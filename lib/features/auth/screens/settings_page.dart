import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../presentation/providers/auth_controller.dart';
import '../../../presentation/providers/notification_providers.dart';
import '../../../presentation/providers/session_provider.dart';
import '../../home/screens/comptes_mobile_money_screen.dart';
import '../../home/screens/page_contenu_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import 'profil_edit_sheet.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  void _profilVerrouille(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Vos documents sont en cours de vérification. '
          'Cette action sera disponible une fois votre compte activé.',
        ),
        backgroundColor: AppColors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10))),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nonLues = ref.watch(nombreNotificationsNonLuesProvider);
    final compteActif = ref.watch(utilisateurCourantProvider)?.estActif ?? true;

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
                subtitle: compteActif
                    ? 'Email, adresse, situation familiale'
                    : 'Vérification des documents en cours',
                verrouille: !compteActif,
                onTap: compteActif
                    ? () => showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                          builder: (_) => const ProfilEditSheet(),
                        )
                    : () => _profilVerrouille(context),
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Comptes',
                subtitle: 'Comptes mobile money associés',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ComptesMobileMoneyScreen(),
                  ),
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
                // l'état de session et remplace toute la pile de navigation
                // (pushAndRemoveUntil) dès qu'elle passe à non-authentifié.
                // Ne PAS dépiler ici en plus : selon l'ordre d'exécution, ce
                // pop peut arriver après que la pile a déjà été remplacée par
                // le seul écran de connexion, et planter en tentant de
                // dépiler la dernière route restante.
                onTap: () => ref
                    .read(authControllerProvider.notifier)
                    .seDeconnecter(),
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
                        _buildFooterLink(
                          context,
                          'Conditions Générales',
                          type: 'CGU',
                        ),
                        Text(' • ', style: TextStyle(color: Colors.grey.shade400)),
                        _buildFooterLink(
                          context,
                          'Avis de Confidentialité',
                          type: 'POLITIQUE_CONFIDENTIALITE',
                        ),
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
    bool verrouille = false,
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
              color: verrouille
                  ? AppColors.textHint
                  : (iconColor ?? AppColors.textSecondary),
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
                      color: verrouille
                          ? AppColors.textHint
                          : (titleColor ?? AppColors.textPrimary),
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
            if (verrouille)
              const Icon(Icons.lock_outline_rounded,
                  color: AppColors.textHint, size: 18),
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
  Widget _buildFooterLink(BuildContext context, String text, {required String type}) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PageContenuScreen(type: type, titreEcran: text),
        ),
      ),
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