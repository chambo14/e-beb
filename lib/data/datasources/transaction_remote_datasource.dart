import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_response.dart';
import '../../domain/entities/operation.dart';

/// Appels HTTP des opérations et des paiements clients.
class TransactionRemoteDataSource {
  final ApiClient _client;

  const TransactionRemoteDataSource(this._client);

  /// `GET /espace-utilisateur/operations` — les filtres voyagent dans le corps
  /// de la requête, conformément à la collection Postman.
  Future<ApiEnvelope> operations(FiltreOperations filtre) => _client.get(
    ApiEndpoints.operations,
    body: filtre.estVide ? null : filtre.versJson(),
  );

  Future<ApiEnvelope> operation(String id) =>
      _client.get(ApiEndpoints.operation(id));

  Future<ApiEnvelope> paiements() => _client.get(ApiEndpoints.paiements);

  Future<ApiEnvelope> paiement(String id) =>
      _client.get(ApiEndpoints.paiement(id));

  Future<ApiEnvelope> enregistrerPaiement({
    required String referenceExterne,
    required String qrCodeRef,
    required num montantBrut,
    String? description,
  }) => _client.postForm(ApiEndpoints.paiementWebhook, {
    'reference_externe': referenceExterne,
    'qr_code_ref': qrCodeRef,
    'montant_brut': montantBrut.round().toString(),
    'description': description,
  });
}
