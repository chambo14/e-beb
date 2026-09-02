import '../entities/destinataire_qr.dart';

/// Contrat du transfert par QR code (compte à compte, même opérateur).
///
/// Statut SIMULE pour l'instant : aucune API opérateur (MTN/Wave/Orange/Moov)
/// n'est encore intégrée — voir `TransfertQrService` côté back-end.
abstract class TransfertQrRepository {
  /// Décode le contenu scanné et identifie le compte destinataire, sans rien
  /// enregistrer. Lève une [ApiException] (message affichable tel quel,
  /// ex. incompatibilité d'opérateur, QR invalide/inactif) en cas d'échec.
  Future<DestinataireQr> identifierDestinataire({
    required String compteSourceId,
    required String qrScanne,
  });

  /// Envoie le transfert de test. Lève une [ApiException] en cas d'échec.
  Future<void> envoyer({
    required String compteSourceId,
    required String qrScanne,
    required double montant,
  });
}
