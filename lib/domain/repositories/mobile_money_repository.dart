import '../entities/compte_mobile_money.dart';

/// Contrat de gestion des comptes mobile money.
abstract class MobileMoneyRepository {
  Future<List<CompteMobileMoney>> comptes();

  Future<CompteMobileMoney> ajouterCompte({
    required String moyenPaiementId,
    required String numeroCompte,
    bool estPrincipal,
  });

  Future<void> definirPrincipal(String compteId);
}
