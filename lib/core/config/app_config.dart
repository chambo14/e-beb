/// Configuration globale de l'application.
///
/// L'URL de base est surchargeable au build :
///   flutter run --dart-define=EBEB_API_BASE_URL=https://staging.ebebfinance.com/api
class AppConfig {
  const AppConfig._();

  static const String baseUrl = String.fromEnvironment(
    'EBEB_API_BASE_URL',
    // defaultValue: 'https://ebebfinance.com/api',
    defaultValue: 'http://localhost:8000/api',
  );

  /// Active les logs détaillés des requêtes HTTP.
  static const bool enableHttpLogs = bool.fromEnvironment(
    'EBEB_HTTP_LOGS',
    defaultValue: true,
  );

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 60);

  /// Indicatif pays par défaut (Côte d'Ivoire).
  static const String defaultCountryCode = '+225';
}
