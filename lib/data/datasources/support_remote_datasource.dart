import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_response.dart';

/// Appels HTTP du support utilisateur.
class SupportRemoteDataSource {
  final ApiClient _client;

  const SupportRemoteDataSource(this._client);

  Future<ApiEnvelope> signaler(String description) => _client.post(
    ApiEndpoints.supportSignaler,
    body: {'description': description},
  );
}
