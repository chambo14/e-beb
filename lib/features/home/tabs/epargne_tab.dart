import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/user_model.dart';

class _EpargneGoal {
  final String emoji;
  final String label;
  final double objectif;
  final double solde;
  final Color color;

  const _EpargneGoal({
    required this.emoji,
    required this.label,
    required this.objectif,
    required this.solde,
    required this.color,
  });

  double get progress => (solde / objectif).clamp(0, 1);
}

class EpargneTab extends StatefulWidget {
  final UserModel user;

  const EpargneTab({super.key, required this.user});

  @override
  State<EpargneTab> createState() => _EpargneTabState();
}

class _EpargneTabState extends State<EpargneTab> {
  final _goals = [
    const _EpargneGoal(
      emoji: '🏠',
      label: 'Épargne Logement',
      objectif: 2000000,
      solde: 450000,
      color: AppColors.primaryBlue,
    ),
    const _EpargneGoal(
      emoji: '🎓',
      label: 'Épargne Scolarité',
      objectif: 500000,
      solde: 320000,
      color: Color(0xFF2E9E5B),
    ),
    const _EpargneGoal(
      emoji: '💼',
      label: 'Épargne Projet',
      objectif: 1000000,
      solde: 180000,
      color: AppColors.orange,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'fr_FR');
    final totalEpargne = _goals.fold(0.0, (sum, g) => sum + g.solde);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Mon épargne',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded,
                color: AppColors.primaryBlue, size: 26),
            onPressed: () => _showAddGoalSheet(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carte total épargne
            _buildTotalCard(fmt, totalEpargne),
            const SizedBox(height: 24),
            // Titre
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mes objectifs',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${_goals.length} objectifs',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Liste objectifs
            ..._goals.map((g) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _GoalCard(goal: g, fmt: fmt),
                )),
            const SizedBox(height: 12),
            // Bouton ajouter
            OutlinedButton.icon(
              onPressed: () => _showAddGoalSheet(context),
              icon: const Icon(Icons.add_rounded,
                  color: AppColors.primaryBlue, size: 18),
              label: const Text(
                'Ajouter un objectif',
                style: TextStyle(
                    color: AppColors.primaryBlue, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: const BorderSide(
                    color: AppColors.primaryBlue, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard(NumberFormat fmt, double total) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E9E5B), Color(0xFF1A7540)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E9E5B).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total épargné',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  fmt.format(total),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text(
                  'FCFA',
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.15),
            ),
            child: const Icon(Icons.savings_rounded,
                color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }

  void _showAddGoalSheet(BuildContext context) {
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
              'Nouvel objectif d\'épargne',
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
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final _EpargneGoal goal;
  final NumberFormat fmt;

  const _GoalCard({required this.goal, required this.fmt});

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
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: goal.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                    child: Text(goal.emoji,
                        style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Objectif : ${fmt.format(goal.objectif)} FCFA',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fmt.format(goal.solde),
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: goal.color),
                  ),
                  Text(
                    '${(goal.progress * 100).round()}%',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(goal.color),
            ),
          ),
          if (goal.progress < 1) ...[
            const SizedBox(height: 8),
            Text(
              'Reste ${fmt.format(goal.objectif - goal.solde)} FCFA',
              style: const TextStyle(
                  color: AppColors.textHint, fontSize: 11),
              textAlign: TextAlign.right,
            ),
          ] else ...[
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 14),
                SizedBox(width: 4),
                Text(
                  'Objectif atteint !',
                  style: TextStyle(
                      color: AppColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
