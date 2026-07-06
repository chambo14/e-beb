import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../auth/screens/landing_screen.dart';

// ─── Données des slides ───────────────────────────────────────────────────────

class _SlideData {
  final IconData icon;
  final Color iconBg;
  final String titleAccent;
  final String titleRest;
  final String description;
  final String tagline;

  const _SlideData({
    required this.icon,
    required this.iconBg,
    required this.titleAccent,
    required this.titleRest,
    required this.description,
    required this.tagline,
  });
}

const _slides = [
  _SlideData(
    icon: Icons.account_balance_wallet_rounded,
    iconBg: Color(0xFF7C3AED),
    titleAccent: 'Épargner',
    titleRest: 'Sans y Penser',
    description:
        'Activez votre portefeuille de cotisation automatique et laissez notre système mettre de côté pour vous, régulièrement et sans effort.',
    tagline: 'Construisez votre avenir.',
  ),
  _SlideData(
    icon: Icons.credit_card_rounded,
    iconBg: Color(0xFF1B4DB7),
    titleAccent: 'Payer, Rétirer',
    titleRest: 'Partout',
    description:
        'Profitez de paiements et rechargements simplifiés grâce à votre carte physique ou virtuelle, ou juste par scan de votre QR code.',
    tagline: 'Rapide, pratique, sans tracas.',
  ),
  _SlideData(
    icon: Icons.shield_rounded,
    iconBg: Color(0xFF065F46),
    titleAccent: 'Sécuriser',
    titleRest: 'Vos Finances',
    description:
        'Utilisez une plateforme fiable, performante et protégée par les dernières technologies de sécurité pour vos différentes transactions.',
    tagline: 'Vos finances entre de bonnes mains.',
  ),
];

// ─── Écran principal ──────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _goToLanding();
    }
  }

  void _goToLanding() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LandingScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (_, i) => _OnboardingSlide(slide: _slides[i]),
            ),
          ),
          _BottomBar(
            currentPage: _currentPage,
            total: _slides.length,
            isLast: _currentPage == _slides.length - 1,
            onSkip: _goToLanding,
            onNext: _next,
          ),
        ],
      ),
    );
  }
}

// ─── Slide ────────────────────────────────────────────────────────────────────

class _OnboardingSlide extends StatelessWidget {
  final _SlideData slide;
  const _OnboardingSlide({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Zone dégradée haut (illustration)
        Expanded(
          flex: 5,
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF5B21B6), Color(0xFF3730A3)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Illustration centrée
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 16),
                          // Icône de la slide
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.20),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(slide.icon,
                                size: 32, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Zone blanche bas (texte)
        Expanded(
          flex: 5,
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre : premier mot en violet, reste en noir
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${slide.titleAccent}\n',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF5B21B6),
                          height: 1.1,
                        ),
                      ),
                      TextSpan(
                        text: slide.titleRest,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Description
                Text(
                  slide.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 12),

                // Tagline en gras italique
                Text(
                  slide.tagline,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Barre de navigation bas ──────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final int currentPage;
  final int total;
  final bool isLast;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  const _BottomBar({
    required this.currentPage,
    required this.total,
    required this.isLast,
    required this.onSkip,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Passer
          if (!isLast)
            GestureDetector(
              onTap: onSkip,
              child: const Text(
                'Passer',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            const SizedBox(width: 60),

          // Points indicateurs
          Row(
            children: List.generate(total, (i) {
              final active = i == currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 22 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFF5B21B6)
                      : const Color(0xFFD1C4E9),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),

          // Bouton suivant / Commencer
          GestureDetector(
            onTap: onNext,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: isLast ? 130 : 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5B21B6), Color(0xFF3730A3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(isLast ? 16 : 26),
              ),
              child: Center(
                child: isLast
                    ? const Text(
                        'Commencer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

