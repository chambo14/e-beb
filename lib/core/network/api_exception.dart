/// Nature d'une erreur remontée par la couche réseau.
enum ApiErrorType {
  /// Pas de connexion, DNS injoignable, socket fermée.
  reseau,

  /// Délai d'attente dépassé.
  delaiDepasse,

  /// 401 — jeton absent, expiré ou révoqué.
  nonAuthentifie,

  /// 403 — authentifié mais action interdite.
  interdit,

  /// 404 — ressource inexistante.
  introuvable,

  /// 422 — validation Laravel, voir [ApiException.erreursChamps].
  validation,

  /// 429 — trop de requêtes.
  tropDeRequetes,

  /// 5xx.
  serveur,

  /// Réponse illisible ou cas non couvert.
  inconnu,
}

/// Erreur normalisée de la couche réseau, porteuse d'un message affichable
/// à l'utilisateur (en français, fourni par l'API quand disponible).
class ApiException implements Exception {
  final ApiErrorType type;
  final String message;
  final int? statusCode;

  /// Erreurs de validation Laravel : `{"telephone": ["Le numéro ..."]}`.
  final Map<String, List<String>> erreursChamps;

  const ApiException({
    required this.type,
    required this.message,
    this.statusCode,
    this.erreursChamps = const {},
  });

  bool get estValidation => type == ApiErrorType.validation;
  bool get estNonAuthentifie => type == ApiErrorType.nonAuthentifie;

  /// Première erreur associée à [champ], si elle existe.
  String? erreurPour(String champ) {
    final erreurs = erreursChamps[champ];
    return (erreurs == null || erreurs.isEmpty) ? null : erreurs.first;
  }

  /// Tous les messages de validation aplatis, un par ligne.
  String get messagesValidation => erreursChamps.values
      .expand((e) => e)
      .join('\n');

  factory ApiException.reseau() => const ApiException(
    type: ApiErrorType.reseau,
    message:
        'Connexion impossible. Vérifiez votre connexion internet et réessayez.',
  );

  /// Sur le web, un échec au niveau transport vient presque toujours du CORS :
  /// l'API ne renvoie pas d'en-tête `Access-Control-Allow-Origin`, le
  /// navigateur bloque donc la requête avant qu'elle parte. Inutile
  /// d'envoyer l'utilisateur vérifier son réseau.
  factory ApiException.corsWeb() => const ApiException(
    type: ApiErrorType.reseau,
    message:
        'Le serveur refuse les appels depuis un navigateur (CORS non '
        'configuré). Utilisez l\'application Android, ou demandez à l\'équipe '
        'back-end d\'autoriser cette origine.',
  );

  factory ApiException.delaiDepasse() => const ApiException(
    type: ApiErrorType.delaiDepasse,
    message: 'Le serveur met trop de temps à répondre. Veuillez réessayer.',
  );

  factory ApiException.inconnu([String? message]) => ApiException(
    type: ApiErrorType.inconnu,
    message: message ?? 'Une erreur inattendue est survenue.',
  );

  @override
  String toString() => 'ApiException($type, $statusCode): $message';
}
