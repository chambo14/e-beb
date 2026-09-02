/// Lecture tolérante des payloads JSON.
///
/// L'API renvoie selon les routes des nombres sous forme de chaînes
/// (`"242000"`), des booléens sous forme d'entiers (`1`) et des noms de champs
/// variables (`libelle` / `nom` / `label`). Ces helpers évitent de parsemer
/// les modèles de `as` fragiles.
class Json {
  const Json._();

  /// Première valeur non nulle parmi [cles].
  static Object? premier(Map<String, dynamic> json, List<String> cles) {
    for (final cle in cles) {
      final valeur = json[cle];
      if (valeur != null) return valeur;
    }
    return null;
  }

  static String? texte(Map<String, dynamic> json, List<String> cles) {
    final valeur = premier(json, cles);
    if (valeur == null) return null;
    final s = valeur is String ? valeur : '$valeur';
    return s.isEmpty ? null : s;
  }

  static String texteOu(
    Map<String, dynamic> json,
    List<String> cles, [
    String defaut = '',
  ]) => texte(json, cles) ?? defaut;

  static double? decimal(Map<String, dynamic> json, List<String> cles) {
    final valeur = premier(json, cles);
    return _versDouble(valeur);
  }

  static double decimalOu(
    Map<String, dynamic> json,
    List<String> cles, [
    double defaut = 0,
  ]) => decimal(json, cles) ?? defaut;

  static int? entier(Map<String, dynamic> json, List<String> cles) {
    final valeur = _versDouble(premier(json, cles));
    return valeur?.round();
  }

  static int entierOu(
    Map<String, dynamic> json,
    List<String> cles, [
    int defaut = 0,
  ]) => entier(json, cles) ?? defaut;

  /// Accepte `true`, `1`, `"1"`, `"true"`, `"oui"`.
  static bool booleen(
    Map<String, dynamic> json,
    List<String> cles, {
    bool defaut = false,
  }) {
    final valeur = premier(json, cles);
    if (valeur == null) return defaut;
    if (valeur is bool) return valeur;
    if (valeur is num) return valeur != 0;
    final s = '$valeur'.toLowerCase().trim();
    return s == '1' || s == 'true' || s == 'oui' || s == 'yes';
  }

  static DateTime? date(Map<String, dynamic> json, List<String> cles) {
    final valeur = texte(json, cles);
    if (valeur == null) return null;
    return DateTime.tryParse(valeur)?.toLocal();
  }

  /// Sous-objet, `null` si absent ou de type inattendu.
  static Map<String, dynamic>? objet(
    Map<String, dynamic> json,
    List<String> cles,
  ) {
    final valeur = premier(json, cles);
    if (valeur is Map) return Map<String, dynamic>.from(valeur);
    return null;
  }

  /// Liste d'objets, vide si absente.
  static List<Map<String, dynamic>> objets(
    Map<String, dynamic> json,
    List<String> cles,
  ) {
    final valeur = premier(json, cles);
    if (valeur is List) {
      return valeur
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(growable: false);
    }
    return const [];
  }

  static double? _versDouble(Object? valeur) {
    if (valeur == null) return null;
    if (valeur is num) return valeur.toDouble();
    // Tolère « 242 000,50 » et « 242000.50 ».
    final nettoye = '$valeur'
        .replaceAll(RegExp(r'[\s ]'), '')
        .replaceAll(',', '.');
    return double.tryParse(nettoye);
  }
}
