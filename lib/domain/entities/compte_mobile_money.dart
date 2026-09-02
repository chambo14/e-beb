import '../../core/utils/json_utils.dart';

/// Opérateur de paiement (Orange, MTN, Moov, Wave…).
class MoyenPaiement {
  final String id;
  final String libelle;
  final String? code;
  final String? logoUrl;
  final String? operateur;

  /// `true` si ce moyen est celui marqué par défaut en base
  /// (`moyen_paiements.par_defaut`) — sert de présélection à l'inscription.
  final bool parDefaut;

  /// Couleur associée en base (`moyen_paiements.couleur`), format `#RRGGBB`.
  /// `null` si non configurée — jamais déduite du code opérateur côté mobile.
  final String? couleur;

  const MoyenPaiement({
    required this.id,
    required this.libelle,
    this.code,
    this.logoUrl,
    this.parDefaut = false,
    this.operateur,
    this.couleur,
  });

  factory MoyenPaiement.depuisJson(Map<String, dynamic> json) {
    return MoyenPaiement(
      id: Json.texteOu(json, ['id', 'uuid', 'moyen_paiement_id']),
      libelle: Json.texteOu(json, ['libelle', 'nom', 'label'], '—'),
      code: Json.texte(json, ['code']),
      logoUrl: Json.texte(json, ['logo_url', 'logo', 'icone_url']),
      parDefaut: Json.booleen(json, ['par_defaut', 'defaut']),
      operateur: Json.texte(json, ['operateur']),
      couleur: Json.texte(json, ['couleur', 'color']),
    );
  }
}

/// Compte mobile money rattaché à l'utilisateur
/// (`/espace-utilisateur/comptes-mobile-money`).
class CompteMobileMoney {
  final String id;
  final String numeroCompte;
  final bool estPrincipal;
  final MoyenPaiement? moyenPaiement;
  final String? titulaire;
  final DateTime? creeLe;

  /// Contenu du QR code de ce compte, tel que généré et persisté par le
  /// back-end à sa création (`qrcode_paiement.valeur`) — jamais recalculé ou
  /// simulé côté mobile.
  final String? qrPayload;

  const CompteMobileMoney({
    required this.id,
    required this.numeroCompte,
    this.estPrincipal = false,
    this.moyenPaiement,
    this.titulaire,
    this.creeLe,
    this.qrPayload,
  });

  String get operateur =>
      moyenPaiement?.libelle ?? moyenPaiement?.operateur ?? '—';

  factory CompteMobileMoney.depuisJson(Map<String, dynamic> json) {
    final moyenJson = Json.objet(json, ['moyen_paiement', 'operateur']);
    final qrJson = Json.objet(json, ['qrcode', 'qrcode_paiement']);
    return CompteMobileMoney(
      id: Json.texteOu(json, ['id', 'uuid']),
      numeroCompte: Json.texteOu(json, [
        'numero_compte',
        'numero',
        'telephone',
      ]),
      estPrincipal: Json.booleen(json, ['est_principal', 'principal']),
      moyenPaiement: moyenJson == null
          ? null
          : MoyenPaiement.depuisJson(moyenJson),
      titulaire: Json.texte(json, ['titulaire', 'nom_titulaire']),
      creeLe: Json.date(json, ['created_at', 'cree_le']),
      qrPayload: qrJson == null ? null : Json.texte(qrJson, ['valeur']),
    );
  }
}
