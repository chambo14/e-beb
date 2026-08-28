import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';
import 'api_response.dart';

/// Client HTTP unique de l'application.
///
/// Responsabilités : injection du jeton Sanctum, normalisation des erreurs en
/// [ApiException] et déballage de l'enveloppe `{success, data, message}`.
class ApiClient {
  final Dio _dio;
  final TokenStorage _tokenStorage;

  /// Invoqué sur toute réponse 401 : permet à la couche session de purger le
  /// jeton et de renvoyer l'utilisateur vers l'écran de connexion.
  void Function()? onNonAuthentifie;

  ApiClient({required TokenStorage tokenStorage, Dio? dio})
    : _tokenStorage = tokenStorage,
      _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConfig.baseUrl,
              connectTimeout: AppConfig.connectTimeout,
              receiveTimeout: AppConfig.receiveTimeout,
              sendTimeout: AppConfig.sendTimeout,
              headers: {'Accept': 'application/json'},
              // On gère nous-mêmes les codes d'erreur pour produire des
              // messages exploitables plutôt que des DioException brutes.
              validateStatus: (_) => true,
            ),
          ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Les routes publiques ne doivent jamais porter d'Authorization :
          // un jeton périmé resté en stockage ferait échouer une inscription
          // ou une connexion qui n'a pourtant besoin d'aucune session.
          if (!_estRoutePublique(options.path)) {
            final token = await _tokenStorage.lireToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          if (AppConfig.enableHttpLogs) {
            developer.log(
              '→ ${options.method} ${options.uri}\n'
              '${_enTetesLisibles(options)}',
              name: 'ApiClient',
            );
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          if (AppConfig.enableHttpLogs) {
            developer.log(
              '← ${response.statusCode} ${response.requestOptions.uri}',
              name: 'ApiClient',
            );
          }
          handler.next(response);
        },
      ),
    );
  }

  Dio get dio => _dio;

  /// Routes accessibles sans session : inscription, OTP, connexion, et les
  /// informations publiques de la plateforme.
  ///
  /// La déconnexion (`/espace-utilisateur/se-deconnecter`) vit sous `auth`
  /// côté métier mais exige le jeton : elle n'est pas concernée.
  static bool _estRoutePublique(String chemin) =>
      chemin.startsWith('/auth/') ||
      chemin.startsWith('/administration/public/');

  /// En-têtes effectivement envoyés, pour comparaison avec Postman.
  ///
  /// Le `Content-Type` n'est pas dans `options.headers` tant que Dio ne l'a
  /// pas déduit du corps : on lit `options.contentType`, qui reflète ce qui
  /// partira réellement (avec le boundary pour un multipart).
  static String _enTetesLisibles(RequestOptions options) {
    final lignes = <String>[
      '  content-type: ${options.contentType ?? '(déduit du corps)'}',
    ];
    options.headers.forEach((cle, valeur) {
      // Le jeton n'a pas à finir dans les journaux.
      final affichee = cle.toLowerCase() == 'authorization'
          ? 'Bearer …(masqué)'
          : valeur;
      lignes.add('  $cle: $affichee');
    });
    return lignes.join('\n');
  }

  Future<ApiEnvelope> get(
    String chemin, {
    Map<String, dynamic>? queryParameters,
    Object? body,
  }) => _executer(
    () => _dio.get(chemin, queryParameters: queryParameters, data: body),
  );

  Future<ApiEnvelope> post(String chemin, {Object? body}) =>
      _executer(() => _dio.post(chemin, data: body));

  Future<ApiEnvelope> put(String chemin, {Object? body}) =>
      _executer(() => _dio.put(chemin, data: body));

  Future<ApiEnvelope> patch(String chemin, {Object? body}) =>
      _executer(() => _dio.patch(chemin, data: body));

  Future<ApiEnvelope> delete(String chemin, {Object? body}) =>
      _executer(() => _dio.delete(chemin, data: body));

  /// Envoi `multipart/form-data`.
  ///
  /// Laravel n'accepte pas de corps multipart sur PATCH/PUT : on passe par un
  /// POST avec le champ `_method` (method spoofing), comme dans la collection
  /// Postman.
  Future<ApiEnvelope> postForm(
    String chemin,
    Map<String, dynamic> champs, {
    String? methodeSpoofee,
  }) {
    final data = Map<String, dynamic>.from(champs);
    if (methodeSpoofee != null) {
      data['_method'] = methodeSpoofee;
    }
    data.removeWhere((_, valeur) => valeur == null);
    return _executer(() => _dio.post(chemin, data: FormData.fromMap(data)));
  }

  /// Envoi d'un [FormData] déjà construit (cas des pièces jointes), tout en
  /// conservant la normalisation d'erreurs et le déballage de l'enveloppe.
  Future<ApiEnvelope> postFormData(String chemin, FormData formData) =>
      _executer(() => _dio.post(chemin, data: formData));

  Future<ApiEnvelope> _executer(
    Future<Response<dynamic>> Function() appel,
  ) async {
    late final Response<dynamic> reponse;
    try {
      reponse = await appel();
    } on DioException catch (e) {
      throw _depuisDioException(e);
    } catch (e) {
      throw ApiException.inconnu(e.toString());
    }

    final code = reponse.statusCode ?? 0;
    if (code >= 200 && code < 300) {
      final enveloppe = ApiEnvelope.depuisJson(reponse.data);
      // Certaines routes renvoient 200 avec success=false pour un échec métier.
      if (!enveloppe.success) {
        throw ApiException(
          type: ApiErrorType.inconnu,
          statusCode: code,
          message: enveloppe.message ?? 'L\'opération n\'a pas abouti.',
        );
      }
      return enveloppe;
    }

    throw _depuisReponseErreur(code, reponse.data);
  }

  ApiException _depuisReponseErreur(int code, Object? corps) {
    final map = corps is Map ? Map<String, dynamic>.from(corps) : const {};
    final message = map['message'] as String?;
    final erreurs = _extraireErreurs(map['errors']);

    developer.log(
      'code Erreur API $code : $message, erreurs : $erreurs',
      name: 'ApiClient',
    );
    // Le message affiché à l'utilisateur est volontairement générique pour les
    // erreurs serveur ; on trace la réponse brute pour pouvoir diagnostiquer.
    if (AppConfig.enableHttpLogs && code >= 400) {
      developer.log(
        'Erreur $code — réponse brute : $corps',
        name: 'ApiClient',
        level: 1000,
      );
    }

    switch (code) {
      case 401:
        onNonAuthentifie?.call();
        return ApiException(
          type: ApiErrorType.nonAuthentifie,
          statusCode: code,
          message: 'Votre session a expiré. Veuillez vous reconnecter.',
        );
      case 403:
        return ApiException(
          type: ApiErrorType.interdit,
          statusCode: code,
          message:
              message ?? 'Vous n\'êtes pas autorisé à effectuer cette action.',
        );
      case 404:
        return ApiException(
          type: ApiErrorType.introuvable,
          statusCode: code,
          message: message ?? 'Ressource introuvable.',
        );
      case 422:
        return ApiException(
          type: ApiErrorType.validation,
          statusCode: code,
          message: message ?? 'Certaines informations sont invalides.',
          erreursChamps: erreurs,
        );
      case 429:
        return ApiException(
          type: ApiErrorType.tropDeRequetes,
          statusCode: code,
          message:
              message ?? 'Trop de tentatives. Patientez avant de réessayer.',
        );
      default:
        if (code >= 500) {
          return ApiException(
            type: ApiErrorType.serveur,
            statusCode: code,
            // Le back-end renvoie déjà un message sûr (jamais la trace brute,
            // voir BaseController::throw) : on l'affiche tel quel plutôt que
            // d'écraser systématiquement avec un texte générique.
            message:
                message ??
                'Le service est momentanément indisponible. Réessayez plus tard.',
          );
        }
        return ApiException(
          type: ApiErrorType.inconnu,
          statusCode: code,
          message: message ?? 'Une erreur inattendue est survenue.',
        );
    }
  }

  Map<String, List<String>> _extraireErreurs(Object? errors) {
    if (errors is! Map) return const {};
    final resultat = <String, List<String>>{};
    errors.forEach((cle, valeur) {
      if (valeur is List) {
        resultat['$cle'] = valeur.map((e) => '$e').toList();
      } else if (valeur != null) {
        resultat['$cle'] = ['$valeur'];
      }
    });
    return resultat;
  }

  ApiException _depuisDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException.delaiDepasse();
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return _echecTransport();
      case DioExceptionType.cancel:
        return const ApiException(
          type: ApiErrorType.inconnu,
          message: 'Requête annulée.',
        );
      case DioExceptionType.badResponse:
        return _depuisReponseErreur(
          e.response?.statusCode ?? 0,
          e.response?.data,
        );
      case DioExceptionType.unknown:
        return _echecTransport();
    }
  }

  /// Échec avant toute réponse HTTP. Sur le web, le navigateur masque la cause
  /// réelle d'un blocage CORS derrière une erreur réseau générique.
  ApiException _echecTransport() =>
      kIsWeb ? ApiException.corsWeb() : ApiException.reseau();
}
