import '../../core/utils/json_utils.dart';
import 'type_cotisation.dart';

/// Objectif d'épargne de l'utilisateur
/// (`/espace-utilisateur/objectif-epargne`).
class ObjectifEpargne {
  final String id;
  final String libelle;
  final double montantCible;
  final double montantEpargne;
  final DateTime? dateLimite;
  final TypeCalcul typeCalcul;
  final double valeur;
  final bool estActif;

  const ObjectifEpargne({
    required this.id,
    required this.libelle,
    required this.montantCible,
    this.montantEpargne = 0,
    this.dateLimite,
    this.typeCalcul = TypeCalcul.fixe,
    this.valeur = 0,
    this.estActif = true,
  });

  double get progression =>
      montantCible <= 0 ? 0 : (montantEpargne / montantCible).clamp(0.0, 1.0);

  double get reste =>
      (montantCible - montantEpargne).clamp(0, double.infinity).toDouble();

  bool get estAtteint => montantEpargne >= montantCible && montantCible > 0;

  /// Nombre de jours restants ; négatif si la date limite est dépassée.
  int? get joursRestants {
    final limite = dateLimite;
    if (limite == null) return null;
    return limite.difference(DateTime.now()).inDays;
  }

  factory ObjectifEpargne.depuisJson(Map<String, dynamic> json) {
    return ObjectifEpargne(
      id: Json.texteOu(json, ['id', 'uuid']),
      libelle: Json.texteOu(json, ['libelle', 'nom', 'label'], '—'),
      montantCible: Json.decimalOu(json, ['montant_cible', 'objectif']),
      montantEpargne: Json.decimalOu(json, [
        'montant_epargne',
        'montant_actuel',
        'montant_atteint',
      ]),
      dateLimite: Json.date(json, ['date_limite', 'echeance']),
      typeCalcul: TypeCalcul.depuisCode(Json.texte(json, ['type_calcul'])),
      valeur: Json.decimalOu(json, ['valeur', 'value']),
      estActif: Json.booleen(json, ['est_actif', 'actif'], defaut: true),
    );
  }
}
