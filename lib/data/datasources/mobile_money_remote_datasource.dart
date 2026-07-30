import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_response.dart';

/// Appels HTTP des comptes mobile money.
class MobileMoneyRemoteDataSource {
  final ApiClient _client;

  const MobileMoneyRemoteDataSource(this._client);

  Future<ApiEnvelope> comptes() =>
      _client.get(ApiEndpoints.comptesMobileMoney);

  Future<ApiEnvelope> ajouter({
    required String moyenPaiementId,
    required String numeroCompte,
    required bool estPrincipal,
  }) => _client.postForm(ApiEndpoints.comptesMobileMoney, {
    'moyen_paiement_id': moyenPaiementId,
    'numero_compte': numeroCompte,
    'est_principal': estPrincipal ? '1' : '0',
  });

  Future<ApiEnvelope> definirPrincipal(String compteId) =>
      _client.patch(ApiEndpoints.compteMobileMoneyPrincipal(compteId));
}
