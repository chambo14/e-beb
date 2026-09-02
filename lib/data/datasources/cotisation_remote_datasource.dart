import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_response.dart';

/// Appels HTTP des règles de prélèvement et des cotisations personnalisées.
class CotisationRemoteDataSource {
  final ApiClient _client;

  const CotisationRemoteDataSource(this._client);

  Future<ApiEnvelope> types() => _client.get(ApiEndpoints.typesCotisation);

  Future<ApiEnvelope> configurerRegle({
    required String typeCotisationId,
    required String typeCalcul,
    required num valeur,
    required bool estActif,
  }) => _client.post(
    ApiEndpoints.configurerReglePrelevement,
    body: {
      'type_cotisation_id': typeCotisationId,
      'type_calcul': typeCalcul,
      'valeur': valeur,
      'est_actif': estActif ? 1 : 0,
    },
  );

  Future<ApiEnvelope> suggestionsTypesPersonnalises() =>
      _client.get(ApiEndpoints.suggestionsTypesCotisationPersonnalises);

  Future<ApiEnvelope> ajouterTypePersonnalise(Map<String, dynamic> corps) =>
      _client.post(ApiEndpoints.typesCotisationPersonnalises, body: corps);

  Future<ApiEnvelope> modifierTypePersonnalise(
    String id,
    Map<String, dynamic> corps,
  ) => _client.put(
    ApiEndpoints.typeCotisationPersonnalise(id),
    body: corps,
  );

  Future<ApiEnvelope> supprimerTypePersonnalise(String id) =>
      _client.delete(ApiEndpoints.typeCotisationPersonnalise(id));
}
