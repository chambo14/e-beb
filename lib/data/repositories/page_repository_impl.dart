import '../../domain/entities/page_contenu.dart';
import '../../domain/repositories/page_repository.dart';
import '../datasources/page_remote_datasource.dart';

class PageRepositoryImpl implements PageRepository {
  final PageRemoteDataSource _remote;

  const PageRepositoryImpl(this._remote);

  @override
  Future<PageContenu?> parType(String type) async {
    final donnees = (await _remote.parType(type)).donnees;
    if (donnees.isEmpty) return null;
    return PageContenu.depuisJson(donnees);
  }
}
