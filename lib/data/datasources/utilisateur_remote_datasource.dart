import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_response.dart';
import '../../domain/entities/demande_inscription.dart';

/// Appels HTTP du groupe « Profil utilisateur ».
class UtilisateurRemoteDataSource {
  final ApiClient _client;

  const UtilisateurRemoteDataSource(this._client);

  Future<ApiEnvelope> details() => _client.get(ApiEndpoints.details);

  Future<ApiEnvelope> solde() => _client.get(ApiEndpoints.solde);

  Future<ApiEnvelope> recapitulatif() =>
      _client.get(ApiEndpoints.recapitulatif);

  /// PATCH via method spoofing (multipart), comme dans la collection Postman.
  Future<ApiEnvelope> mettreAJourProfil(MiseAJourProfil mise) => _client
      .postForm(ApiEndpoints.profil, mise.versChamps(), methodeSpoofee: 'patch');

  Future<ApiEnvelope> modifierCodePin({
    required String ancienCodePin,
    required String nouveauCodePin,
  }) => _client.postForm(ApiEndpoints.codePin, {
    'ancien_code_pin': ancienCodePin,
    'nouveau_code_pin': nouveauCodePin,
    'nouveau_code_pin_confirmation': nouveauCodePin,
  }, methodeSpoofee: 'patch');
}
