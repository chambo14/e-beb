import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/moyens_paiement.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/type_cotisation.dart';
import '../../presentation/providers/cotisation_providers.dart';
import '../../presentation/providers/mobile_money_providers.dart';
import '../../presentation/providers/session_provider.dart';
import '../home/screens/home_screen.dart';

/// Parcours guidé affiché juste après l'inscription : configuration du
/// compte principal (nécessaire pour les QR codes) puis des règles de
/// prélèvement, avant l'entrée dans l'application.
class AccountSetupFlow extends ConsumerStatefulWidget {
  final String prenom;
  final String telephone;

  const AccountSetupFlow({
    super.key,
    required this.prenom,
    required this.telephone,
  });

  @override
  ConsumerState<AccountSetupFlow> createState() => _AccountSetupFlowState();
}

class _AccountSetupFlowState extends ConsumerState<AccountSetupFlow> {
  final _pageController = PageController();
  int _step = 0;

  String _selectedNetwork = 'Wave';
  bool _assuranceActive = false;
  bool _epargneActive = true;
  double _epargneTaux = 10;
  bool _enregistrement = false;

  static const _stepTitles = ['Compte principal', 'Règles de prélèvement'];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  /// Enregistre le compte mobile money principal puis passe à l'étape 2.
  ///
  /// Si aucun `moyen_paiement_id` n'est encore connu (cf. [MoyensPaiement]),
  /// l'étape est simplement passée : le compte pourra être ajouté plus tard.
  Future<void> _enregistrerCompte() async {
    final moyenId = MoyensPaiement.idPour(_selectedNetwork);
    if (moyenId == null) {
      _goToStep(1);
      return;
    }

    setState(() => _enregistrement = true);
    final succes = await ref
        .read(comptesMobileMoneyProvider.notifier)
        .ajouter(
          moyenPaiementId: moyenId,
          numeroCompte: Formatters.telephoneApi(widget.telephone),
          estPrincipal: true,
        );
    if (!mounted) return;
    setState(() => _enregistrement = false);

    if (!succes) {
      final erreur = ref.read(comptesMobileMoneyProvider).error;
      _snack(
        erreur is ApiException
            ? erreur.message
            : 'Impossible d\'enregistrer ce compte.',
        succes: false,
      );
      return;
    }

    _goToStep(1);
  }

  /// Applique les taux choisis aux types de cotisation correspondants, puis
  /// entre dans l'application.
  Future<void> _terminer() async {
    setState(() => _enregistrement = true);

    final types = ref.read(cotisationsControllerProvider).valueOrNull ?? const [];
    final controller = ref.read(cotisationsControllerProvider.notifier);

    // On ne configure que les types réellement exposés par l'API.
    final aConfigurer = <(TypeCotisation, double, bool)>[
      for (final type in types)
        if (_correspond(type, ['EPARGNE', 'ÉPARGNE']))
          (type, _epargneTaux, _epargneActive)
        else if (_correspond(type, ['ASSUR']))
          (type, 5, _assuranceActive),
    ];

    for (final (type, valeur, actif) in aConfigurer) {
      final succes = await controller.configurerRegle(
        typeCotisationId: type.id,
        typeCalcul: TypeCalcul.pourcentage,
        valeur: valeur,
        estActif: actif,
      );
      if (!mounted) return;
      if (!succes) {
        setState(() => _enregistrement = false);
        final erreur = ref.read(cotisationsControllerProvider).error;
        _snack(
          erreur is ApiException
              ? '${type.libelle} : ${erreur.message}'
              : 'Échec de la configuration de ${type.libelle}.',
          succes: false,
        );
        return;
      }
    }

    if (!mounted) return;
    setState(() => _enregistrement = false);
    _finish();
  }

  bool _correspond(TypeCotisation type, List<String> motsCles) {
    final cle = '${type.code ?? ''} ${type.libelle}'.toUpperCase();
    return motsCles.any(cle.contains);
  }

