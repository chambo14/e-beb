import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../domain/entities/recapitulatif.dart';
import '../../../domain/entities/type_cotisation.dart';
import '../../../presentation/providers/cotisation_providers.dart';
import '../../../presentation/providers/session_provider.dart';
import '../../../presentation/providers/utilisateur_providers.dart';

const _moisLabels = [
  'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
  'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
];

/// Un type de cotisation comparé sur le mois sélectionné : ce qui est visé
/// (réglage actuel du type/de la déclaration de revenu — pas un instantané
/// historique) contre ce qui a réellement été versé ce mois-là.
class _LigneComparaison {
  final String libelle;
  final double objectif;
  final double verse;

  const _LigneComparaison({
    required this.libelle,
    required this.objectif,
    required this.verse,
  });

  double get progression =>
      objectif <= 0 ? 0 : (verse / objectif).clamp(0.0, 1.0);
}

/// Récapitulatif mois par mois de chaque type de cotisation (CNPS, AMU,
/// cotisations personnalisées) — ouvert depuis la carte « Récapitulatif du
/// mois » de l'onglet Cotisations.
class RecapitulatifParTypeScreen extends ConsumerStatefulWidget {
  const RecapitulatifParTypeScreen({super.key});

  @override
  ConsumerState<RecapitulatifParTypeScreen> createState() =>
      _RecapitulatifParTypeScreenState();
}

class _RecapitulatifParTypeScreenState
    extends ConsumerState<RecapitulatifParTypeScreen> {
  late int _mois;
  late int _annee;

  @override
  void initState() {
    super.initState();
    final maintenant = DateTime.now();
    _mois = maintenant.month;
    _annee = maintenant.year;
  }

  bool get _estMoisCourant {
    final maintenant = DateTime.now();
    return _mois == maintenant.month && _annee == maintenant.year;
  }

  void _moisPrecedent() {
    setState(() {
      if (_mois == 1) {
        _mois = 12;
        _annee -= 1;
      } else {
        _mois -= 1;
      }
    });
  }

  void _moisSuivant() {
    if (_estMoisCourant) return;
    setState(() {
      if (_mois == 12) {
        _mois = 1;
        _annee += 1;
      } else {
        _mois += 1;
      }
    });
  }

  /// CNPS et AMU visent un montant issu de réglages actuels (déclaration de
  /// revenu, `montant_paiement_mensuel` du type — source de vérité du suivi
  /// de conformité, jamais `default_valeur` qui ne sert qu'à pré-remplir une
  /// règle de prélèvement) plutôt que d'un instantané par mois — même règle
  /// que `RecapitulatifService::calculerObjectifMensuel`.
  List<_LigneComparaison> _construireLignes(
    List<TypeCotisation> types,
    double? montantCotisationMensuelle,
    Recapitulatif recap,
  ) {
    final lignes = <_LigneComparaison>[];

    final cnps = types.where((t) => (t.code ?? '').toUpperCase() == 'CNPS');
    if (cnps.isNotEmpty) {
      lignes.add(_LigneComparaison(
        libelle: 'CNPS',
        objectif: montantCotisationMensuelle ?? 0,
        verse: recap.montantCotisationParType('COTISATION_CNPS'),
      ));
    }

    final amu = types.where((t) => (t.code ?? '').toUpperCase() == 'AMU');
    if (amu.isNotEmpty) {
      lignes.add(_LigneComparaison(
        libelle: 'CMU',
        objectif: amu.first.montantPaiementMensuel ?? 0,
        verse: recap.montantCotisationParType('COTISATION_AMU'),
      ));
    }

    for (final type in types.where((t) => t.estPersonnalise)) {
      final verse = recap.ventilationCotisations
          .where((l) => l.typeCotisationId == type.id)
          .fold<double>(0, (total, l) => total + l.montant);
      lignes.add(_LigneComparaison(
        libelle: type.libelle,
        objectif: type.montantPaiementMensuel ?? 0,
        verse: verse,
      ));
    }

    return lignes;
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'fr_FR');
    final types = ref.watch(cotisationsControllerProvider).valueOrNull ?? const [];
    final utilisateur = ref.watch(utilisateurCourantProvider);
    final recapAsync = ref.watch(
      recapitulatifMoisProvider((mois: _mois, annee: _annee)),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Récapitulatif par type',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _moisPrecedent,
                      icon: const Icon(Icons.chevron_left_rounded,
                          color: AppColors.primaryBlue),
                    ),
                    Text(
                      '${_moisLabels[_mois - 1]} $_annee',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: _estMoisCourant ? null : _moisSuivant,
                      icon: Icon(
                        Icons.chevron_right_rounded,
                        color: _estMoisCourant
                            ? AppColors.textHint
                            : AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: recapAsync.when(
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
                              : 'Impossible de charger ce récapitulatif.',
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
                            recapitulatifMoisProvider(
                                (mois: _mois, annee: _annee)),
                          ),
                          style: ElevatedButton.styleFrom(
                              minimumSize: const Size(160, 44)),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (recap) {
                  final lignes = _construireLignes(
                    types,
                    utilisateur?.montantCotisationMensuelle,
                    recap,
                  );

                  if (lignes.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'Aucun type de cotisation à comparer pour le moment.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: lignes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) =>
                        _CarteComparaison(ligne: lignes[i], fmt: fmt),
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

class _CarteComparaison extends StatelessWidget {
  final _LigneComparaison ligne;
  final NumberFormat fmt;

  const _CarteComparaison({required this.ligne, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  ligne.libelle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${(ligne.progression * 100).round()} %',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ligne.progression,
              minHeight: 7,
              backgroundColor: AppColors.border,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Versé : ${fmt.format(ligne.verse)} FCFA',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue),
              ),
              Text(
                'Objectif : ${fmt.format(ligne.objectif)} FCFA',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
