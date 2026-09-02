import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../presentation/providers/repository_providers.dart';
import '../../../presentation/providers/session_provider.dart';

const int _longueurPin = 6;

/// Verrouillage de l'application : la session (jeton Sanctum) reste valide,
/// seul le code PIN est demandé pour reprendre la main — jamais d'OTP.
///
/// Affiché en superposition par [EbebApp] tant que
/// `session.estAuthentifie && session.verrouille` : voir main.dart.
///
/// Saisie via un clavier numérique dédié plutôt qu'un `TextField` : le code
/// PIN est un simple [String] accumulé chiffre par chiffre dans l'état local,
/// chaque case affichée (les points en haut) ne fait que refléter sa
/// longueur — aucun contrôleur partagé ne peut donc « recopier » un chiffre
/// dans toutes les cases.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _pin = '';
  String? _erreur;
  bool _enCours = false;

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

  Future<void> _codeOublie() async {
    if (_enCours) return;
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Code PIN oublié ?'),
        content: const Text(
          'Vous allez être déconnecté et devrez vous authentifier à nouveau '
          '(code de vérification par SMS) pour définir un nouveau code PIN.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
    if (confirme == true) {
      ref.read(sessionProvider.notifier).deconnecter();
    }
  }

  @override
  Widget build(BuildContext context) {
    final utilisateur = ref.watch(utilisateurCourantProvider);

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
                        _ToucheIcone(
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

/// Touche icône (effacer) — pas de biométrie disponible dans l'application :
/// ce dernier emplacement sert à corriger une saisie plutôt qu'à imiter une
/// empreinte digitale inexistante.
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
