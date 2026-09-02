import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../domain/entities/notification_app.dart';
import 'repository_providers.dart';
import 'session_provider.dart';

/// ViewModel des notifications.
///
/// Le marquage « lu » est appliqué localement d'abord (optimiste) puis
/// resynchronisé, pour que le badge disparaisse sans attendre le réseau.
class NotificationsController extends AsyncNotifier<List<NotificationApp>> {
  @override
  Future<List<NotificationApp>> build() async {
    final session = ref.watch(sessionProvider);
    if (!session.estAuthentifie) return const [];
    return ref.watch(notificationRepositoryProvider).toutes();
  }

  Future<void> recharger() async {
    state = await AsyncValue.guard(
      () => ref.read(notificationRepositoryProvider).toutes(),
    );
  }

  Future<bool> marquerLue(String id) async {
    final precedent = state.valueOrNull ?? const <NotificationApp>[];
    state = AsyncData([
      for (final n in precedent) if (n.id == id) n.marquerLue() else n,
    ]);
    try {
      await ref.read(notificationRepositoryProvider).marquerLue(id);
      return true;
    } on ApiException {
      state = AsyncData(precedent);
      return false;
    }
  }

  Future<bool> marquerToutesLues() async {
    final precedent = state.valueOrNull ?? const <NotificationApp>[];
    state = AsyncData([for (final n in precedent) n.marquerLue()]);
    try {
      await ref.read(notificationRepositoryProvider).marquerToutesLues();
      return true;
    } on ApiException {
      state = AsyncData(precedent);
      return false;
    }
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsController, List<NotificationApp>>(
      NotificationsController.new,
    );

/// Nombre de notifications non lues — alimente le badge de la barre du haut.
final nombreNotificationsNonLuesProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider).valueOrNull;
  if (notifications == null) return 0;
  return notifications.where((n) => !n.estLue).length;
});
