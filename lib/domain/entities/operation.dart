import '../../core/utils/json_utils.dart';

/// Sens d'une opération sur le compte.
enum SensOperation {
  credit('CREDIT'),
  debit('DEBIT');

  final String code;
  const SensOperation(this.code);

  static SensOperation depuisJson(Map<String, dynamic> json) {
    final sens = Json.texte(json, ['sens', 'direction'])?.toUpperCase();
    if (sens != null) {
      if (sens.startsWith('CRED') || sens == 'ENTREE' || sens == 'IN') {
        return SensOperation.credit;
      }
      if (sens.startsWith('DEB') || sens == 'SORTIE' || sens == 'OUT') {
        return SensOperation.debit;
      }
    }
    // Repli : un prélèvement / une déduction est toujours un débit.
    final type = Json.texte(json, ['type', 'type_operation'])?.toUpperCase();
    if (type != null &&
        (type.contains('PRELEV') ||
            type.contains('DEDUC') ||
            type.contains('COTISATION') ||
            type.contains('EPARGNE') ||
            type.contains('RETRAIT') ||
            type.contains('VIREMENT'))) {
      return SensOperation.debit;
    }
    return SensOperation.credit;
  }
}

/// Mouvement du compte (`/espace-utilisateur/operations`).
class Operation {
  final String id;
  final String libelle;
  final String? description;
  final double montant;
  final SensOperation sens;
  final String? type;
  final String? statut;
  final String? reference;
  final DateTime date;

  const Operation({
    required this.id,
    required this.libelle,
    required this.montant,
    required this.sens,
    required this.date,
    this.description,
    this.type,
    this.statut,
    this.reference,
  });

  bool get estCredit => sens == SensOperation.credit;

  factory Operation.depuisJson(Map<String, dynamic> json) {
    return Operation(
      id: Json.texteOu(json, ['id', 'uuid', 'reference']),
      libelle: Json.texteOu(json, [
        'libelle',
        'label',
        'intitule',
        'type_libelle',
        'type',
      ], 'Opération'),
      description: Json.texte(json, ['description', 'motif', 'commentaire']),
      montant: Json.decimalOu(json, ['montant', 'montant_net', 'montant_brut']),
      sens: SensOperation.depuisJson(json),
      type: Json.texte(json, ['type', 'type_operation']),
      statut: Json.texte(json, ['statut', 'status', 'etat']),
      reference: Json.texte(json, ['reference', 'reference_externe']),
      date:
          Json.date(json, [
            'date_operation',
            'date',
            'created_at',
            'effectue_le',
          ]) ??
          DateTime.now(),
    );
  }
}

/// Filtres acceptés par `GET /espace-utilisateur/operations`.
class FiltreOperations {
  final List<String> types;
  final String? type;
  final String? sens;
  final int? mois;
  final int? annee;
  final DateTime? dateDebut;
  final DateTime? dateFin;

  const FiltreOperations({
    this.types = const [],
    this.type,
    this.sens,
    this.mois,
    this.annee,
    this.dateDebut,
    this.dateFin,
  });

  static const aucun = FiltreOperations();

  bool get estVide =>
      types.isEmpty &&
      type == null &&
      sens == null &&
      mois == null &&
      annee == null &&
      dateDebut == null &&
      dateFin == null;

  Map<String, dynamic> versJson() => {
    'types': types,
    'type': type ?? '',
    'sens': sens ?? '',
    'mois': mois?.toString() ?? '',
    'annee': annee?.toString() ?? '',
    'date_debut': dateDebut == null ? '' : _iso(dateDebut!),
    'date_fin': dateFin == null ? '' : _iso(dateFin!),
  };

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
