import '../../core/utils/json_utils.dart';

/// Une ligne du récapitulatif : un type de cotisation et son avancement.
class LigneRecapitulatif {
  final String libelle;
  final String? code;
  final double montantCible;
  final double montantVerse;

  const LigneRecapitulatif({
    required this.libelle,
    this.code,
    this.montantCible = 0,
    this.montantVerse = 0,
  });

  double get progression =>
      montantCible <= 0 ? 0 : (montantVerse / montantCible).clamp(0.0, 1.0);

  double get reste =>
      (montantCible - montantVerse).clamp(0, double.infinity).toDouble();

  factory LigneRecapitulatif.depuisJson(Map<String, dynamic> json) {
    return LigneRecapitulatif(
      libelle: Json.texteOu(json, ['libelle', 'nom', 'label', 'type'], '—'),
      code: Json.texte(json, ['code']),
      montantCible: Json.decimalOu(json, [
        'montant_cible',
        'montant_attendu',
        'montant_du',
        'montant',
      ]),
      montantVerse: Json.decimalOu(json, [
        'montant_verse',
        'montant_paye',
        'montant_cotise',
        'total_verse',
      ]),
    );
  }
}

/// Montant versé pour un type de cotisation précis, sur la période couverte
/// par un `Recapitulatif` — lu depuis la ventilation réelle `cotisations` de
/// l'API (`RecapitulatifService::ventilerCotisations`).
class LigneCotisationVersee {
  final String typeOperation;

  /// `null` pour les types globaux non rattachés (ex. CNPS, identifié par
  /// son seul `type_operation`) ; toujours renseigné pour une cotisation
  /// personnalisée, qui partage `COTISATION_PERSONNALISEE` avec toutes les
  /// autres — seul cet identifiant permet de les distinguer entre elles.
  final String? typeCotisationId;
  final String libelle;
  final String? categorie;
  final double montant;

  const LigneCotisationVersee({
    required this.typeOperation,
    this.typeCotisationId,
    required this.libelle,
    this.categorie,
    this.montant = 0,
  });

  factory LigneCotisationVersee.depuisJson(Map<String, dynamic> json) {
    return LigneCotisationVersee(
      typeOperation: Json.texteOu(json, ['type_operation']),
      typeCotisationId: Json.texte(json, ['type_cotisation_id']),
      libelle: Json.texteOu(json, ['libelle'], '—'),
      categorie: Json.texte(json, ['categorie']),
      montant: Json.decimalOu(json, ['montant']),
    );
  }
}

/// Récapitulatif des cotisations (`/espace-utilisateur/recapitulatif`).
class Recapitulatif {
  final double totalCibleMensuel;
  final double totalVerseMensuel;
  final double totalCibleAnnuel;
  final double totalVerseAnnuel;
  final List<LigneRecapitulatif> lignes;

  /// Objectif total (CNPS déclaré + `default_valeur` de chaque autre type
  /// actif — AMU et cotisations personnalisées) — indépendant de la période
  /// affichée, voir `RecapitulatifService::calculerObjectifMensuel`.
  final double totalObjectifMensuel;

  // ── Champs réellement renvoyés par `RecapitulatifService::recapitulatif`
  // pour la période demandée (mois courant par défaut, ou l'intervalle
  // `date_debut`/`date_fin` fourni) ──────────────────────────────────────
  final double totalRecu;
  final double totalCotisations;
  final double totalCommissions;

  /// Cotisations + commissions, hors épargne — c'est le « total prélevé »
  /// affiché sur la carte de solde.
  final double totalPrelevementsHorsEpargne;
  final double totalEpargnePeriode;
  final double soldeTheorique;
  final double soldeDisponiblePeriode;

  /// Libellé de la période couverte (ex. « Août 2026 »), tel que renvoyé par
  /// le back-end pour un récapitulatif mensuel — `null` pour un intervalle
  /// libre (semaine, année), auquel cas l'appelant compose son propre libellé.
  final String? periodeLibelle;

  /// Payload d'origine : utile tant que le contrat back n'est pas figé.
  final Map<String, dynamic> brut;

  const Recapitulatif({
    this.totalCibleMensuel = 0,
    this.totalVerseMensuel = 0,
    this.totalCibleAnnuel = 0,
    this.totalVerseAnnuel = 0,
    this.lignes = const [],
    this.totalObjectifMensuel = 0,
    this.totalRecu = 0,
    this.totalCotisations = 0,
    this.totalCommissions = 0,
    this.totalPrelevementsHorsEpargne = 0,
    this.totalEpargnePeriode = 0,
    this.soldeTheorique = 0,
    this.soldeDisponiblePeriode = 0,
    this.periodeLibelle,
    this.brut = const {},
  });

