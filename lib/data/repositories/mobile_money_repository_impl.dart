import '../../domain/entities/compte_mobile_money.dart';
import '../../domain/repositories/mobile_money_repository.dart';
import '../datasources/mobile_money_remote_datasource.dart';

class MobileMoneyRepositoryImpl implements MobileMoneyRepository {
  final MobileMoneyRemoteDataSource _remote;

  const MobileMoneyRepositoryImpl(this._remote);

  @override
  Future<List<CompteMobileMoney>> comptes() async {
    final reponse = await _remote.comptes();
    return reponse.liste
        .map(CompteMobileMoney.depuisJson)
        .toList(growable: false);
  }

  @override
  Future<CompteMobileMoney> ajouterCompte({
    required String moyenPaiementId,
    required String numeroCompte,
    bool estPrincipal = false,
  }) async {
    final reponse = await _remote.ajouter(
      moyenPaiementId: moyenPaiementId,
      numeroCompte: numeroCompte,
      estPrincipal: estPrincipal,
    );
    return CompteMobileMoney.depuisJson(reponse.donnees);
  }

  @override
  Future<void> definirPrincipal(String compteId) =>
      _remote.definirPrincipal(compteId);
}
