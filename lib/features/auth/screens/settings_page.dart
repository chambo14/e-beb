import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                icon: Icons.share_outlined,
                title: 'Inviter un ami à rejoindre Ebeb',
                onTap: () {
                  // Logique de partage d'invitation
                },
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.percent_rounded,
                title: 'Vos taux',
                onTap: () {
                  // Redirection vers la configuration des taux
                },
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.location_on_outlined,
                title: 'Trouvez les agents à proximité',
                onTap: () {
                  // Logique de géolocalisation des agents
                },
              ),

              const SizedBox(height: 32),

              // ─── Section Sécurité & Support ────────────────────────────────
              _buildSectionTitle('Sécurité & Support'),
              const SizedBox(height: 12),
              _buildSettingItem(
                icon: Icons.help_outline_rounded,
                title: "Support",
                subtitle: "Contactez le service d'aide utilisateur",
                onTap: () {
                  // Ouverture du canal de support
                },
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.devices_rounded,
                title: 'Vos appareils connectés',
                trailingText: '1 appareil', // Issu du document d'analyse
                onTap: () {
                  // Gestion des sessions / appareils connectés
                },
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.lock_outline_rounded,
                title: 'Modifiez votre code secret',
                onTap: () {
                  // Changement de code secret PIN
                },
              ),

              const SizedBox(height: 40),

              // ─── Boutons d'action de déconnexion / Clôture ────────────────
              _buildSettingItem(
                icon: Icons.logout_rounded,
                title: 'Se déconnecter',
                titleColor: Colors.orange.shade800,
                iconColor: Colors.orange.shade800,
                showTrailing: false,
                onTap: () {
                  // Code de déconnexion de la session
                },
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.delete_forever_outlined,
                title: 'Fermer mon compte Ebeb',
                titleColor: Colors.red.shade700,
                iconColor: Colors.red.shade700,
                showTrailing: false,
                onTap: () {
                  // Procédure de suppression du compte utilisateur
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