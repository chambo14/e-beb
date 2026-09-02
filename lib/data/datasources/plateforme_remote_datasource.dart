import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_response.dart';

/// Appels HTTP publics (sans jeton).
class PlateformeRemoteDataSource {
  final ApiClient _client;

  const PlateformeRemoteDataSource(this._client);

  Future<ApiEnvelope> infos() => _client.get(ApiEndpoints.infosPlateforme);
}
