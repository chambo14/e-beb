import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/utilisateur.dart';
import '../../../presentation/providers/auth_controller.dart';
import '../../../presentation/providers/session_provider.dart';
import '../../auth/screens/settings_page.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../support/screens/support_screen.dart';

class ProfilTab extends ConsumerWidget {
  const ProfilTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final utilisateur = ref.watch(utilisateurCourantProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Mon profil',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: AppColors.primaryBlue, size: 22),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
      ),
      body: utilisateur == null
          ? _buildChargement(ref)
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(sessionProvider.notifier).rafraichirUtilisateur(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  children: [
                    _buildProfileHeader(utilisateur),
                    const SizedBox(height: 24),
                    _buildCardInfo(utilisateur),
                    const SizedBox(height: 20),
                    _buildInfoSection(utilisateur),
                    const SizedBox(height: 20),
                    _buildMenuSection(context),
                    const SizedBox(height: 24),
                    _buildLogoutButton(context, ref),
                    const SizedBox(height: 8),
                    const Text(
                      'Ebeb Finance v1.0.0\n© 2026 Agnero\'s Engineering',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textHint, fontSize: 11),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  /// Le profil n'est pas encore chargé (démarrage, ou rechargement après 401).
  Widget _buildChargement(WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text(
            'Chargement de votre profil…',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () =>
                ref.read(sessionProvider.notifier).rafraichirUtilisateur(),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(Utilisateur user) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.primaryBlue, AppColors.purple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                user.initiales,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            user.nomComplet,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.telephone,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          if (user.typeCarte != null || user.statut != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryBlue, AppColors.purple],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                user.typeCarte != null
                    ? 'Carte ${user.typeCarte}'
                    : user.statut!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardInfo(Utilisateur user) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryBlue, Color(0xFF3D2C9E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.credit_card_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Matricule Ebeb',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  user.matricule ?? 'En cours d\'attribution',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(Utilisateur user) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.badge_outlined,
            label: 'N° CNPS',
            value: user.numeroCnps ?? 'Non renseigné',
          ),
          const Divider(height: 1, indent: 56, color: AppColors.border),
          _InfoRow(
            icon: Icons.local_hospital_outlined,
            label: 'N° CMU',
            value: user.numeroCmu ?? 'Non renseigné',
          ),
          const Divider(height: 1, indent: 56, color: AppColors.border),
          _InfoRow(
            icon: Icons.phone_outlined,
            label: 'Téléphone',
            value: user.telephone,
          ),
          const Divider(height: 1, indent: 56, color: AppColors.border),
          _InfoRow(
            icon: Icons.mail_outline_rounded,
            label: 'Email',
            value: user.email ?? 'Non renseigné',
          ),
          const Divider(height: 1, indent: 56, color: AppColors.border),
          _InfoRow(
            icon: Icons.work_outline_rounded,
            label: 'Métier',
            value: user.metier ?? user.profession ?? 'Non renseigné',
          ),
          const Divider(height: 1, indent: 56, color: AppColors.border),
          _InfoRow(
            icon: Icons.place_outlined,
            label: 'Résidence',
            value: [user.quartier, user.ville]
                    .where((e) => e != null && e.isNotEmpty)
                    .join(', ')
                    .ifEmpty('Non renseignée'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _MenuItem(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          const Divider(height: 1, indent: 56, color: AppColors.border),
          _MenuItem(
            icon: Icons.security_outlined,
            label: 'Sécurité',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
          const Divider(height: 1, indent: 56, color: AppColors.border),
          _MenuItem(
            icon: Icons.help_outline_rounded,
            label: 'Aide & Support',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SupportScreen()),
            ),
          ),
          const Divider(height: 1, indent: 56, color: AppColors.border),
          _MenuItem(
            icon: Icons.description_outlined,
            label: 'Conditions d\'utilisation',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return TextButton.icon(
      onPressed: () => _showLogoutDialog(context, ref),
      icon: const Icon(Icons.logout_rounded, color: AppColors.red, size: 20),
      label: const Text(
        'Se déconnecter',
        style: TextStyle(
          color: AppColors.red,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Déconnexion',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir vous déconnecter de votre compte Ebeb Finance ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            // La redirection est pilotée par le `ref.listen` de HomeScreen :
            // il suffit d'invalider la session.
            onPressed: () {
              Navigator.pop(dialogContext);
              ref.read(authControllerProvider.notifier).seDeconnecter();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Déconnecter',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryBlue, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryBlue, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

extension _TexteParDefaut on String {
  /// Renvoie [defaut] quand la chaîne assemblée est vide.
  String ifEmpty(String defaut) => isEmpty ? defaut : this;
}
