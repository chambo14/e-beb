import '../../domain/entities/destinataire_qr.dart';
import '../../domain/repositories/transfert_qr_repository.dart';
import '../datasources/transfert_qr_remote_datasource.dart';

class TransfertQrRepositoryImpl implements TransfertQrRepository {
  final TransfertQrRemoteDataSource _remote;

  const TransfertQrRepositoryImpl(this._remote);

  @override
  Future<DestinataireQr> identifierDestinataire({
    required String compteSourceId,
    required String qrScanne,
  }) async {
    final reponse = await _remote.identifierDestinataire(
      compteSourceId: compteSourceId,
      qrScanne: qrScanne,
    );
    return DestinataireQr.depuisJson(
      reponse.donnees['compte_destinataire'] as Map<String, dynamic>,
    );
  }

  @override
  Future<void> envoyer({
    required String compteSourceId,
    required String qrScanne,
    required double montant,
  }) async {
    await _remote.envoyer(
      compteSourceId: compteSourceId,
      qrScanne: qrScanne,
      montant: montant,
    );
  }
}
