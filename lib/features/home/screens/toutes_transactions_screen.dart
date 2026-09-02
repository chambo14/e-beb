import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../domain/entities/operation.dart';
import '../../../presentation/providers/repository_providers.dart';
import '../../../presentation/providers/utilisateur_providers.dart' show PeriodeRecap;

/// Période rapide proposée en haut de l'écran — reprend les trois découpages
/// de `PeriodeRecap` et ajoute « Toutes » (aucun filtre de date) et
/// « Personnalisé » (intervalle libre choisi par l'utilisateur).
enum _PeriodeChoix {
  toutes('Toutes'),
  semaine('Semaine'),
  mois('Mois'),
  annee('Année'),
  personnalise('Personnalisé');

  final String libelle;
  const _PeriodeChoix(this.libelle);
}

/// Types d'opération connus (`Operation::TYPES_CREDIT`/`TYPES_DEBIT` côté
/// back-end), avec un libellé lisible — permet le filtre `types[]`.
const Map<String, String> _typesConnus = {
  'PAIEMENT_CLIENT': 'Paiement reçu',
  'REVERSEMENT': 'Reversement',
  'REVERSEMENT_ESCROW': 'Reversement (escrow)',
  'EPARGNE': 'Épargne',
  'COTISATION_CNPS': 'Cotisation CNPS',
  'COTISATION_AMU': 'Cotisation CMU',
  'COTISATION_PERSONNALISEE': 'Cotisation personnalisée',
  'ASSURANCE_PERSONNALISEE': 'Assurance personnalisée',
  'COMMISSION_PLATEFORME': 'Commission plateforme',
  'COMMISSION': 'Commission',
  'VIREMENT': 'Virement',
  'PRELEVEMENT_COTISATION': 'Prélèvement cotisation',
  'PRELEVEMENT_EPARGNE': 'Prélèvement épargne',
  'RETRAIT_EPARGNE': 'Retrait épargne',
  'RETRAIT_COTISATION': 'Retrait cotisation',
  'AJUSTEMENT': 'Ajustement',
  'REPORT_COTISATION': 'Report cotisation',
  'ESCROW': 'Escrow',
};

/// Historique complet des opérations, avec filtre par période (semaine /
/// mois / année / intervalle libre), par type(s) et par sens (crédit/débit).
///
/// Utilise son propre état de filtre local (et son propre appel réseau via
/// le dépôt directement) plutôt que le `filtreOperationsProvider` partagé —
/// pour ne pas modifier ce qu'affiche « Transactions récentes » sur
/// l'accueil quand l'utilisateur revient en arrière.
class ToutesTransactionsScreen extends ConsumerStatefulWidget {
  const ToutesTransactionsScreen({super.key});

  @override
  ConsumerState<ToutesTransactionsScreen> createState() =>
      _ToutesTransactionsScreenState();
}

