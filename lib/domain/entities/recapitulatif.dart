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

/// Récapitulatif des cotisations (`/espace-utilisateur/recapitulatif`).
class Recapitulatif {
  final double totalCibleMensuel;
  final double totalVerseMensuel;
  final double totalCibleAnnuel;
  final double totalVerseAnnuel;
  final List<LigneRecapitulatif> lignes;

  /// Payload d'origine : utile tant que le contrat back n'est pas figé.
  final Map<String, dynamic> brut;

  const Recapitulatif({
    this.totalCibleMensuel = 0,
    this.totalVerseMensuel = 0,
    this.totalCibleAnnuel = 0,
    this.totalVerseAnnuel = 0,
    this.lignes = const [],
    this.brut = const {},
  });

  static const vide = Recapitulatif();

  double get progressionMensuelle => totalCibleMensuel <= 0
      ? 0
      : (totalVerseMensuel / totalCibleMensuel).clamp(0.0, 1.0);

  double get progressionAnnuelle => totalCibleAnnuel <= 0
      ? 0
      : (totalVerseAnnuel / totalCibleAnnuel).clamp(0.0, 1.0);

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
      brut: json,
    );
  }
}
