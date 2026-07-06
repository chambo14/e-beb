import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/user_model.dart';

class CotisationsTab extends StatelessWidget {
  final UserModel user;

  const CotisationsTab({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'fr_FR');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Mes cotisations',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _StatusPill(aJour: user.cnpsAJour),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner statut
            _buildStatusBanner(context),
            const SizedBox(height: 24),
            // Titre section
            const _SectionTitle('Cotisations sociales obligatoires'),
            const SizedBox(height: 12),
            // CNPS
            _CnpsCard(user: user, fmt: fmt),
            const SizedBox(height: 16),
            // AMU
            _AmuCard(fmt: fmt),
            const SizedBox(height: 24),
            // Titre section
            const _SectionTitle('Autres déductions'),
            const SizedBox(height: 12),
            // Commission E-BEB
            _DeductionCard(
              emoji: '⚙️',
              label: 'Commission E-BEB SALARY',
              description: 'Frais de service plateforme',
              taux: 0.5,
              montant: (user.totalRecuMois * 0.005),
              color: AppColors.orange,
              fmt: fmt,
            ),
            const SizedBox(height: 8),
            // Service VIP (si activé)
            _DeductionCard(
              emoji: '⭐',
              label: 'Service VIP E-BEB',
              description: 'Services premium (non activé)',
              taux: 3.0,
              montant: 0,
              color: AppColors.purple,
              isActive: false,
              fmt: fmt,
            ),
            const SizedBox(height: 24),
            // Récapitulatif mensuel
            _buildRecapMensuel(fmt),
            const SizedBox(height: 24),
            // Bouton modifier les taux
            ElevatedButton.icon(
              onPressed: () => _showModifierTauxDialog(context, fmt),
              icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
              label: const Text(
                'Modifier mes taux de déduction',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_rounded,
                  color: AppColors.primaryBlue, size: 18),
              label: const Text(
                'Ajouter une assurance',
                style: TextStyle(
                    color: AppColors.primaryBlue, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: user.cnpsAJour
              ? [
                  AppColors.success.withValues(alpha: 0.15),
                  AppColors.success.withValues(alpha: 0.05),
                ]
              : [
                  AppColors.red.withValues(alpha: 0.15),
                  AppColors.red.withValues(alpha: 0.05),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: user.cnpsAJour
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.red.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: user.cnpsAJour
                  ? AppColors.success.withValues(alpha: 0.2)
                  : AppColors.red.withValues(alpha: 0.2),
            ),
            child: Icon(
              user.cnpsAJour
                  ? Icons.verified_rounded
                  : Icons.warning_amber_rounded,
              color: user.cnpsAJour ? AppColors.success : AppColors.red,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.cnpsAJour
                      ? 'Vous êtes à jour de vos cotisations'
                      : 'Cotisations en retard !',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: user.cnpsAJour ? AppColors.success : AppColors.red,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.cnpsAJour
                      ? 'Toutes vos prestations sociales sont actives'
                      : 'Vos prestations peuvent être suspendues',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecapMensuel(NumberFormat fmt) {
    const cnpsVerse = 18000.0;
    const amuVerse = 12000.0;
    final commission = user.totalRecuMois * 0.005;
    final total = cnpsVerse + amuVerse + commission;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryBlue, Color(0xFF3D2C9E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Récapitulatif — Avril 2026',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          _RecapRow(label: 'Total reçu', value: '${fmt.format(user.totalRecuMois)} FCFA', isHighlight: false),
          _RecapRow(label: 'CNPS versé', value: '${fmt.format(cnpsVerse)} FCFA', isHighlight: false),
          _RecapRow(label: 'AMU versé', value: '${fmt.format(amuVerse)} FCFA', isHighlight: false),
          _RecapRow(label: 'Commission E-BEB', value: '${fmt.format(commission)} FCFA', isHighlight: false),
          Divider(color: Colors.white.withValues(alpha: 0.2), height: 20),
          _RecapRow(
            label: 'Solde disponible',
            value: '${fmt.format(user.totalRecuMois - total)} FCFA',
            isHighlight: true,
          ),
        ],
      ),
    );
  }

  void _showModifierTauxDialog(BuildContext context, NumberFormat fmt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Modifier mes taux',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Fonctionnalité disponible dans la prochaine version',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets ─────────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final bool aJour;

  const _StatusPill({required this.aJour});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: aJour
            ? AppColors.success.withValues(alpha: 0.12)
            : AppColors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: aJour ? AppColors.success : AppColors.red,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            aJour ? 'À JOUR' : 'EN RETARD',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: aJour ? AppColors.success : AppColors.red,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _CnpsCard extends StatelessWidget {
  final UserModel user;
  final NumberFormat fmt;

  const _CnpsCard({required this.user, required this.fmt});

  @override
  Widget build(BuildContext context) {
    const verse = 18000.0;
    const total = 21600.0;
    const progress = verse / total;

    return _BaseCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                    child: Text('🏛️', style: TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CNPS',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.textPrimary),
                    ),
                    const Text(
                      'Caisse Nationale de Prévoyance Sociale',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 16),
          // Taux et montant
          Row(
            children: [
              Expanded(
                child: _InfoChip(
                    label: 'Taux', value: '12%', color: AppColors.primaryBlue),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoChip(
                  label: 'Versé ce mois',
                  value: '${fmt.format(verse)} FCFA',
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoChip(
                  label: 'Objectif',
                  value: '${fmt.format(total)} FCFA',
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Barre de progression
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primaryBlue),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryBlue,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Numéro CNPS
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.badge_outlined,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  'N° ${user.cnpsNumero}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AmuCard extends StatelessWidget {
  final NumberFormat fmt;

  const _AmuCard({required this.fmt});

  @override
  Widget build(BuildContext context) {
    return _BaseCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
                child: Text('🏥', style: TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AMU',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.textPrimary),
                ),
                const Text(
                  'Assurance Maladie Universelle',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Text(
                      '12 000 FCFA / mois',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                          fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Payé',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 24),
        ],
      ),
    );
  }
}

class _DeductionCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String description;
  final double taux;
  final double montant;
  final Color color;
  final bool isActive;
  final NumberFormat fmt;

  const _DeductionCard({
    required this.emoji,
    required this.label,
    required this.description,
    required this.taux,
    required this.montant,
    required this.color,
    required this.fmt,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.textPrimary),
                ),
                Text(
                  description,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$taux%',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: isActive ? color : AppColors.textHint),
              ),
              if (isActive && montant > 0)
                Text(
                  fmt.format(montant),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11),
                ),
              if (!isActive)
                const Text(
                  'Inactif',
                  style: TextStyle(color: AppColors.textHint, fontSize: 10),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BaseCard extends StatelessWidget {
  final Widget child;

  const _BaseCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 9,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _RecapRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;

  const _RecapRow(
      {required this.label, required this.value, required this.isHighlight});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isHighlight ? Colors.white : Colors.white60,
              fontSize: isHighlight ? 14 : 13,
              fontWeight:
                  isHighlight ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: isHighlight ? 16 : 13,
              fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
