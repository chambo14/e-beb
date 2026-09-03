import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../domain/entities/compte_mobile_money.dart';
import '../../../domain/entities/destinataire_qr.dart';
import '../../../presentation/providers/repository_providers.dart';
import '../../../presentation/providers/session_provider.dart';

/// Contenu du scan de QR code pour effectuer un paiement depuis
/// [compteSource] — embarqué dans l'écran QR de l'accueil (bascule « Scanner
/// un code » / « Ma carte »), sans Scaffold ni barre de navigation propres.
///
/// Seuls les QR codes du même opérateur sont acceptés — la compatibilité est
/// re-vérifiée côté serveur (voir `TransfertQrRepository.identifierDestinataire`),
/// jamais tranchée uniquement côté mobile.
class ScannerQrCorps extends ConsumerStatefulWidget {
  final CompteMobileMoney compteSource;

  /// Appelé une fois le compte destinataire identifié avec succès — au
  /// parent de décider de la suite (ouvrir l'écran de paiement).
  final void Function(DestinataireQr destinataire, String qrScanne) onIdentifie;

  const ScannerQrCorps({
    super.key,
    required this.compteSource,
    required this.onIdentifie,
  });

  @override
  ConsumerState<ScannerQrCorps> createState() => _ScannerQrCorpsState();
}

class _ScannerQrCorpsState extends ConsumerState<ScannerQrCorps>
    with WidgetsBindingObserver {
  final _controller = MobileScannerController(formats: const [BarcodeFormat.qrCode]);

  bool _traitementEnCours = false;
  String? _erreur;
  bool _torcheActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  /// Cycle de vie de la caméra géré explicitement ici plutôt que par
  /// `MobileScanner.useAppLifecycleState` (désactivé ci-dessous) : par
  /// défaut, ce paquet relance la caméra dès `resumed` — y compris quand
  /// l'application revient au premier plan alors que l'écran de
  /// verrouillage (voir `LockScreen`) est encore affiché par-dessus. La
  /// caméra redémarre alors « à l'aveugle » derrière le verrou, en même
  /// temps que l'OS peut recréer la surface/texture native pour cette même
  /// transition — ce qui laisse le contrôleur dans un état incohérent
  /// (texture invalide, `start()` qui ne se termine jamais) une fois l'écran
  /// réellement déverrouillé. On ne relance donc la caméra qu'une fois
  /// l'application effectivement déverrouillée, jamais sur un simple
  /// `resumed` du système.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        unawaited(_controller.stop());
      case AppLifecycleState.resumed:
        _reprendreSiDeverrouille();
      case AppLifecycleState.detached:
        break;
    }
  }

  void _reprendreSiDeverrouille() {
    if (!mounted || _controller.value.isRunning) return;
    if (ref.read(sessionProvider).verrouille) return;
    unawaited(_controller.start().catchError((_) {}));
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
      widget.onIdentifie(destinataire, valeur);
      setState(() => _traitementEnCours = false);
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
    // `resumed` peut survenir alors que l'application est encore verrouillée
    // (voir `didChangeAppLifecycleState` ci-dessus, qui ignore ce cas) : on
    // reprend donc aussi la caméra dès le déverrouillage effectif.
    ref.listen(sessionProvider, (precedent, courant) {
      if (precedent?.verrouille == true && !courant.verrouille) {
        _reprendreSiDeverrouille();
      }
    });

    return Stack(
      fit: StackFit.expand,
      children: [
        // `useAppLifecycleState: false` — le cycle de vie est géré nous-mêmes
        // ci-dessus (`didChangeAppLifecycleState`) pour ne jamais relancer la
        // caméra pendant que l'écran de verrouillage est actif ; sans ce
        // réglage, ce paquet installerait son propre observateur concurrent
        // et relancerait la caméra à l'aveugle sur chaque `resumed`.
        MobileScanner(
          controller: _controller,
          onDetect: _surDetection,
          useAppLifecycleState: false,
        ),

        // Voile assombri avec fenêtre de visée centrale.
        Positioned.fill(
          child: IgnorePointer(child: CustomPaint(painter: _VoileScan())),
        ),

        Positioned(
          top: 12,
          right: 12,
          child: _BoutonRond(
            icone: _torcheActive ? Icons.flash_on_rounded : Icons.flash_off_rounded,
            onTap: () async {
              await _controller.toggleTorch();
              if (!mounted) return;
              setState(() => _torcheActive = !_torcheActive);
            },
          ),
        ),

        Positioned(
          left: 24,
          right: 24,
          bottom: 24,
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
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                ),
              ],
              if (_erreur != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
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
      ],
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
