import '../../core/utils/json_utils.dart';

/// Opérateur de paiement (Orange, MTN, Moov, Wave…).
class MoyenPaiement {
  final String id;
  final String libelle;
  final String? code;
  final String? logoUrl;

  const MoyenPaiement({
    required this.id,
    required this.libelle,
    this.code,
    this.logoUrl,
  });

  factory MoyenPaiement.depuisJson(Map<String, dynamic> json) {
    return MoyenPaiement(
      id: Json.texteOu(json, ['id', 'uuid', 'moyen_paiement_id']),
      libelle: Json.texteOu(json, ['libelle', 'nom', 'label'], '—'),
      code: Json.texte(json, ['code']),
      logoUrl: Json.texte(json, ['logo_url', 'logo', 'icone_url']),
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

  const CompteMobileMoney({
    required this.id,
    required this.numeroCompte,
    this.estPrincipal = false,
    this.moyenPaiement,
    this.titulaire,
    this.creeLe,
  });

  String get operateur => moyenPaiement?.libelle ?? 'Mobile Money';

  factory CompteMobileMoney.depuisJson(Map<String, dynamic> json) {
    final moyenJson = Json.objet(json, ['moyen_paiement', 'operateur']);
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
    );
  }
}
