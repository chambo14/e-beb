import '../../core/utils/formatters.dart';
import '../../domain/entities/objectif_epargne.dart';
import '../../domain/entities/type_cotisation.dart';
import '../../domain/repositories/epargne_repository.dart';
import '../datasources/epargne_remote_datasource.dart';

class EpargneRepositoryImpl implements EpargneRepository {
  final EpargneRemoteDataSource _remote;

  const EpargneRepositoryImpl(this._remote);

  @override
  Future<List<ObjectifEpargne>> objectifs() async {
    // Le back-end ne modélise qu'un seul objectif actif par utilisateur —
    // `GET /objectif-epargne` renvoie directement cet objet (ou `null`), pas
    // une liste. `reponse.liste` ne sait déballer un objet unique en liste
    // que via une clé wrapper à valeur `List`, absente ici (l'objet a de
    // nombreuses clés à plat) : elle renverrait toujours `[]`, y compris
    // quand un objectif existe réellement.
    final donnees = (await _remote.objectifs()).donnees;
    if (donnees.isEmpty) return const [];
    return [ObjectifEpargne.depuisJson(donnees)];
  }

  @override
  Future<ObjectifEpargne> ajouter({
    required String libelle,
    required double montantCible,
    required DateTime dateLimite,
    required TypeCalcul typeCalcul,
    required double valeur,
    double montantEpargne = 0,
    bool estActif = true,
  }) async {
    final reponse = await _remote.ajouter(
      _champs(
        libelle: libelle,
        montantCible: montantCible,
        dateLimite: dateLimite,
        typeCalcul: typeCalcul,
        valeur: valeur,
        montantEpargne: montantEpargne,
        estActif: estActif,
      ),
    );
    return ObjectifEpargne.depuisJson(reponse.donnees);
  }

  @override
  Future<ObjectifEpargne> modifier({
    required String id,
    required String libelle,
    required double montantCible,
    required DateTime dateLimite,
    required TypeCalcul typeCalcul,
    required double valeur,
    double? montantEpargne,
    bool? estActif,
  }) async {
    final reponse = await _remote.modifier(
      id,
      _champs(
        libelle: libelle,
        montantCible: montantCible,
        dateLimite: dateLimite,
        typeCalcul: typeCalcul,
        valeur: valeur,
        montantEpargne: montantEpargne,
        estActif: estActif,
      ),
    );
    return ObjectifEpargne.depuisJson(reponse.donnees);
  }

  @override
  Future<void> supprimer(String id) => _remote.supprimer(id);

  Map<String, dynamic> _champs({
    required String libelle,
    required double montantCible,
    required DateTime dateLimite,
    required TypeCalcul typeCalcul,
    required double valeur,
    double? montantEpargne,
    bool? estActif,
  }) => {
    'libelle': libelle,
    'montant_cible': montantCible.round().toString(),
    'date_limite': Formatters.dateApi(dateLimite),
    'type_calcul': typeCalcul.code,
    'valeur': valeur.round().toString(),
    'montant_epargne': montantEpargne?.round().toString(),
    'est_actif': estActif == null ? null : (estActif ? '1' : '0'),
  };
}
