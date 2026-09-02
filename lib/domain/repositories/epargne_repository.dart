import '../entities/objectif_epargne.dart';
import '../entities/type_cotisation.dart';

/// Contrat de gestion des objectifs d'épargne.
abstract class EpargneRepository {
  Future<List<ObjectifEpargne>> objectifs();

  Future<ObjectifEpargne> ajouter({
    required String libelle,
    required double montantCible,
    required DateTime dateLimite,
    required TypeCalcul typeCalcul,
    required double valeur,
    double montantEpargne,
    bool estActif,
  });

  Future<ObjectifEpargne> modifier({
    required String id,
    required String libelle,
    required double montantCible,
    required DateTime dateLimite,
    required TypeCalcul typeCalcul,
    required double valeur,
    double? montantEpargne,
    bool? estActif,
  });

  Future<void> supprimer(String id);
}
