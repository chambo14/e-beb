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

  /// Règle de prélèvement déjà configurée par l'utilisateur, le cas échéant.
  final ReglePrelevement? regle;

  const TypeCotisation({
    required this.id,
    required this.libelle,
    this.code,
    this.categorie,
    this.description,
    this.montantPaiementMensuel,
    this.regle,
  });

  bool get estConfigure => regle != null;
  bool get estActif => regle?.estActif ?? false;

  /// `true` si l'utilisateur a lui-même créé ce type (cotisation personnalisée).
  bool get estPersonnalise =>
      (categorie ?? '').toUpperCase().contains('PERSONNALIS');

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
    regle: regle ?? this.regle,
  );
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
    return ReglePrelevement(
      id: Json.texte(json, ['id', 'uuid']),
      typeCotisationId: Json.texteOu(json, ['type_cotisation_id', 'type_id']),
      typeCalcul: TypeCalcul.depuisCode(Json.texte(json, ['type_calcul'])),
      valeur: Json.decimalOu(json, ['valeur', 'value', 'montant']),
      estActif: Json.booleen(json, ['est_actif', 'actif'], defaut: true),
    );
  }
}
