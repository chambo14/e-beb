import '../entities/notification_app.dart';

/// Contrat des notifications de l'espace utilisateur.
abstract class NotificationRepository {
  Future<List<NotificationApp>> toutes();

  Future<List<NotificationApp>> nonLues();

  Future<void> marquerLue(String id);

  Future<void> marquerToutesLues();
}
