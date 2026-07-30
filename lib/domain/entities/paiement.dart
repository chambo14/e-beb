import '../../core/utils/json_utils.dart';

/// Ligne de prélèvement appliquée à un paiement encaissé.
class PrelevementPaiement {
  final String libelle;
  final double montant;
  final String? code;

  const PrelevementPaiement({
    required this.libelle,
    required this.montant,
    this.code,
  });

  factory PrelevementPaiement.depuisJson(Map<String, dynamic> json) {
    return PrelevementPaiement(
      libelle: Json.texteOu(json, [
        'libelle',
        'nom',
        'type_cotisation',
        'label',
      ], '—'),
      montant: Json.decimalOu(json, ['montant', 'montant_preleve', 'valeur']),
      code: Json.texte(json, ['code']),
    );
  }
}

/// Paiement reçu d'un client (`/espace-utilisateur/paiements`).
class Paiement {
  final String id;
  final double montantBrut;
  final double montantNet;
  final double montantPreleve;
  final String? description;
  final String? referenceExterne;
  final String? qrCodeRef;
  final String? statut;
  final DateTime date;
  final List<PrelevementPaiement> prelevements;

  const Paiement({
    required this.id,
    required this.montantBrut,
    required this.date,
    this.montantNet = 0,
    this.montantPreleve = 0,
    this.description,
    this.referenceExterne,
    this.qrCodeRef,
    this.statut,
    this.prelevements = const [],
  });

  factory Paiement.depuisJson(Map<String, dynamic> json) {
    final prelevements = Json.objets(json, [
      'prelevements',
      'deductions',
      'cotisations',
      'operations',
    ]).map(PrelevementPaiement.depuisJson).toList(growable: false);

    final brut = Json.decimalOu(json, ['montant_brut', 'montant']);
    final preleve = Json.decimalOu(json, [
      'montant_preleve',
      'total_prelevements',
      'montant_deduit',
    ]);
    final netApi = Json.decimal(json, ['montant_net', 'montant_verse']);

    return Paiement(
      id: Json.texteOu(json, ['id', 'uuid']),
      montantBrut: brut,
      montantPreleve: preleve,
      montantNet: netApi ?? (brut - preleve),
      description: Json.texte(json, ['description', 'libelle', 'motif']),
      referenceExterne: Json.texte(json, ['reference_externe', 'reference']),
      qrCodeRef: Json.texte(json, ['qr_code_ref', 'qr_code']),
      statut: Json.texte(json, ['statut', 'status', 'etat']),
      date:
          Json.date(json, ['date_paiement', 'date', 'created_at']) ??
          DateTime.now(),
      prelevements: prelevements,
    );
  }
}