class _ToutesTransactionsScreenState
    extends ConsumerState<ToutesTransactionsScreen> {
  _PeriodeChoix _periode = _PeriodeChoix.toutes;
  DateTime? _dateDebutPerso;
  DateTime? _dateFinPerso;
  String? _sens; // null = tout, sinon 'CREDIT' / 'DEBIT'
  final Set<String> _typesSelectionnes = {};

  Future<List<Operation>>? _futureOperations;

  @override
  void initState() {
    super.initState();
    _relancerRecherche();
  }

  FiltreOperations get _filtreActuel {
    DateTime? debut;
    DateTime? fin;
    switch (_periode) {
      case _PeriodeChoix.toutes:
        break;
      case _PeriodeChoix.semaine:
        (debut, fin) = PeriodeRecap.semaine.bornes(DateTime.now());
      case _PeriodeChoix.mois:
        (debut, fin) = PeriodeRecap.mois.bornes(DateTime.now());
      case _PeriodeChoix.annee:
        (debut, fin) = PeriodeRecap.annee.bornes(DateTime.now());
      case _PeriodeChoix.personnalise:
        debut = _dateDebutPerso;
        fin = _dateFinPerso;
    }
    return FiltreOperations(
      types: _typesSelectionnes.toList(),
      sens: _sens,
      dateDebut: debut,
      dateFin: fin,
    );
  }

  bool get _filtresActifs =>
      _periode != _PeriodeChoix.toutes ||
      _sens != null ||
      _typesSelectionnes.isNotEmpty;

  void _relancerRecherche() {
    setState(() {
      _futureOperations = ref
          .read(transactionRepositoryProvider)
          .operations(_filtreActuel);
    });
  }

  void _reinitialiser() {
    setState(() {
      _periode = _PeriodeChoix.toutes;
      _dateDebutPerso = null;
      _dateFinPerso = null;
      _sens = null;
      _typesSelectionnes.clear();
    });
    _relancerRecherche();
  }

  Future<void> _choisirPeriode(_PeriodeChoix choix) async {
    if (choix == _PeriodeChoix.personnalise) {
      final plage = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now().add(const Duration(days: 1)),
        initialDateRange: _dateDebutPerso != null && _dateFinPerso != null
            ? DateTimeRange(start: _dateDebutPerso!, end: _dateFinPerso!)
            : null,
        locale: const Locale('fr', 'FR'),
      );
      if (plage == null) return;
      setState(() {
        _periode = choix;
        _dateDebutPerso = plage.start;
        _dateFinPerso = plage.end;
      });
    } else {
      setState(() => _periode = choix);
    }
    _relancerRecherche();
  }

  Future<void> _ouvrirFiltreTypes() async {
    final resultat = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FiltreTypesSheet(selection: _typesSelectionnes),
    );
    if (resultat == null) return;
    setState(() {
      _typesSelectionnes
        ..clear()
        ..addAll(resultat);
    });
    _relancerRecherche();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Transactions',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _ouvrirFiltreTypes,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.filter_list_rounded,
                    color: AppColors.primaryBlue),
                if (_typesSelectionnes.isNotEmpty)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _PeriodeChoix.values.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final choix = _PeriodeChoix.values[i];
                    final actif = choix == _periode;
                    return ChoiceChip(
                      label: Text(
                        choix == _PeriodeChoix.personnalise &&
                                _dateDebutPerso != null &&
                                _dateFinPerso != null
                            ? '${DateFormat('dd/MM').format(_dateDebutPerso!)} - ${DateFormat('dd/MM').format(_dateFinPerso!)}'
                            : choix.libelle,
                      ),
                      selected: actif,
                      onSelected: (_) => _choisirPeriode(choix),
                      selectedColor: AppColors.primaryBlue,
                      labelStyle: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: actif ? Colors.white : AppColors.textSecondary,
                      ),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: actif
                              ? AppColors.primaryBlue
                              : AppColors.border,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _SensSelector(
                      selection: _sens,
                      onChanged: (s) {
                        setState(() => _sens = s);
                        _relancerRecherche();
                      },
                    ),
                  ),
                  if (_filtresActifs) ...[
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: _reinitialiser,
                      child: const Text('Effacer'),
                    ),
                  ],
                ],
              ),
            ),
            if (_typesSelectionnes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _typesSelectionnes
                        .map((t) => Chip(
                              label: Text(
                                _typesConnus[t] ?? t,
                                style: const TextStyle(fontSize: 11),
                              ),
                              visualDensity: VisualDensity.compact,
                              onDeleted: () {
                                setState(() => _typesSelectionnes.remove(t));
                                _relancerRecherche();
                              },
                            ))
                        .toList(),
                  ),
                ),
              ),
            const SizedBox(height: 8),
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
                                  : 'Impossible de charger les transactions.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _relancerRecherche,
                              style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(160, 44)),
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
                        padding: EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                color: AppColors.textHint, size: 34),
                            SizedBox(height: 10),
                            Text(
                              'Aucune opération ne correspond à ces filtres.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => _relancerRecherche(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      itemCount: operations.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) =>
                          _OperationTile(operation: operations[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SensSelector extends StatelessWidget {
  final String? selection;
  final ValueChanged<String?> onChanged;

  const _SensSelector({required this.selection, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const options = [
      (null, 'Tout'),
      ('CREDIT', 'Crédit'),
      ('DEBIT', 'Débit'),
    ];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.border.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          for (final (valeur, label) in options)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(valeur),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: selection == valeur ? Colors.white : null,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: selection == valeur
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: selection == valeur
                          ? AppColors.textPrimary
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

class _FiltreTypesSheet extends StatefulWidget {
  final Set<String> selection;
  const _FiltreTypesSheet({required this.selection});

  @override
  State<_FiltreTypesSheet> createState() => _FiltreTypesSheetState();
}

class _FiltreTypesSheetState extends State<_FiltreTypesSheet> {
  late final Set<String> _selection = {...widget.selection};

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Filtrer par type',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _typesConnus.entries.map((entry) {
                  final actif = _selection.contains(entry.key);
                  return FilterChip(
                    label: Text(entry.value,
                        style: const TextStyle(fontSize: 12)),
                    selected: actif,
                    onSelected: (v) => setState(() {
                      if (v) {
                        _selection.add(entry.key);
                      } else {
                        _selection.remove(entry.key);
                      }
                    }),
                    selectedColor: AppColors.primaryBlue.withValues(alpha: 0.15),
                    checkmarkColor: AppColors.primaryBlue,
                    labelStyle: TextStyle(
                      color: actif
                          ? AppColors.primaryBlue
                          : AppColors.textSecondary,
                      fontWeight: actif ? FontWeight.w700 : FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: actif ? AppColors.primaryBlue : AppColors.border,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _selection.clear()),
                  child: const Text('Tout effacer'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _selection),
                  child: const Text('Appliquer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OperationTile extends StatelessWidget {
  final Operation operation;
  const _OperationTile({required this.operation});

  String get _icone {
    final type = (operation.type ?? operation.libelle).toUpperCase();
    if (type.contains('CNPS')) return '🏛️';
    if (type.contains('CMU') || type.contains('AMU')) return '🏥';
    if (type.contains('EPARGNE')) return '🏠';
    if (type.contains('VIREMENT')) return '📲';
    if (type.contains('COTISATION') || type.contains('PRELEV')) return '🧾';
    return operation.estCredit ? '💰' : '🏦';
  }

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
              color: operation.estCredit
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFF5F5F5),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(_icone, style: const TextStyle(fontSize: 17)),
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
            '${operation.estCredit ? '+' : '-'}${fmt.format(operation.montant)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: operation.estCredit
                  ? const Color(0xFF2E7D32)
                  : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
