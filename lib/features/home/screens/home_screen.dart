import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../presentation/providers/session_provider.dart';
import '../../auth/screens/phone_input_screen.dart';
import '../tabs/accueil_tab.dart';
import '../tabs/cotisations_tab.dart';
import '../tabs/epargne_tab.dart';
import '../tabs/profil_tab.dart';
import '../tabs/taux_tab.dart';

class HomeScreen extends ConsumerStatefulWidget {
  /// `true` juste après la finalisation de l'inscription : affiche un message
  /// de bienvenue une seule fois, à la première entrée dans l'application.
  final bool afficherBienvenue;

  const HomeScreen({super.key, this.afficherBienvenue = false});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  bool _bienvenueAffichee = false;

  static const _tabs = [
    AccueilTab(),
    TauxTab(),
    CotisationsTab(),
    EpargneTab(),
    ProfilTab(),
  ];

  void _afficherMessageBienvenue() {
    if (_bienvenueAffichee || !widget.afficherBienvenue) return;
    _bienvenueAffichee = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.celebration_rounded,
                color: AppColors.primaryBlue, size: 28),
          ),
          title: const Text(
            'Bienvenue sur Ebeb Finance',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          content: const Text(
            'Votre inscription est enregistrée. Vos documents sont '
            'actuellement en cours de vérification par notre équipe — vous '
            'serez notifié dès que votre compte sera activé.',
            textAlign: TextAlign.center,
            style: TextStyle(height: 1.5),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: ElevatedButton.styleFrom(minimumSize: const Size(140, 46)),
              child: const Text('Compris'),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    _afficherMessageBienvenue();

    // Une session invalidée (déconnexion, jeton expiré) ramène à la connexion.
    ref.listen(sessionProvider, (precedent, courant) {
      if (precedent?.estAuthentifie == true && !courant.estAuthentifie) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const PhoneInputScreen()),
          (route) => false,
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Accueil',
                index: 0,
                current: _currentIndex,
                onTap: () => setState(() => _currentIndex = 0),
              ),
              _NavItem(
                icon: Icons.percent_rounded,
                label: 'Vos taux',
                index: 1,
                current: _currentIndex,
                onTap: () => setState(() => _currentIndex = 1),
              ),
              _NavItem(
                icon: Icons.shield_rounded,
                label: 'Cotisations',
                index: 2,
                current: _currentIndex,
                onTap: () => setState(() => _currentIndex = 2),
              ),
              _NavItem(
                icon: Icons.savings_rounded,
                label: 'Épargne',
                index: 3,
                current: _currentIndex,
                onTap: () => setState(() => _currentIndex = 3),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Profil',
                index: 4,
                current: _currentIndex,
                onTap: () => setState(() => _currentIndex = 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == current;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryBlue.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? AppColors.primaryBlue
                    : AppColors.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected
                    ? AppColors.primaryBlue
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
