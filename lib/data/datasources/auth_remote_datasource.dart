import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_response.dart';
import '../../domain/entities/demande_inscription.dart';

/// Appels HTTP bruts du groupe `auth` de la collection Postman.
class AuthRemoteDataSource {
  final ApiClient _client;

  const AuthRemoteDataSource(this._client);

  /// `POST /auth/inscription` — multipart avec recto, verso et selfie.
  Future<ApiEnvelope> inscrire(DemandeInscription demande) async {
    final champs = demande.versChamps()
      ..removeWhere((_, valeur) => valeur == null);

    // Trace du payload sortant : indispensable pour confronter ce que l'app
    // envoie aux valeurs attendues par le back-end. Debug uniquement.
    if (AppConfig.enableHttpLogs) {
      final apercu = champs.entries
          .map((e) => '  ${e.key} = ${e.value}')
          .join('\n');
      developer.log('Inscription — champs envoyés :\n$apercu', name: 'ApiClient');
    }

    // fromBytes plutôt que fromFile : ce dernier passe par dart:io, absent du
    // web. Les octets fonctionnent sur toutes les plateformes.
    final formData = FormData.fromMap(champs);
    formData.files.addAll([
      MapEntry('url_recto', _versMultipart(demande.recto)),
      MapEntry('url_verso', _versMultipart(demande.verso)),
      MapEntry('url_selfie', _versMultipart(demande.selfie)),
    ]);

    return _client.postFormData(ApiEndpoints.inscription, formData);
  }

  Future<ApiEnvelope> verifierOtp({
    required String telephone,
    required String codeOtp,
  }) => _client.post(
    ApiEndpoints.otpVerifier,
    body: {'telephone': telephone, 'code_otp': codeOtp},
  );

  Future<ApiEnvelope> renvoyerOtp(String telephone) =>
      _client.post(ApiEndpoints.otpRenvoyer, body: {'telephone': telephone});

  Future<ApiEnvelope> definirCodePin({
    required String telephone,
    required String codePin,
  }) => _client.post(
    ApiEndpoints.configurerCodePin,
    body: {'telephone': telephone, 'password': codePin},
  );

  Future<ApiEnvelope> connexion(String telephone) =>
      _client.post(ApiEndpoints.connexion, body: {'telephone': telephone});

  Future<ApiEnvelope> confirmerConnexion({
    required String telephone,
    required String codeOtp,
  }) => _client.post(
    ApiEndpoints.otpConfirmerConnexion,
    body: {'telephone': telephone, 'code_otp': codeOtp},
  );

  Future<ApiEnvelope> deconnexion() => _client.post(ApiEndpoints.deconnexion);

  /// L'API n'accepte que des images : le nom de fichier porte l'extension,
  /// dont Laravel se sert pour déterminer le type MIME.
  MultipartFile _versMultipart(FichierJoint fichier) =>
      MultipartFile.fromBytes(fichier.octets, filename: fichier.nom);
}
