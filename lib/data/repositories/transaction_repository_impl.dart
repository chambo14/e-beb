import '../../domain/entities/operation.dart';
import '../../domain/entities/paiement.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_remote_datasource.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionRemoteDataSource _remote;

  const TransactionRepositoryImpl(this._remote);

  @override
  Future<List<Operation>> operations([
    FiltreOperations filtre = FiltreOperations.aucun,
  ]) async {
    final reponse = await _remote.operations(filtre);
    final operations = reponse.liste
        .map(Operation.depuisJson)
        .toList(growable: false);
    // Le back-end ne garantit pas l'ordre : on affiche du plus récent au plus
    // ancien.
    return operations.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<Operation> operation(String id) async {
    final reponse = await _remote.operation(id);
    return Operation.depuisJson(reponse.donnees);
  }

  @override
  Future<List<Paiement>> paiements() async {
    final reponse = await _remote.paiements();
    final paiements = reponse.liste
        .map(Paiement.depuisJson)
        .toList(growable: false);
    return paiements.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<Paiement> paiement(String id) async {
    final reponse = await _remote.paiement(id);
    return Paiement.depuisJson(reponse.donnees);
  }

  @override
  Future<Paiement> enregistrerPaiement({
    required String referenceExterne,
    required String qrCodeRef,
    required double montantBrut,
    String? description,
  }) async {
    final reponse = await _remote.enregistrerPaiement(
      referenceExterne: referenceExterne,
      qrCodeRef: qrCodeRef,
      montantBrut: montantBrut,
      description: description,
    );
    return Paiement.depuisJson(reponse.donnees);
  }
}
