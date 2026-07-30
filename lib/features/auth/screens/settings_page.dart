import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../presentation/providers/auth_controller.dart';
import '../../../presentation/providers/notification_providers.dart';
import '../../notifications/screens/notifications_screen.dart';
import 'profil_edit_sheet.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nonLues = ref.watch(nombreNotificationsNonLuesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Paramètres',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Section Générale ──────────────────────────────────────────
              _buildSectionTitle('Général'),
              const SizedBox(height: 12),
              _buildSettingItem(
                icon: Icons.person_outline_rounded,
                title: 'Modifier mes informations',
                subtitle: 'Email, adresse, situation familiale',
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  builder: (_) => const ProfilEditSheet(),
                ),
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                trailingText: nonLues > 0 ? '$nonLues non lues' : null,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ─── Section Sécurité & Support ────────────────────────────────
              _buildSectionTitle('Sécurité & Support'),
              const SizedBox(height: 12),
              _buildSettingItem(
                icon: Icons.lock_outline_rounded,
                title: 'Modifiez votre code secret',
                subtitle: 'Code PIN à 6 chiffres',
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  builder: (_) => const CodePinEditSheet(),
                ),
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.help_outline_rounded,
                title: "Support",
                subtitle: "Contactez le service d'aide utilisateur",
                onTap: () {
                  // Ouverture du canal de support
                },
              ),

              const SizedBox(height: 40),

              // ─── Déconnexion ──────────────────────────────────────────────
              _buildSettingItem(
                icon: Icons.logout_rounded,
                title: 'Se déconnecter',
                titleColor: Colors.orange.shade800,
                iconColor: Colors.orange.shade800,
                showTrailing: false,
                // La redirection est prise en charge par HomeScreen, qui écoute
                // l'état de session.
                onTap: () async {
                  await ref
                      .read(authControllerProvider.notifier)
                      .seDeconnecter();
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),

              const SizedBox(height: 48),

              // ─── Pied de page (Version & Mentions Légales) ─────────────────
              Center(
                child: Column(
                  children: [
                    Text(
                      'Version 25:05:06-2448c6',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildFooterLink('Conditions Générales'),
                        Text(' • ', style: TextStyle(color: Colors.grey.shade400)),
                        _buildFooterLink('Avis de Confidentialité'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget utilitaire pour les titres de section
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }

  // Séparateur fin discret entre les options du menu
  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 0.8,
      color: AppColors.border,
    );
  }

  // Composant générique pour chaque ligne de paramètre
  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    String? trailingText,
    Color? titleColor,
    Color? iconColor,
    bool showTrailing = true,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor ?? AppColors.textSecondary,
              size: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailingText != null)
              Text(
                trailingText,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (showTrailing) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Lien cliquable pour le pied de page
  Widget _buildFooterLink(String text) {
    return GestureDetector(
      onTap: () {
        // Redirection vers la vue web ou document légal associé
      },
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}