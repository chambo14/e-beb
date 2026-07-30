import 'package:dio/dio.dart';

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

    final formData = FormData.fromMap(champs);
    formData.files.addAll([
      MapEntry('url_recto', await MultipartFile.fromFile(demande.cheminRecto)),
      MapEntry('url_verso', await MultipartFile.fromFile(demande.cheminVerso)),
      MapEntry(
        'url_selfie',
        await MultipartFile.fromFile(demande.cheminSelfie),
      ),
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
}
