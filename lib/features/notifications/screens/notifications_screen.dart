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
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: liste.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    indent: 68,
                    color: AppColors.border,
                  ),
                  itemBuilder: (_, i) => _NotificationTile(
                    notification: liste[i],
                    onTap: () => ref
                        .read(notificationsProvider.notifier)
                        .marquerLue(liste[i].id),
                  ),
                ),
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
      onTap: lue ? null : onTap,
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
