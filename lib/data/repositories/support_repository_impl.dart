import '../../domain/repositories/support_repository.dart';
import '../datasources/support_remote_datasource.dart';

class SupportRepositoryImpl implements SupportRepository {
  final SupportRemoteDataSource _remote;

  const SupportRepositoryImpl(this._remote);

  @override
  Future<String> signaler(String description) async {
    final reponse = await _remote.signaler(description);
    return reponse.message ?? 'Votre signalement a été transmis.';
  }
}
