/// Enveloppe standard renvoyée par l'API :
/// `{"success": true, "data": {...}, "message": "..."}`.
///
/// Certaines routes omettent `data` (actions sans contenu) ; les accesseurs
/// tolèrent ce cas plutôt que de lever une exception.
class ApiEnvelope {
  final bool success;
  final Object? data;
  final String? message;
  final Map<String, dynamic> brut;

  const ApiEnvelope({
    required this.success,
    required this.data,
    required this.message,
    required this.brut,
  });

  factory ApiEnvelope.depuisJson(Object? corps) {
    if (corps is! Map) {
      // Réponse non enveloppée (rare) : on la traite comme la donnée utile.
      return ApiEnvelope(
        success: true,
        data: corps,
        message: null,
        brut: const {},
      );
    }
    final map = Map<String, dynamic>.from(corps);
    return ApiEnvelope(
      success: map['success'] as bool? ?? true,
      data: map.containsKey('data') ? map['data'] : null,
      message: map['message'] as String?,
      brut: map,
    );
  }

  /// `data` sous forme d'objet, `{}` si absent.
  Map<String, dynamic> get donnees {
    final d = data;
    if (d is Map) return Map<String, dynamic>.from(d);
    return const {};
  }

  /// `data` sous forme de liste.
  ///
  /// Gère aussi la pagination Laravel (`data.data`) et les collections
  /// imbriquées sous une clé unique.
  List<Map<String, dynamic>> get liste {
    final d = data;
    if (d is List) return _versListeDeMaps(d);
    if (d is Map) {
      final interne = d['data'];
      if (interne is List) return _versListeDeMaps(interne);
      // Un seul objet renvoyé là où une liste est attendue.
      if (d.isNotEmpty && d.values.length == 1) {
        final unique = d.values.first;
        if (unique is List) return _versListeDeMaps(unique);
      }
    }
    return const [];
  }

  /// Métadonnées de pagination Laravel, si présentes.
  Map<String, dynamic> get pagination {
    final d = data;
    if (d is Map && d['meta'] is Map) {
      return Map<String, dynamic>.from(d['meta'] as Map);
    }
    return const {};
  }

  static List<Map<String, dynamic>> _versListeDeMaps(List source) => source
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList(growable: false);
}
