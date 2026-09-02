import '../../core/utils/json_utils.dart';

/// Compte identifié après un scan de QR code compatible
/// (`/espace-utilisateur/paiements-qr/identifier`) — uniquement ce qu'il faut
/// pour confirmer le paiement, jamais le compte complet d'un tiers.
class DestinataireQr {
  final String id;
  final String operateur;
  final String numeroMasque;
  final String titulaire;

  const DestinataireQr({
    required this.id,
    required this.operateur,
    required this.numeroMasque,
    required this.titulaire,
  });

  factory DestinataireQr.depuisJson(Map<String, dynamic> json) {
    return DestinataireQr(
      id: Json.texteOu(json, ['uuid', 'id']),
      operateur: Json.texteOu(json, ['operateur'], '—'),
      numeroMasque: Json.texteOu(json, ['numero_masque'], '—'),
      titulaire: Json.texteOu(json, ['titulaire'], '—'),
    );
  }
}
