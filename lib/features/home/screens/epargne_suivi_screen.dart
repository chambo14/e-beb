import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../domain/entities/operation.dart';
import '../../../presentation/providers/repository_providers.dart';
import '../../../presentation/providers/utilisateur_providers.dart';

/// Suivi de l'épargne, filtrable par période (semaine / mois / année) : total
/// épargné sur la période (via le récapitulatif existant) et détail des
/// opérations d'épargne (montants + dates) sur cette même période.
class EpargneSuiviScreen extends ConsumerStatefulWidget {
  const EpargneSuiviScreen({super.key});

  @override
  ConsumerState<EpargneSuiviScreen> createState() =>
      _EpargneSuiviScreenState();
}

class _EpargneSuiviScreenState extends ConsumerState<EpargneSuiviScreen> {
  PeriodeRecap _periode = PeriodeRecap.mois;
  Future<List<Operation>>? _futureOperations;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  void _charger() {
    final (debut, fin) = _periode.bornes(DateTime.now());
    setState(() {
      _futureOperations = ref.read(transactionRepositoryProvider).operations(
            FiltreOperations(
              types: const ['EPARGNE'],
              dateDebut: debut,
              dateFin: fin,
            ),
          );
    });
  }

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
          'Suivi de l\'épargne',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 17,
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
                onChanged: (p) {
                  setState(() => _periode = p);
                  _charger();
                },
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E9E5B), Color(0xFF1A7540)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: recap.when(
                  loading: () => const SizedBox(
                    height: 46,
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                  error: (erreur, _) => Text(
                    erreur is ApiException
                        ? erreur.message
                        : 'Impossible de charger le récapitulatif.',
                    style: const TextStyle(color: Colors.white, fontSize: 12.5),
                  ),
                  data: (r) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.periodeLibelle ?? _periode.libelle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Épargné sur la période',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        '${fmt.format(r.totalEpargnePeriode)} FCFA',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Opérations d\'épargne',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<Operation>>(
                  future: _futureOperations,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      final erreur = snapshot.error;
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.cloud_off_rounded,
                                  color: AppColors.error, size: 30),
                              const SizedBox(height: 10),
                              Text(
                                erreur is ApiException
                                    ? erreur.message
                                    : 'Impossible de charger les opérations.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12.5),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: _charger,
                                style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(140, 40)),
                                child: const Text('Réessayer'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final operations = snapshot.data ?? const [];
                    if (operations.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Aucune opération d\'épargne sur cette période.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async => _charger(),
                      child: ListView.separated(
                        itemCount: operations.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) =>
                            _OperationEpargneTile(operation: operations[i]),
                      ),
                    );
                  },
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
                          ? const Color(0xFF2E9E5B)
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

class _OperationEpargneTile extends StatelessWidget {
  final Operation operation;
  const _OperationEpargneTile({required this.operation});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'fr_FR');
    final dateFmt = DateFormat('dd MMM yyyy · HH:mm', 'fr_FR');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.savings_rounded,
                  color: Color(0xFF2E9E5B), size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  operation.libelle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (operation.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    operation.description!,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 3),
                Text(
                  dateFmt.format(operation.date),
                  style: const TextStyle(fontSize: 10, color: AppColors.textHint),
                ),
              ],
            ),
          ),
          Text(
            '+${fmt.format(operation.montant)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }
}
