import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_response.dart';

/// Appels HTTP des pages de contenu CMS (Conditions générales, Avis de
/// confidentialité...).
class PageRemoteDataSource {
  final ApiClient _client;

  const PageRemoteDataSource(this._client);

  Future<ApiEnvelope> parType(String type) => _client.get(ApiEndpoints.page(type));
}
