import '../../domain/entities/type_cotisation.dart';
import '../../domain/repositories/cotisation_repository.dart';
import '../datasources/cotisation_remote_datasource.dart';

class CotisationRepositoryImpl implements CotisationRepository {
  final CotisationRemoteDataSource _remote;

  /// Catégorie imposée par le back-end pour les cotisations créées par
  /// l'utilisateur.
  static const _categoriePersonnalisee = 'COTISATION PERSONNALISE';

  const CotisationRepositoryImpl(this._remote);

  @override
  Future<List<TypeCotisation>> typesDisponibles() async {
    final reponse = await _remote.types();
    return reponse.liste.map(TypeCotisation.depuisJson).toList(growable: false);
  }

  @override
  Future<String> configurerRegle({
    required String typeCotisationId,
    required TypeCalcul typeCalcul,
    required double valeur,
    required bool estActif,
  }) async {
    final reponse = await _remote.configurerRegle(
      typeCotisationId: typeCotisationId,
      typeCalcul: typeCalcul.code,
      valeur: valeur,
      estActif: estActif,
    );
    return reponse.message ?? 'Règle de prélèvement enregistrée.';
  }

  @override
  Future<TypeCotisation> ajouterTypePersonnalise({
    required String libelle,
    required String code,
    required double montantPaiementMensuel,
    String? description,
    String? categorie,
  }) async {
    final reponse = await _remote.ajouterTypePersonnalise(
      _corpsTypePersonnalise(
        libelle: libelle,
        code: code,
        montantPaiementMensuel: montantPaiementMensuel,
        description: description,
        categorie: categorie,
      ),
    );
    return TypeCotisation.depuisJson(reponse.donnees);
  }

  @override
  Future<TypeCotisation> modifierTypePersonnalise({
    required String id,
    required String libelle,
    required String code,
    required double montantPaiementMensuel,
    String? description,
  }) async {
    final reponse = await _remote.modifierTypePersonnalise(
      id,
      _corpsTypePersonnalise(
        libelle: libelle,
        code: code,
        montantPaiementMensuel: montantPaiementMensuel,
        description: description,
      ),
    );
    return TypeCotisation.depuisJson(reponse.donnees);
  }

  @override
  Future<void> supprimerTypePersonnalise(String id) =>
      _remote.supprimerTypePersonnalise(id);

  Map<String, dynamic> _corpsTypePersonnalise({
    required String libelle,
    required String code,
    required double montantPaiementMensuel,
    String? description,
    String? categorie,
  }) => {
    'libelle': libelle,
    'code': code,
    'categorie': (categorie == null || categorie.trim().isEmpty)
        ? _categoriePersonnalisee
        : categorie.trim(),
    'description': description ?? libelle,
    'montant_paiement_mensuel': montantPaiementMensuel.round(),
  };
}
