import '../../core/utils/json_utils.dart';

/// Mode de calcul d'un prélèvement.
enum TypeCalcul {
  fixe('FIXE', 'Montant fixe'),
  pourcentage('POURCENTAGE', 'Pourcentage');

  final String code;
  final String libelle;
  const TypeCalcul(this.code, this.libelle);

  static TypeCalcul depuisCode(String? code) =>
      code?.toUpperCase() == 'POURCENTAGE' ? pourcentage : fixe;
}

/// Type de cotisation proposé par la plateforme
/// (`/espace-utilisateur/regle-prelevements/types`).
class TypeCotisation {
  final String id;
  final String libelle;
  final String? code;
  final String? categorie;
  final String? description;
  final double? montantPaiementMensuel;
  final bool estPersonnaliseApi;

  /// Mode de calcul et valeur par défaut du type, configurés côté back-end
  /// (`default_type_calcul` / `default_valeur`). Utilisés pour pré-remplir le
  /// taux tant que l'utilisateur n'a pas encore sa propre règle.
  final TypeCalcul? typeCalculParDefaut;
  final double? valeurParDefaut;

  /// Règle de prélèvement déjà configurée par l'utilisateur, le cas échéant.
  final ReglePrelevement? regle;

  const TypeCotisation({
    required this.id,
    required this.libelle,
    this.code,
    this.categorie,
    this.description,
    this.montantPaiementMensuel,
    this.estPersonnaliseApi = false,
    this.typeCalculParDefaut,
    this.valeurParDefaut,
    this.regle,
  });

  bool get estConfigure => regle != null;
  bool get estActif => regle?.estActif ?? false;

  /// `true` si l'utilisateur a lui-même créé ce type (cotisation personnalisée).
  ///
  /// Priorité au champ `est_personnalise` renvoyé par l'API (source de
  /// vérité, basé sur `user_id`) ; le mot-clé dans `categorie` ne sert que de
  /// filet de sécurité si ce champ est absent d'une réponse plus ancienne.
  bool get estPersonnalise =>
      estPersonnaliseApi ||
      (categorie ?? '').toUpperCase().contains('PERSONNALIS');

  /// Mode de calcul à utiliser pour pré-remplir un formulaire : la règle déjà
  /// configurée prime, sinon le défaut du type, sinon POURCENTAGE.
  TypeCalcul get typeCalculEffectif =>
      regle?.typeCalcul ?? typeCalculParDefaut ?? TypeCalcul.pourcentage;

  /// Valeur à utiliser pour pré-remplir un formulaire : la règle déjà
  /// configurée prime, sinon le défaut du type, sinon 5 (règle plateforme :
  /// taux par défaut de 5 % quand rien n'est configuré en base).
  double get valeurEffective => regle?.valeur ?? valeurParDefaut ?? 5;

  factory TypeCotisation.depuisJson(Map<String, dynamic> json) {
    final regleJson = Json.objet(json, [
      'regle_prelevement',
      'regle',
      'regle_utilisateur',
    ]);

    return TypeCotisation(
      id: Json.texteOu(json, ['id', 'uuid', 'type_cotisation_id']),
      libelle: Json.texteOu(json, ['libelle', 'nom', 'label'], '—'),
      code: Json.texte(json, ['code']),
      categorie: Json.texte(json, ['categorie', 'category']),
      description: Json.texte(json, ['description']),
      montantPaiementMensuel: Json.decimal(json, [
        'montant_paiement_mensuel',
        'montant_mensuel',
      ]),
      estPersonnaliseApi: Json.booleen(json, ['est_personnalise']),
      typeCalculParDefaut: Json.texte(json, ['default_type_calcul']) == null
          ? null
          : TypeCalcul.depuisCode(Json.texte(json, ['default_type_calcul'])),
      valeurParDefaut: Json.decimal(json, ['default_valeur']),
      regle: regleJson == null ? null : ReglePrelevement.depuisJson(regleJson),
    );
  }

  TypeCotisation copyWith({ReglePrelevement? regle}) => TypeCotisation(
    id: id,
    libelle: libelle,
    code: code,
    categorie: categorie,
    description: description,
    montantPaiementMensuel: montantPaiementMensuel,
    estPersonnaliseApi: estPersonnaliseApi,
    typeCalculParDefaut: typeCalculParDefaut,
    valeurParDefaut: valeurParDefaut,
    regle: regle ?? this.regle,
  );
}

/// Suggestion de type de cotisation personnalisé déjà créé par un autre
/// utilisateur (`/types-cotisation-personnalises/suggestions`) — libellé,
/// code et catégorie uniquement : ni montant ni description, propres à
/// chaque utilisateur. La sélectionner crée une nouvelle ligne pour
/// l'utilisateur courant sans jamais modifier le type d'origine.
class SuggestionTypeCotisation {
  final String libelle;
  final String code;
  final String? categorie;

  const SuggestionTypeCotisation({
    required this.libelle,
    required this.code,
    this.categorie,
  });

  factory SuggestionTypeCotisation.depuisJson(Map<String, dynamic> json) {
    return SuggestionTypeCotisation(
      libelle: Json.texteOu(json, ['libelle'], '—'),
      code: Json.texteOu(json, ['code']),
      categorie: Json.texte(json, ['categorie']),
    );
  }
}

/// Règle de prélèvement configurée par l'utilisateur pour un type de cotisation.
class ReglePrelevement {
  final String? id;
  final String typeCotisationId;
  final TypeCalcul typeCalcul;
  final double valeur;
  final bool estActif;

  const ReglePrelevement({
    this.id,
    required this.typeCotisationId,
    required this.typeCalcul,
    required this.valeur,
    this.estActif = true,
  });

  /// `3 %` ou `2 000 FCFA` selon le mode de calcul.
  String get valeurAffichee => typeCalcul == TypeCalcul.pourcentage
      ? '${valeur.toStringAsFixed(valeur.truncateToDouble() == valeur ? 0 : 2)} %'
      : '${valeur.round()} FCFA';

  factory ReglePrelevement.depuisJson(Map<String, dynamic> json) {
    final typeCalcul = TypeCalcul.depuisCode(Json.texte(json, ['type_calcul']));

    // Deux formats coexistent selon la route : le modèle brut renvoie la
    // valeur sous `valeur` (ex. réponse de `configurer-regle-prelevement`),
    // tandis que `regle-prelevements/types` la sépare en `taux` (POURCENTAGE)
    // / `montant` (FIXE), l'autre champ étant toujours à 0. Ne lire que
    // `montant` faisait retomber à 0 toute règle en pourcentage (CNPS,
    // cotisations personnalisées) puisque son `montant` est toujours nul.
    final valeurDirecte = Json.decimal(json, ['valeur', 'value']);
    final valeur = valeurDirecte ??
        (typeCalcul == TypeCalcul.pourcentage
            ? Json.decimalOu(json, ['taux'])
            : Json.decimalOu(json, ['montant']));

    return ReglePrelevement(
      id: Json.texte(json, ['id', 'uuid']),
      typeCotisationId: Json.texteOu(json, ['type_cotisation_id', 'type_id']),
      typeCalcul: typeCalcul,
      valeur: valeur,
      estActif: Json.booleen(json, ['est_actif', 'actif'], defaut: true),
    );
  }
}
