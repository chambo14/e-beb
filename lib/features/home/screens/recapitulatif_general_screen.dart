import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../domain/entities/recapitulatif.dart';
import '../../../presentation/providers/utilisateur_providers.dart';

/// Récapitulatif général des prélèvements, filtrable par période
/// (semaine / mois / année) — ouvert depuis la carte de solde de l'accueil.
class RecapitulatifGeneralScreen extends ConsumerStatefulWidget {
  const RecapitulatifGeneralScreen({super.key});

  @override
  ConsumerState<RecapitulatifGeneralScreen> createState() =>
      _RecapitulatifGeneralScreenState();
}

class _RecapitulatifGeneralScreenState
    extends ConsumerState<RecapitulatifGeneralScreen> {
  PeriodeRecap _periode = PeriodeRecap.mois;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'fr_FR');
    final recap = ref.watch(recapitulatifPeriodeProvider(_periode));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Récapitulatif',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SelecteurPeriode(
                selection: _periode,
                onChanged: (p) => setState(() => _periode = p),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: recap.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (erreur, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_off_rounded,
                              color: AppColors.error, size: 34),
                          const SizedBox(height: 12),
                          Text(
                            erreur is ApiException
                                ? erreur.message
                                : 'Impossible de charger le récapitulatif.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => ref.invalidate(
                              recapitulatifPeriodeProvider(_periode),
                            ),
                            style: ElevatedButton.styleFrom(
                                minimumSize: const Size(160, 44)),
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (r) => _DetailPeriode(
                    periode: _periode,
                    recap: r,
                    fmt: fmt,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelecteurPeriode extends StatelessWidget {
  final PeriodeRecap selection;
  final ValueChanged<PeriodeRecap> onChanged;

  const _SelecteurPeriode({required this.selection, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.border.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final periode in PeriodeRecap.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(periode),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: periode == selection ? Colors.white : null,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: periode == selection
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    periode.libelle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: periode == selection
                          ? AppColors.primaryBlue
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailPeriode extends StatelessWidget {
  final PeriodeRecap periode;
  final Recapitulatif recap;
  final NumberFormat fmt;

  const _DetailPeriode({
    required this.periode,
    required this.recap,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryBlue, AppColors.purple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recap.periodeLibelle ?? periode.libelle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Solde disponible',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  '${fmt.format(recap.soldeDisponiblePeriode)} FCFA',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Détail des mouvements',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _LigneMontant(
                  icone: Icons.arrow_downward_rounded,
                  couleur: AppColors.success,
                  label: 'Total reçu',
                  valeur: '+${fmt.format(recap.totalRecu)} FCFA',
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _LigneMontant(
                  icone: Icons.savings_rounded,
                  couleur: AppColors.primaryBlue,
                  label: 'Total épargné',
                  valeur: '${fmt.format(recap.totalEpargnePeriode)} FCFA',
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _LigneMontant(
                  icone: Icons.shield_outlined,
                  couleur: AppColors.orange,
                  label: 'Cotisations prélevées',
                  valeur: '-${fmt.format(recap.totalCotisations)} FCFA',
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _LigneMontant(
                  icone: Icons.percent_rounded,
                  couleur: AppColors.textSecondary,
                  label: 'Commissions',
                  valeur: '-${fmt.format(recap.totalCommissions)} FCFA',
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _LigneMontant(
                  icone: Icons.arrow_upward_rounded,
                  couleur: AppColors.error,
                  label: 'Total prélevé (hors épargne)',
                  valeur:
                      '-${fmt.format(recap.totalPrelevementsHorsEpargne)} FCFA',
                  accentue: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _LigneMontant extends StatelessWidget {
  final IconData icone;
  final Color couleur;
  final String label;
  final String valeur;
  final bool accentue;

  const _LigneMontant({
    required this.icone,
    required this.couleur,
    required this.label,
    required this.valeur,
    this.accentue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: couleur.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icone, color: couleur, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: accentue ? FontWeight.w800 : FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            valeur,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: accentue ? couleur : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
