import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/user_model.dart';
import '../../../core/utils/qr_data.dart';
import '../../auth/screens/settings_page.dart';

class AccueilTab extends StatelessWidget {
  final UserModel user;

  const AccueilTab({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _UserHeader(user: user, onSettingsTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },),
              const SizedBox(height: 24),
              // _SoldeCard(user: user),
              _NetworkCardsSection(user: user),
              const SizedBox(height: 32),
              _CotisationTracker(cotisation: user.cotisation),
              const SizedBox(height: 32),
              _TransactionsList(transactions: TransactionModel.demoList),

            ],
          ),
        ),
      ),
    );
  }
}

// ─── Header utilisateur ───────────────────────────────────────────────────────
class _UserHeader extends StatelessWidget {
  final UserModel user;
  final VoidCallback onSettingsTap; // Callback pour la redirection

  const _UserHeader({
    required this.user,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.primaryBlue, AppColors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withValues(alpha: 0.30),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 26,
            backgroundColor: Colors.transparent,
            child: Text(
              user.initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        // Nom + matricule
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.fullName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  user.matricule,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Bloc des boutons d'action (Notification + Settings)
        Row(
          children: [
            // Cloche notification
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10), // Espace entre les deux icônes

            // Bouton Paramètres (Settings)
            GestureDetector(
              onTap: onSettingsTap,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.settings_outlined, // Icône moderne style outline
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Carte solde ─────────────────────────────────────────────────────────────

class _SoldeCard extends StatelessWidget {
  final UserModel user;
  const _SoldeCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'fr_FR');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Solde disponible',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${fmt.format(user.soldeDisponible)} FCFA',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _SoldeStat(
                label: 'Reçu ce mois',
                value: '+${fmt.format(user.totalRecuMois)} FCFA',
                color: const Color(0xFF7FFFB2),
              ),
              const SizedBox(width: 24),
              _SoldeStat(
                label: 'Déduit ce mois',
                value: '-${fmt.format(user.totalDeduitMois)} FCFA',
                color: Colors.white54,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SoldeStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SoldeStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

// ─── Liste des transactions ───────────────────────────────────────────────────

class _TransactionsList extends StatelessWidget {
  final List<TransactionModel> transactions;
  const _TransactionsList({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'fr_FR');
    final dateFmt = DateFormat('dd MMM · HH:mm', 'fr_FR');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transactions récentes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.border,
            ),
            itemBuilder: (_, i) {
              final tx = transactions[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    // Icône
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: tx.estCredit
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFF5F5F5),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(tx.icone, style: const TextStyle(fontSize: 18)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Libellé + description + date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.libelle,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            tx.estCredit
                                ? 'De : ${tx.description}'
                                : tx.description,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: tx.estCredit
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: tx.estCredit
                                  ? AppColors.primaryBlue
                                  : AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            dateFmt.format(tx.date),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Montant
                    Text(
                      '${tx.estCredit ? '+' : '-'}${fmt.format(tx.montant)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: tx.estCredit
                            ? const Color(0xFF2E7D32)
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Données réseaux ──────────────────────────────────────────────────────────

class _NetworkInfo {
  final String name;
  final String tag;
  final List<Color> gradient;
  final int seed;
  final bool available;

  const _NetworkInfo({
    required this.name,
    required this.tag,
    required this.gradient,
    required this.seed,
    this.available = true,
  });
}

const _networks = [
  _NetworkInfo(
    name: 'Wave',
    tag: 'Mobile Money',
    gradient: [Color(0xFF1ECFEE), Color(0xFF03A9C7)],
    seed: 42,
  ),
  _NetworkInfo(
    name: 'Orange Money',
    tag: 'Mobile Money',
    gradient: [Color(0xFF000000), Color(0xFF434343)],
    seed: 77,
    available: false,
  ),
  _NetworkInfo(
    name: 'MTN MoMo',
    tag: 'Mobile Money',
    gradient: [Color(0xFFFFCC00), Color(0xFFE6A800)],
    seed: 13,
    available: false,
  ),
  _NetworkInfo(
    name: 'Moov Money',
    tag: 'Mobile Money',
    gradient: [Color(0xFF1565C0), Color(0xFF003580)],
    seed: 99,
    available: false,
  ),
];

// ─── Section cartes réseau (PageView) ────────────────────────────────────────


class _NetworkCardsSection extends StatefulWidget {
  final UserModel user;
  const _NetworkCardsSection({required this.user});

  @override
  State<_NetworkCardsSection> createState() => _NetworkCardsSectionState();
}

class _NetworkCardsSectionState extends State<_NetworkCardsSection> {
  final _pageController = PageController(viewportFraction: 0.88);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // PageView des cartes
        SizedBox(
          height: 230,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _networks.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) {
              final net = _networks[i];
              return AnimatedScale(
                scale: _currentPage == i ? 1.0 : 0.93,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _NetworkCard(
                    network: net,
                    telephone: widget.user.telephone,
                    cnpsNumero: widget.user.cnpsNumero,
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 14),

        // Indicateurs de page
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_networks.length, (i) {
            final active = i == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active
                    ? _networks[i].gradient.first
                    : AppColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ─── Carte d'un réseau ────────────────────────────────────────────────────────

class _NetworkCard extends StatelessWidget {
  final _NetworkInfo network;
  final String telephone;
  final String cnpsNumero;

  const _NetworkCard({
    required this.network,
    required this.telephone,
    required this.cnpsNumero,
  });

  bool get _isWave => network.name == 'Wave';

  void _showExpanded(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => _QrScanPage(
          network: network,
          telephone: telephone,
          cnpsNumero: cnpsNumero,
        ),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showExpanded(context),
      child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: network.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Background Wave : motif losanges
          if (_isWave)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: CustomPaint(painter: _WaveBgPainter()),
              ),
            ),

          // Cercles décoratifs pour les autres réseaux
          if (!_isWave) ...[
            Positioned(top: -30, right: -30, child: _Circle(size: 120, opacity: 0.10)),
            Positioned(bottom: -20, left: -20, child: _Circle(size: 90, opacity: 0.07)),
          ],

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
                          child: QrImageView(
                            data: buildQrPayload(
                              network: network.name,
                              phone: telephone,
                              cnpsNumero: cnpsNumero,
                            ),
                            version: QrVersions.auto,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Colors.black,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Colors.black,
                            ),
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(18),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_rounded,
                                size: 12, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              'Scanner',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// ─── Page QR scan plein écran ─────────────────────────────────────────────────

class _QrScanPage extends StatelessWidget {
  final _NetworkInfo network;
  final String telephone;
  final String cnpsNumero;

  const _QrScanPage({
    required this.network,
    required this.telephone,
    required this.cnpsNumero,
  });

  bool get _isWave => network.name == 'Wave';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: network.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Fond Wave
            if (_isWave)
              Positioned.fill(
                child: CustomPaint(painter: _WaveBgPainter()),
              ),
            // Cercles pour les autres
            if (!_isWave) ...[
              Positioned(top: -100, right: -80, child: _Circle(size: 320, opacity: 0.10)),
              Positioned(bottom: -80, left: -80, child: _Circle(size: 260, opacity: 0.07)),
            ],

            SafeArea(
              child: Column(
                children: [
                  // Barre de navigation
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          network.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Instruction haut
                  Text(
                    'Présentez ce code à l\'opérateur',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // QR code
                  Container(
                    width: 300,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                          child: QrImageView(
                            data: buildQrPayload(
                              network: network.name,
                              phone: telephone,
                              cnpsNumero: cnpsNumero,
                            ),
                            version: QrVersions.auto,
                            size: 260,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Colors.black,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Colors.black,
                            ),
                            backgroundColor: Colors.white,
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(24),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_rounded,
                                  size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 6),
                              Text(
                                'Scanner pour recevoir',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Numéro de téléphone masqué
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      telephone,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Wave background painter ─────────────────────────────────────────────────

class _WaveBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Grille de losanges (motif Wave)
    const spacing = 28.0;
    const half = spacing / 2;

    for (double y = -spacing; y < size.height + spacing; y += spacing) {
      for (double x = -spacing; x < size.width + spacing; x += spacing) {
        final path = Path()
          ..moveTo(x, y - half)
          ..lineTo(x + half, y)
          ..lineTo(x, y + half)
          ..lineTo(x - half, y)
          ..close();
        canvas.drawPath(path, paint);
      }
    }

    // Losanges pleins accentués (quelques-uns)
    final fillPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;

    final accents = [
      Offset(size.width * 0.15, size.height * 0.25),
      Offset(size.width * 0.80, size.height * 0.15),
      Offset(size.width * 0.70, size.height * 0.75),
      Offset(size.width * 0.10, size.height * 0.80),
    ];
    for (final center in accents) {
      const r = 18.0;
      final path = Path()
        ..moveTo(center.dx, center.dy - r)
        ..lineTo(center.dx + r, center.dy)
        ..lineTo(center.dx, center.dy + r)
        ..lineTo(center.dx - r, center.dy)
        ..close();
      canvas.drawPath(path, fillPaint);
    }
  }

  @override
  bool shouldRepaint(_WaveBgPainter _) => false;
}

// ─── Cercle décoratif ─────────────────────────────────────────────────────────

class _Circle extends StatelessWidget {
  final double size;
  final double opacity;

  const _Circle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

// ─── Suivi cotisations ────────────────────────────────────────────────────────

class _CotisationTracker extends StatefulWidget {
  final CotisationModel cotisation;

  const _CotisationTracker({required this.cotisation});

  @override
  State<_CotisationTracker> createState() => _CotisationTrackerState();
}

class _CotisationTrackerState extends State<_CotisationTracker> {
  int _tab = 0;

  static const _moisLabels = [
    'Janvier','Février','Mars','Avril','Mai','Juin',
    'Juillet','Août','Septembre','Octobre','Novembre','Décembre',
  ];

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'fr_FR');
    final c = widget.cotisation;
    final isMois = _tab == 0;

    final verse    = isMois ? c.mensuelVerse    : c.annuelVerse;
    final cible    = isMois ? c.mensuelCible    : c.annuelCible;
    final progress = isMois ? c.progressMensuel : c.progressAnnuel;
    final color    = isMois ? AppColors.primaryBlue : AppColors.purple;
    final icon     = isMois ? '📅' : '📆';
    final titre    = isMois
        ? 'Ce mois — ${_moisLabels[DateTime.now().month - 1]}'
        : 'Annuel ${DateTime.now().year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre + tab switcher sur la même ligne
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mes cotisations retraite',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            _TabSwitcher(
              selected: _tab,
              onTap: (i) => setState(() => _tab = i),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'CNPS — Suivi de vos versements',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),

        // Carte animée
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: Container(
            key: ValueKey(_tab),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.10),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: _ProgressBloc(
              icon: icon,
              titre: titre,
              verse: verse,
              cible: cible,
              progress: progress,
              fmt: fmt,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

// Tab switcher Mois / Année
class _TabSwitcher extends StatelessWidget {
  final int selected;
  final void Function(int) onTap;

  const _TabSwitcher({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.border.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _TabItem(label: 'Mois',  selected: selected == 0, onTap: () => onTap(0)),
          _TabItem(label: 'Année', selected: selected == 1, onTap: () => onTap(1)),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabItem({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ProgressBloc extends StatelessWidget {
  final String icon;
  final String titre;
  final double verse;
  final double cible;
  final double progress;
  final NumberFormat fmt;
  final Color color;

  const _ProgressBloc({
    required this.icon,
    required this.titre,
    required this.verse,
    required this.cible,
    required this.progress,
    required this.fmt,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête : icône + titre + pourcentage
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                titre,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              '$pct %',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Barre de progression
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            backgroundColor: color.withValues(alpha: 0.10),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),

        const SizedBox(height: 8),

        // Versé / Objectif sous la barre
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${fmt.format(verse)} FCFA',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              '${fmt.format(cible)} FCFA',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textHint,

              ),
              
            ),
          ],
        ),
      ],
    );
  }
}

