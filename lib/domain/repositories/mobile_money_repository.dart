import '../entities/compte_mobile_money.dart';

/// Contrat de gestion des comptes mobile money.
abstract class MobileMoneyRepository {
  /// Moyens de paiement actifs (Wave, Orange Money, ...) parmi lesquels
  /// choisir un compte principal.
  Future<List<MoyenPaiement>> moyensPaiement();

  Future<List<CompteMobileMoney>> comptes();

  Future<CompteMobileMoney> ajouterCompte({
    required String moyenPaiementId,
    required String numeroCompte,
    bool estPrincipal,
  });

  Future<void> definirPrincipal(String compteId);
}