  void _snack(String message, {required bool succes}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: succes ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _finish() {
    // Le profil et les données de l'accueil sont rechargés à l'entrée.
    ref.read(sessionProvider.notifier).rafraichirUtilisateur();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step > 0) _goToStep(_step - 1);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              _buildProgress(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _MainAccountStep(
                      telephone: widget.telephone,
                      selectedNetwork: _selectedNetwork,
                      enCours: _enregistrement,
                      onSelectNetwork: (n) =>
                          setState(() => _selectedNetwork = n),
                      onNext: _enregistrement ? null : _enregistrerCompte,
                    ),
                    _PrelevementStep(
                      assuranceActive: _assuranceActive,
                      epargneActive: _epargneActive,
                      epargneTaux: _epargneTaux,
                      enCours: _enregistrement,
                      onAssuranceChanged: (v) =>
                          setState(() => _assuranceActive = v),
                      onEpargneChanged: (v) =>
                          setState(() => _epargneActive = v),
                      onEpargneTauxChanged: (v) =>
                          setState(() => _epargneTaux = v),
                      onFinish: _enregistrement ? null : _terminer,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          if (_step > 0)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary, size: 20),
              onPressed: () => _goToStep(_step - 1),
            )
          else
            const SizedBox(width: 48),
          Expanded(
            child: Text(
              _stepTitles[_step],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          TextButton(
            onPressed: _finish,
            child: const Text(
              'Passer',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
      child: Column(
        children: [
          Row(
            children: List.generate(_stepTitles.length, (i) {
              final done = i <= _step;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                      right: i == _stepTitles.length - 1 ? 0 : 6),
                  height: 5,
                  decoration: BoxDecoration(
                    color: done
                        ? const Color(0xFF5B21B6)
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Étape ${_step + 1} sur ${_stepTitles.length}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Étape 1 : Compte principal ───────────────────────────────────────────────

class _NetworkChoice {
  final String name;
  final List<Color> gradient;
  final bool available;

  const _NetworkChoice({
    required this.name,
    required this.gradient,
    this.available = true,
  });
}

const _networkChoices = [
  _NetworkChoice(
    name: 'Wave',
    gradient: [Color(0xFF1ECFEE), Color(0xFF03A9C7)],
  ),
  _NetworkChoice(
    name: 'Orange Money',
    gradient: [Color(0xFF000000), Color(0xFF434343)],
    available: false,
  ),
  _NetworkChoice(
    name: 'MTN MoMo',
    gradient: [Color(0xFFFFCC00), Color(0xFFE6A800)],
    available: false,
  ),
  _NetworkChoice(
    name: 'Moov Money',
    gradient: [Color(0xFF1565C0), Color(0xFF003580)],
    available: false,
  ),
];

class _MainAccountStep extends StatelessWidget {
  final String telephone;
  final String selectedNetwork;
  final bool enCours;
  final ValueChanged<String> onSelectNetwork;
  final VoidCallback? onNext;

  const _MainAccountStep({
    required this.telephone,
    required this.selectedNetwork,
    required this.enCours,
    required this.onSelectNetwork,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF5B21B6).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.account_balance_wallet_rounded,
                color: Color(0xFF5B21B6), size: 28),
          ),
          const SizedBox(height: 20),
          const Text(
            'Configurez votre compte principal',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Choisissez le portefeuille mobile money qui recevra vos paiements. '
            'Il est nécessaire pour générer vos QR codes de paiement et de retrait.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          ..._networkChoices.map((n) {
            final isSelected = n.name == selectedNetwork;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: n.available ? () => onSelectNetwork(n.name) : null,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF5B21B6)
                          : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: n.gradient),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.phone_android_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (!n.available)
                              const Text(
                                'Bientôt disponible',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textHint,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded,
                            color: Color(0xFF5B21B6), size: 22)
                      else if (!n.available)
                        const Icon(Icons.lock_outline_rounded,
                            color: AppColors.textHint, size: 20),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.smartphone_rounded,
                    color: AppColors.textSecondary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Numéro associé',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        Formatters.telephoneApi(telephone),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (MoyensPaiement.aucunConfigure) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.orange.withValues(alpha: 0.3)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: AppColors.orange, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Le rattachement automatique du compte mobile money sera '
                      'activé prochainement. Vous pourrez l\'ajouter depuis '
                      'votre profil.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B21B6),
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: enCours
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text(
                      'Continuer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Étape 2 : Règles de prélèvement ──────────────────────────────────────────

class _PrelevementStep extends StatelessWidget {
  final bool assuranceActive;
  final bool epargneActive;
  final double epargneTaux;
  final ValueChanged<bool> onAssuranceChanged;
  final ValueChanged<bool> onEpargneChanged;
  final ValueChanged<double> onEpargneTauxChanged;
  final bool enCours;
  final VoidCallback? onFinish;

  const _PrelevementStep({
    required this.assuranceActive,
    required this.epargneActive,
    required this.epargneTaux,
    required this.enCours,
    required this.onAssuranceChanged,
    required this.onEpargneChanged,
    required this.onEpargneTauxChanged,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.tune_rounded,
                color: AppColors.orange, size: 28),
          ),
          const SizedBox(height: 20),
          const Text(
            'Configurez vos règles de prélèvement',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Définissez la part de vos revenus automatiquement affectée à '
            'chaque poste. Vous pourrez ajuster ces taux à tout moment depuis '
            'l\'onglet "Vos taux".',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          const _ObligatoryRuleRow(
            emoji: '🏛️',
            label: 'CNPS',
            description: 'Cotisation sociale obligatoire',
            taux: '12%',
          ),
          const SizedBox(height: 10),
          const _ObligatoryRuleRow(
            emoji: '🏥',
            label: 'CMU',
            description: 'Assurance maladie universelle',
            taux: '3%',
          ),
          const SizedBox(height: 16),
          const Text(
            'DÉDUCTIONS OPTIONNELLES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 10),
          _ToggleRuleRow(
            emoji: '💰',
            label: 'Épargne automatique',
            description: 'Mise de côté à chaque paiement reçu',
            active: epargneActive,
            taux: epargneTaux,
            onActiveChanged: onEpargneChanged,
            onTauxChanged: onEpargneTauxChanged,
          ),
          const SizedBox(height: 10),
          _ToggleRuleRow(
            emoji: '🛡️',
            label: 'Assurance complémentaire',
            description: 'Couverture santé additionnelle',
            active: assuranceActive,
            taux: 5,
            onActiveChanged: onAssuranceChanged,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onFinish,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: enCours
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text(
                      'Terminer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ObligatoryRuleRow extends StatelessWidget {
  final String emoji;
  final String label;
  final String description;
  final String taux;

  const _ObligatoryRuleRow({
    required this.emoji,
    required this.label,
    required this.description,
    required this.taux,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 17))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                Text(description,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Row(
            children: [
              Text(taux,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              const SizedBox(width: 6),
              const Icon(Icons.lock_outline_rounded,
                  size: 14, color: AppColors.textHint),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToggleRuleRow extends StatelessWidget {
  final String emoji;
  final String label;
  final String description;
  final bool active;
  final double taux;
  final ValueChanged<bool> onActiveChanged;
  final ValueChanged<double>? onTauxChanged;

  const _ToggleRuleRow({
    required this.emoji,
    required this.label,
    required this.description,
    required this.active,
    required this.taux,
    required this.onActiveChanged,
    this.onTauxChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active
              ? const Color(0xFF5B21B6).withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 17))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text(description,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Switch(
                value: active,
                onChanged: onActiveChanged,
                activeThumbColor: const Color(0xFF5B21B6),
              ),
            ],
          ),
          if (active && onTauxChanged != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Text(
                  'Taux appliqué',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.remove_circle_outline_rounded,
                      size: 20, color: Color(0xFF5B21B6)),
                  onPressed: taux > 1
                      ? () => onTauxChanged!(taux - 1)
                      : null,
                ),
                Text(
                  '${taux.round()}%',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.add_circle_outline_rounded,
                      size: 20, color: Color(0xFF5B21B6)),
                  onPressed: taux < 30
                      ? () => onTauxChanged!(taux + 1)
                      : null,
                ),
              ],
            ),
          ] else if (active) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Taux appliqué',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                const Spacer(),
                Text(
                  '${taux.round()}%',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