  static const vide = Recapitulatif();

  double get progressionMensuelle => totalCibleMensuel <= 0
      ? 0
      : (totalVerseMensuel / totalCibleMensuel).clamp(0.0, 1.0);

  double get progressionAnnuelle => totalCibleAnnuel <= 0
      ? 0
      : (totalVerseAnnuel / totalCibleAnnuel).clamp(0.0, 1.0);

  /// Montant versé pour un type d'opération donné (ex. `COTISATION_CNPS`),
  /// lu directement dans la ventilation `cotisations` du payload d'origine —
  /// c'est la seule donnée fiable pour ce niveau de détail, `lignes` (ci-
  /// dessus) reposant sur un ancien contrat qui ne correspond plus à l'API.
  double montantCotisationParType(String typeOperation) {
    for (final c in Json.objets(brut, ['cotisations'])) {
      if (Json.texte(c, ['type_operation']) == typeOperation) {
        return Json.decimalOu(c, ['montant']);
      }
    }
    return 0;
  }

  /// Montant versé au titre de la cotisation CNPS sur la période couverte
  /// par ce récapitulatif.
  double get totalCotisationCnps => montantCotisationParType('COTISATION_CNPS');

  /// Ventilation structurée de `cotisations`, avec l'identifiant de type
  /// nécessaire pour distinguer plusieurs cotisations personnalisées entre
  /// elles (voir `LigneCotisationVersee`).
  List<LigneCotisationVersee> get ventilationCotisations => Json.objets(
        brut,
        ['cotisations'],
      ).map(LigneCotisationVersee.depuisJson).toList(growable: false);

  /// Reste à cotiser ce mois : objectif total moins ce qui a déjà été versé
  /// (jamais négatif).
  double get resteACotiser =>
      (totalObjectifMensuel - totalCotisations).clamp(0, double.infinity).toDouble();

  /// Avancement de l'objectif mensuel de cotisations (0 à 1).
  double get progressionCotisations => totalObjectifMensuel <= 0
      ? 0
      : (totalCotisations / totalObjectifMensuel).clamp(0.0, 1.0);

  double get resteMensuel =>
      (totalCibleMensuel - totalVerseMensuel).clamp(0, double.infinity).toDouble();

  double get resteAnnuel =>
      (totalCibleAnnuel - totalVerseAnnuel).clamp(0, double.infinity).toDouble();

  factory Recapitulatif.depuisJson(Map<String, dynamic> json) {
    final lignes = [
      ...Json.objets(json, ['cotisations', 'lignes', 'details', 'items']),
    ].map(LigneRecapitulatif.depuisJson).toList(growable: false);

    return Recapitulatif(
      totalCibleMensuel: Json.decimalOu(json, [
        'total_cible_mensuel',
        'montant_mensuel_cible',
        'cotisation_mensuelle_cible',
      ]),
      totalVerseMensuel: Json.decimalOu(json, [
        'total_verse_mensuel',
        'montant_mensuel_verse',
        'cotisation_mensuelle_versee',
      ]),
      totalCibleAnnuel: Json.decimalOu(json, [
        'total_cible_annuel',
        'montant_annuel_cible',
      ]),
      totalVerseAnnuel: Json.decimalOu(json, [
        'total_verse_annuel',
        'montant_annuel_verse',
      ]),
      lignes: lignes,
      totalObjectifMensuel: Json.decimalOu(json, ['total_objectif_mensuel']),
      totalRecu: Json.decimalOu(json, ['total_recu']),
      totalCotisations: Json.decimalOu(json, ['total_cotisations']),
      totalCommissions: Json.decimalOu(json, ['total_commissions']),
      totalPrelevementsHorsEpargne: Json.decimalOu(
        json,
        ['total_prelevements_hors_epargne'],
      ),
      totalEpargnePeriode: Json.decimalOu(json, ['total_epargne']),
      soldeTheorique: Json.decimalOu(json, ['solde_theorique']),
      soldeDisponiblePeriode: Json.decimalOu(json, ['solde_disponible']),
      periodeLibelle: Json.texte(
        Json.objet(json, ['periode']) ?? const {},
        ['libelle'],
      ),
      brut: json,
    );
  }
}
