import '../entities/type_cotisation.dart';

/// Contrat des règles de prélèvement et des cotisations personnalisées.
abstract class CotisationRepository {
  /// Types de cotisation disponibles, règles utilisateur incluses.
  Future<List<TypeCotisation>> typesDisponibles();

  /// Crée ou met à jour la règle de prélèvement d'un type de cotisation.
  Future<String> configurerRegle({
    required String typeCotisationId,
    required TypeCalcul typeCalcul,
    required double valeur,
    required bool estActif,
  });

  Future<TypeCotisation> ajouterTypePersonnalise({
    required String libelle,
    required String code,
    required double montantPaiementMensuel,
    String? description,
    String? categorie,
  });

  Future<TypeCotisation> modifierTypePersonnalise({
    required String id,
    required String libelle,
    required String code,
    required double montantPaiementMensuel,
    String? description,
  });

  Future<void> supprimerTypePersonnalise(String id);
}
