import '../entities/operation.dart';
import '../entities/paiement.dart';

/// Contrat de consultation des mouvements : paiements encaissés et opérations.
abstract class TransactionRepository {
  Future<List<Operation>> operations([FiltreOperations filtre]);

  Future<Operation> operation(String id);

  Future<List<Paiement>> paiements();

  Future<Paiement> paiement(String id);

  /// Simule l'encaissement d'un paiement client (route webhook).
  ///
  /// Utilisée par l'écran « recevoir un paiement » tant que la passerelle
  /// n'appelle pas directement le back-end.
  Future<Paiement> enregistrerPaiement({
    required String referenceExterne,
    required String qrCodeRef,
    required double montantBrut,
    String? description,
  });
}
