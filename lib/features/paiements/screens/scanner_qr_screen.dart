import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../domain/entities/compte_mobile_money.dart';
import '../../../presentation/providers/repository_providers.dart';
import 'paiement_qr_screen.dart';

/// Scanner un QR code de paiement pour effectuer un paiement depuis
/// [compteSource]. Seuls les QR codes du même opérateur sont acceptés — la
/// compatibilité est re-vérifiée côté serveur (voir
/// `TransfertQrRepository.identifierDestinataire`), jamais tranchée
/// uniquement côté mobile.
class ScannerQrScreen extends ConsumerStatefulWidget {
  final CompteMobileMoney compteSource;

  const ScannerQrScreen({super.key, required this.compteSource});

  @override
  ConsumerState<ScannerQrScreen> createState() => _ScannerQrScreenState();
}

class _ScannerQrScreenState extends ConsumerState<ScannerQrScreen> {
  final _controller = MobileScannerController(formats: const [BarcodeFormat.qrCode]);

  bool _traitementEnCours = false;
  String? _erreur;
  bool _torcheActive = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _surDetection(BarcodeCapture capture) async {
    if (_traitementEnCours) return;
    if (capture.barcodes.isEmpty) return;
    final valeur = capture.barcodes.first.rawValue;
    if (valeur == null || valeur.isEmpty) return;

    setState(() {
      _traitementEnCours = true;
      _erreur = null;
    });
    await _controller.stop();

    try {
      final destinataire = await ref
          .read(transfertQrRepositoryProvider)
          .identifierDestinataire(
            compteSourceId: widget.compteSource.id,
            qrScanne: valeur,
          );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PaiementQrScreen(
            compteSource: widget.compteSource,
            destinataire: destinataire,
            qrScanne: valeur,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _traitementEnCours = false;
        _erreur = e.message;
      });
      await _controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _surDetection,
          ),

          // Voile assombri avec fenêtre de visée centrale.
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _VoileScan()),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      _BoutonRond(
                        icone: Icons.arrow_back_rounded,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      _BoutonRond(
                        icone: _torcheActive
                            ? Icons.flash_on_rounded
                            : Icons.flash_off_rounded,
                        onTap: () async {
                          await _controller.toggleTorch();
                          if (!mounted) return;
                          setState(() => _torcheActive = !_torcheActive);
                        },
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      Text(
                        'Scannez un QR code ${widget.compteSource.operateur}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Seuls les comptes ${widget.compteSource.operateur} sont '
                        'compatibles avec votre compte.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      if (_traitementEnCours) ...[
                        const SizedBox(height: 20),
                        const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        ),
                      ],
                      if (_erreur != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.90),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _erreur!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BoutonRond extends StatelessWidget {
  final IconData icone;
  final VoidCallback onTap;

  const _BoutonRond({required this.icone, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        child: Icon(icone, color: Colors.white, size: 22),
      ),
    );
  }
}

/// Voile semi-transparent avec une fenêtre carrée découpée au centre —
/// guide visuel de visée, purement décoratif (la détection porte sur
/// l'image complète, pas seulement cette zone).
class _VoileScan extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fenetre = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 40),
      width: 260,
      height: 260,
    );

    final voile = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(fenetre, const Radius.circular(24)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(voile, Paint()..color = Colors.black.withValues(alpha: 0.55));

    canvas.drawRRect(
      RRect.fromRectAndRadius(fenetre, const Radius.circular(24)),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
