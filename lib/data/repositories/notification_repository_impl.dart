import '../../domain/entities/notification_app.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource _remote;

  const NotificationRepositoryImpl(this._remote);

  @override
  Future<List<NotificationApp>> toutes() async {
    final reponse = await _remote.toutes();
    return _trier(reponse.liste);
  }

  @override
  Future<List<NotificationApp>> nonLues() async {
    final reponse = await _remote.nonLues();
    return _trier(reponse.liste);
  }

  @override
  Future<void> marquerLue(String id) => _remote.marquerLue(id);

  @override
  Future<void> marquerToutesLues() => _remote.marquerToutesLues();

  List<NotificationApp> _trier(List<Map<String, dynamic>> brut) {
    final notifications = brut
        .map(NotificationApp.depuisJson)
        .toList(growable: false);
    return notifications.toList()..sort((a, b) => b.date.compareTo(a.date));
  }
}
