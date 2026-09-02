import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_response.dart';

/// Appels HTTP du parcours « transfert par QR code » (statut SIMULE — voir
/// TransfertQrService côté back-end, aucune API opérateur réelle intégrée
/// pour l'instant).
class TransfertQrRemoteDataSource {
  final ApiClient _client;

  const TransfertQrRemoteDataSource(this._client);

  Future<ApiEnvelope> identifierDestinataire({
    required String compteSourceId,
    required String qrScanne,
  }) => _client.postForm(ApiEndpoints.identifierDestinataireQr, {
    'compte_source_id': compteSourceId,
    'qr_scanne': qrScanne,
  });

  Future<ApiEnvelope> envoyer({
    required String compteSourceId,
    required String qrScanne,
    required double montant,
  }) => _client.postForm(ApiEndpoints.envoyerTransfertQr, {
    'compte_source_id': compteSourceId,
    'qr_scanne': qrScanne,
    'montant': montant.toString(),
  });
}
