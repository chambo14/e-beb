import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../presentation/providers/repository_providers.dart';
import '../../../presentation/providers/session_provider.dart';
import 'reinitialiser_pin_screen.dart';

const int _longueurPin = 6;

/// Codes d'erreur `local_auth` signifiant qu'aucune empreinte ne sera jamais
/// disponible sur cet appareil/cette session (matériel absent, aucune
/// empreinte enrôlée, ou aucun verrouillage d'appareil configuré) — dans ces
/// cas, inutile de proposer l'icône ou de retenter automatiquement. Les
/// autres codes (verrou temporaire, annulation, timeout…) sont transitoires :
/// l'icône reste affichée pour permettre une nouvelle tentative.
const _codesBiometrieIndisponible = {
  LocalAuthExceptionCode.noCredentialsSet,
  LocalAuthExceptionCode.noBiometricsEnrolled,
  LocalAuthExceptionCode.noBiometricHardware,
};

/// Verrouillage de l'application : la session (jeton Sanctum) reste valide,
/// seul le code PIN (ou l'empreinte digitale, en complément) est demandé
/// pour reprendre la main — jamais d'OTP.
///
/// Affiché en superposition par [EbebApp] tant que
/// `session.estAuthentifie && session.verrouille` : voir main.dart.
///
/// Saisie du PIN via un clavier numérique dédié plutôt qu'un `TextField` : le
/// code est un simple [String] accumulé chiffre par chiffre dans l'état
/// local, chaque case affichée (les points en haut) ne fait que refléter sa
/// longueur — aucun contrôleur partagé ne peut donc « recopier » un chiffre
/// dans toutes les cases.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _localAuth = LocalAuthentication();

  String _pin = '';
  String? _erreur;
  bool _enCours = false;

  /// `true` dès qu'un capteur biométrique enrôlé est détecté sur l'appareil.
  /// Tant que c'est indéterminé (vérification en cours), l'icône reste
  /// masquée plutôt que de clignoter.
  bool _biometrieDisponible = false;

  @override
  void initState() {
    super.initState();
    // Ce widget n'est plus recréé à chaque verrouillage (voir main.dart : le
    // Navigator qui l'héberge reste monté en permanence, seule sa visibilité
    // change) — `initState` ne couvre donc que le cas où l'application est
    // déjà verrouillée au moment où cet écran est construit pour la toute
    // première fois (ex. démarrage à froid avec un jeton encore valide). Les
    // verrouillages suivants sont détectés dans `build` via `ref.listen`.
    if (ref.read(sessionProvider).verrouille) {
      _initBiometrie();
    }
  }

  /// Réinitialise l'écran à chaque nouveau verrouillage (code PIN et erreur
  /// effacés, disponibilité biométrique re-vérifiée) — sans cela, le widget
  /// persistant réafficherait l'état laissé par le cycle précédent.
  void _surNouveauVerrouillage() {
    setState(() {
      _pin = '';
      _erreur = null;
      _enCours = false;
    });
    _initBiometrie();
  }

  /// Détecte la disponibilité du capteur puis, si présent, déclenche
  /// automatiquement la demande d'authentification — comme sur les
  /// applications bancaires, à l'ouverture de l'écran de verrouillage.
  ///
  /// Ce verrou apparaît précisément quand l'application passe en arrière-plan
  /// (voir `EbebApp.didChangeAppLifecycleState`) : cet appel peut donc
  /// démarrer alors que l'application n'est pas encore réellement au premier
  /// plan. On ne déclenche l'authentification auto que si `resumed` est déjà
  /// atteint au moment où ces vérifications asynchrones se terminent — sinon
  /// l'icône d'empreinte reste disponible pour une relance manuelle une fois
  /// l'utilisateur effectivement revenu sur l'écran (voir `_authentifierParBiometrie`).
  Future<void> _initBiometrie() async {
    bool disponible;
    try {
      disponible = await _localAuth.isDeviceSupported() &&
          await _localAuth.canCheckBiometrics &&
          (await _localAuth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      disponible = false;
    }

    if (!mounted) return;
    setState(() => _biometrieDisponible = disponible);

    if (disponible) _authentifierParBiometrie(auto: true);
  }

  Future<void> _authentifierParBiometrie({bool auto = false}) async {
    if (_enCours || !_biometrieDisponible) return;

    // Ne jamais déclencher automatiquement l'invite biométrique tant que
    // l'application n'est pas réellement au premier plan : sinon le système
    // peut la conserver « en attente » et l'afficher plus tard, à un moment
    // où l'utilisateur ne l'attend plus — l'invite native reste alors
    // affichée par-dessus l'application sans qu'aucune interaction Flutter
    // ne l'indique, ce qui donne l'impression d'une interface figée. Une
    // relance manuelle (tap sur l'icône) reste toujours autorisée : à ce
    // moment l'utilisateur est nécessairement déjà au premier plan.
    if (auto &&
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return;
    }

    try {
      final reussie = await _localAuth.authenticate(
        localizedReason:
            'Authentifiez-vous pour accéder à votre espace Ebeb Finance',
        biometricOnly: true,
      );

      if (!mounted || !reussie) return;
      ref.read(sessionProvider.notifier).deverrouiller();
    } on LocalAuthException catch (e) {
      if (!mounted) return;
      // Empreinte retirée/désactivée entre-temps : on masque l'icône plutôt
      // que de continuer à proposer une biométrie qui ne fonctionnera plus.
      if (_codesBiometrieIndisponible.contains(e.code)) {
        setState(() => _biometrieDisponible = false);
      }
      // Annulation par l'utilisateur ou échec de lecture : aucun message
      // alarmant, il lui reste la saisie du code PIN.
    }
  }

  void _saisirChiffre(String chiffre) {
    if (_enCours || _pin.length >= _longueurPin) return;
    setState(() {
      _erreur = null;
      _pin += chiffre;
    });
    if (_pin.length == _longueurPin) _valider();
  }

  void _effacer() {
    if (_enCours || _pin.isEmpty) return;
    setState(() {
      _erreur = null;
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  Future<void> _valider() async {
    setState(() => _enCours = true);

    try {
      final valide = await ref
          .read(utilisateurRepositoryProvider)
          .verifierCodePin(_pin);

      if (!mounted) return;

      if (!valide) {
        setState(() {
          _enCours = false;
          _erreur = 'Code PIN incorrect.';
          _pin = '';
        });
        return;
      }

      ref.read(sessionProvider.notifier).deverrouiller();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _enCours = false;
        _erreur = e.message;
        _pin = '';
      });
    }
  }

  /// Lance le parcours « code PIN oublié » : un OTP envoyé par email prouve
  /// l'identité (la session/le jeton reste valide tout du long, inutile de
  /// se déconnecter) avant de définir un nouveau code PIN. La déconnexion
  /// complète reste disponible séparément via le lien en bas de l'écran,
  /// pour l'utilisateur qui n'a pas non plus accès à cette adresse email.
  Future<void> _codeOublie() async {
    if (_enCours) return;
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Code PIN oublié ?'),
        content: const Text(
          'Nous allons vous envoyer un code de vérification par email pour '
          'confirmer votre identité, puis vous pourrez définir un nouveau '
          'code PIN.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
    if (confirme != true || !mounted) return;

    setState(() => _enCours = true);
    try {
      await ref
          .read(utilisateurRepositoryProvider)
          .demanderReinitialisationPin();

      if (!mounted) return;
      setState(() => _enCours = false);
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ReinitialiserPinScreen()),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _enCours = false;
        _erreur = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final utilisateur = ref.watch(utilisateurCourantProvider);

    ref.listen(sessionProvider, (precedent, courant) {
      if (precedent?.verrouille != true && courant.verrouille) {
        _surNouveauVerrouillage();
      }
    });

    return PopScope(
      // On ne quitte jamais l'écran de verrouillage avec le bouton retour :
      // seul un code PIN valide déverrouille l'application.
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 32),
              Image.asset(
                'assets/logo.jpeg',
                width: 96,
                height: 96,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              Text(
                utilisateur != null
                    ? 'Bon retour, ${utilisateur.prenom} !'
                    : 'Application verrouillée',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Saisissez votre code PIN pour accéder à votre espace.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const Spacer(),
              // ─── Indicateur de saisie (points) ─────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _longueurPin; i++) ...[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < _pin.length
                            ? AppColors.primaryBlue
                            : Colors.transparent,
                        border: Border.all(
                          color: i < _pin.length
                              ? AppColors.primaryBlue
                              : AppColors.border,
                          width: 1.5,
                        ),
                      ),
                    ),
                    if (i != _longueurPin - 1) const SizedBox(width: 14),
                  ],
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 20,
                child: _erreur == null
                    ? null
                    : Text(
                        _erreur!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              const Spacer(),
              // ─── Clavier numérique ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    for (final ligne in const [
                      ['1', '2', '3'],
                      ['4', '5', '6'],
                      ['7', '8', '9'],
                    ])
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (final chiffre in ligne)
                            _ToucheChiffre(
                              chiffre: chiffre,
                              onTap: () => _saisirChiffre(chiffre),
                            ),
                        ],
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _ToucheTexte(texte: 'OUBLIÉ ?', onTap: _codeOublie),
                        _ToucheChiffre(
                          chiffre: '0',
                          onTap: () => _saisirChiffre('0'),
                        ),
                        // Empreinte tant que rien n'est saisi (relance
                        // manuelle possible) ; dès la première touche, cette
                        // place sert à corriger la saisie du PIN.
                        _pin.isEmpty && _biometrieDisponible
                            ? _ToucheIcone(
                                icone: Icons.fingerprint_rounded,
                                onTap: _authentifierParBiometrie,
                              )
                            : _ToucheIcone(
                                icone: Icons.backspace_outlined,
                                onTap: _effacer,
                              ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_enCours) ...[
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: AppColors.primaryBlue,
                    strokeWidth: 2.5,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextButton(
                onPressed: _enCours
                    ? null
                    : () => ref.read(sessionProvider.notifier).deconnecter(),
                child: const Text(
                  'Ce n\'est pas moi, se déconnecter',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// Touche du clavier : un simple chiffre, grand et sans contour — reprend le
/// style épuré de la maquette (pas de cercle ni de fond sur les touches).
class _ToucheChiffre extends StatelessWidget {
  final String chiffre;
  final VoidCallback onTap;

  const _ToucheChiffre({required this.chiffre, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 36,
      child: SizedBox(
        width: 64,
        height: 64,
        child: Center(
          child: Text(
            chiffre,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Touche texte (« OUBLIÉ ? ») — même emprise qu'une touche chiffre pour
/// garder la grille alignée.
class _ToucheTexte extends StatelessWidget {
  final String texte;
  final VoidCallback onTap;

  const _ToucheTexte({required this.texte, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 36,
      child: SizedBox(
        width: 64,
        height: 64,
        child: Center(
          child: Text(
            texte,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Touche icône du dernier emplacement du clavier : empreinte digitale
/// (relance la biométrie) tant que le PIN est vide, ou effacer dès qu'une
/// saisie est en cours (voir le `build` de [_LockScreenState]).
class _ToucheIcone extends StatelessWidget {
  final IconData icone;
  final VoidCallback onTap;

  const _ToucheIcone({required this.icone, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 36,
      child: SizedBox(
        width: 64,
        height: 64,
        child: Center(
          child: Icon(icone, size: 24, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
