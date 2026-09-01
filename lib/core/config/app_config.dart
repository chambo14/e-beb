import 'package:flutter/foundation.dart' show kReleaseMode;

/// Configuration globale de l'application.
///
/// L'URL de base est surchargeable au build (utile en local uniquement) :
///   flutter run --dart-define=EBEB_API_BASE_URL=http://localhost:8000/api
class AppConfig {
  const AppConfig._();

  static const String baseUrl = String.fromEnvironment(
    'EBEB_API_BASE_URL',
    defaultValue: 'https://ebebfinance.com/api',
  );

  /// Active les logs détaillés des requêtes HTTP (méthode/URL/statut, jamais
  /// le jeton d'authentification — masqué explicitement côté client HTTP).
  /// Activés par défaut en debug (confort de développement), mais
  /// `kReleaseMode` bloque toujours l'activation en build release, quel que
  /// soit le define passé par erreur au build — sans quoi un
  /// `flutter build apk --release` sans `--dart-define` explicite embarquait
  /// ces logs par défaut (payloads d'inscription complets, corps d'erreur).
  static const bool enableHttpLogs =
      !kReleaseMode &&
      bool.fromEnvironment('EBEB_HTTP_LOGS', defaultValue: true);

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 60);

  /// Indicatif pays par défaut (Côte d'Ivoire).
  static const String defaultCountryCode = '+225';
}
