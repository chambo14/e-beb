import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_response.dart';

/// Appels HTTP des objectifs d'épargne.
class EpargneRemoteDataSource {
  final ApiClient _client;

  const EpargneRemoteDataSource(this._client);

  Future<ApiEnvelope> objectifs() => _client.get(ApiEndpoints.objectifsEpargne);

  Future<ApiEnvelope> ajouter(Map<String, dynamic> champs) =>
      _client.postForm(ApiEndpoints.objectifsEpargne, champs);

  /// Modification via method spoofing sur POST (multipart).
  Future<ApiEnvelope> modifier(String id, Map<String, dynamic> champs) =>
      _client.postForm(
        ApiEndpoints.objectifEpargne(id),
        champs,
        methodeSpoofee: 'patch',
      );

  Future<ApiEnvelope> supprimer(String id) =>
      _client.delete(ApiEndpoints.objectifEpargne(id));
}
