import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_response.dart';

/// Appels HTTP des notifications.
class NotificationRemoteDataSource {
  final ApiClient _client;

  const NotificationRemoteDataSource(this._client);

  Future<ApiEnvelope> toutes() => _client.get(ApiEndpoints.notifications);

  Future<ApiEnvelope> nonLues() =>
      _client.get(ApiEndpoints.notificationsNonLues);

  Future<ApiEnvelope> marquerLue(String id) =>
      _client.patch(ApiEndpoints.notificationLue(id));

  Future<ApiEnvelope> marquerToutesLues() =>
      _client.patch(ApiEndpoints.notificationsToutesLues);
}
