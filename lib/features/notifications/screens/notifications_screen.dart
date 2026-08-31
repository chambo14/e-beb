import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/notification_app.dart';
import '../../../presentation/providers/notification_providers.dart';

/// Liste des notifications de l'espace utilisateur.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final nonLues = ref.watch(nombreNotificationsNonLuesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          if (nonLues > 0)
            TextButton(
              onPressed: () =>
                  ref.read(notificationsProvider.notifier).marquerToutesLues(),
              child: const Text('Tout marquer lu'),
            ),
        ],
      ),
      body: notifications.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (erreur, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded,
                    color: AppColors.error, size: 34),
                const SizedBox(height: 12),
                Text(
                  erreur is ApiException
                      ? erreur.message
                      : 'Impossible de charger vos notifications.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.5),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(notificationsProvider.notifier).recharger(),
                  style:
                      ElevatedButton.styleFrom(minimumSize: const Size(160, 44)),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (liste) => RefreshIndicator(
          onRefresh: () => ref.read(notificationsProvider.notifier).recharger(),
          child: liste.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 120),
                    Icon(Icons.notifications_none_rounded,
                        color: AppColors.textHint, size: 40),
                    SizedBox(height: 12),
                    Text(
                      'Aucune notification',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  itemCount: liste.length + 1,
                  separatorBuilder: (_, i) => i == 0
                      ? const SizedBox.shrink()
                      : const Divider(
                          height: 1,
                          indent: 68,
                          color: AppColors.border,
                        ),
                  itemBuilder: (_, i) {
                    if (i == 0) return _EnTeteNonLues(nombre: nonLues);
                    final notif = liste[i - 1];
                    return _NotificationTile(
                      notification: notif,
                      onTap: () => _ouvrirDetail(context, ref, notif),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Future<void> _ouvrirDetail(
    BuildContext context,
    WidgetRef ref,
    NotificationApp notification,
  ) async {
    if (!notification.estLue) {
      await ref.read(notificationsProvider.notifier).marquerLue(notification.id);
    }
    if (!context.mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _DetailNotificationSheet(notification: notification),
    );
  }
}

/// Compteur de notifications non lues, toujours visible en tête de liste.
class _EnTeteNonLues extends StatelessWidget {
  final int nombre;
  const _EnTeteNonLues({required this.nombre});

  @override
  Widget build(BuildContext context) {
    final aDesNonLues = nombre > 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: aDesNonLues
              ? AppColors.primaryBlue.withValues(alpha: 0.08)
              : AppColors.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              aDesNonLues
                  ? Icons.mark_email_unread_rounded
                  : Icons.mark_email_read_rounded,
              size: 18,
              color: aDesNonLues ? AppColors.primaryBlue : AppColors.success,
            ),
            const SizedBox(width: 10),
            Text(
              aDesNonLues
                  ? '$nombre notification${nombre > 1 ? 's' : ''} non lue${nombre > 1 ? 's' : ''}'
                  : 'Toutes les notifications sont lues',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: aDesNonLues ? AppColors.primaryBlue : AppColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationApp notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final lue = notification.estLue;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: lue ? null : AppColors.primaryBlue.withValues(alpha: 0.04),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBlue.withValues(alpha: 0.10),
              ),
              child: Icon(
                lue
                    ? Icons.notifications_none_rounded
                    : Icons.notifications_active_rounded,
                color: AppColors.primaryBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.titre,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: lue ? FontWeight.w600 : FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (notification.message.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      notification.message,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    Formatters.dateHeure(notification.date),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textHint),
                  ),
                ],
              ),
            ),
            if (!lue)
              Container(
                margin: const EdgeInsets.only(top: 6, left: 8),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryBlue,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Contenu complet d'une notification : titre, message intégral et date/
/// heure précise de réception.
class _DetailNotificationSheet extends StatelessWidget {
  final NotificationApp notification;

  const _DetailNotificationSheet({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryBlue.withValues(alpha: 0.10),
                ),
                child: const Icon(
                  Icons.notifications_rounded,
                  color: AppColors.primaryBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  notification.titre,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.schedule_rounded,
                  size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Reçue le ${Formatters.dateHeure(notification.date)}',
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.textSecondary),
              ),
            ],
          ),
          if (notification.type != null && notification.type!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.border.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                notification.type!,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary),
              ),
            ),
          ],
          if (notification.message.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 18),
            Text(
              notification.message,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.6,
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
