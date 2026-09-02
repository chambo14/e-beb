/// Contrat du support utilisateur.
abstract class SupportRepository {
  /// Signale un problème ; renvoie le message de confirmation du back-end.
  Future<String> signaler(String description);
}
