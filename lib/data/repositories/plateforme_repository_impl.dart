import '../../domain/entities/infos_plateforme.dart';
import '../../domain/repositories/plateforme_repository.dart';
import '../datasources/plateforme_remote_datasource.dart';

class PlateformeRepositoryImpl implements PlateformeRepository {
  final PlateformeRemoteDataSource _remote;

  const PlateformeRepositoryImpl(this._remote);

  @override
  Future<InfosPlateforme> infos() async {
    final reponse = await _remote.infos();
    return InfosPlateforme.depuisJson(reponse.donnees);
  }
}
