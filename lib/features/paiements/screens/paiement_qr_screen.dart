import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../domain/entities/compte_mobile_money.dart';
import '../../../domain/entities/destinataire_qr.dart';
import '../../../presentation/providers/repository_providers.dart';
import '../../home/screens/home_screen.dart';

/// Confirmation et envoi d'un paiement par QR code.
///
/// Le montant confirmé ici est immédiatement traité côté serveur comme un
/// paiement reçu par le destinataire : répartition en cotisations, épargne
/// et commission, exactement comme un paiement confirmé par un opérateur
/// (voir `PaiementService::traiterPaiement()`). Aucune API opérateur
/// (MTN/Wave/Orange/Moov) n'est en revanche encore intégrée : rien ne débite
/// réellement le compte mobile money de l'expéditeur — le transfert de fonds
/// unitaire réel sera géré par une application Agent distincte.
class PaiementQrScreen extends ConsumerStatefulWidget {
  final CompteMobileMoney compteSource;
  final DestinataireQr destinataire;
  final String qrScanne;

  const PaiementQrScreen({
    super.key,
    required this.compteSource,
    required this.destinataire,
    required this.qrScanne,
  });

  @override
  ConsumerState<PaiementQrScreen> createState() => _PaiementQrScreenState();
}

enum _Etat { formulaire, enCours, succes, echec }

class _PaiementQrScreenState extends ConsumerState<PaiementQrScreen> {
  final _montantController = TextEditingController();
  _Etat _etat = _Etat.formulaire;
  String? _erreur;

  @override
  void dispose() {
    _montantController.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    final montant = double.tryParse(_montantController.text.replaceAll(',', '.'));
    if (montant == null || montant < 100) {
      setState(() => _erreur = 'Indiquez un montant valide (minimum 100 FCFA).');
      return;
    }

    setState(() {
      _erreur = null;
      _etat = _Etat.enCours;
    });

    try {
      await ref.read(transfertQrRepositoryProvider).envoyer(
            compteSourceId: widget.compteSource.id,
            qrScanne: widget.qrScanne,
            montant: montant,
          );
      if (!mounted) return;
      setState(() => _etat = _Etat.succes);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _etat = _Etat.echec;
        _erreur = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: _etat == _Etat.enCours ? null : () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Payer',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: switch (_etat) {
        _Etat.succes => _buildResultat(
            icone: Icons.check_circle_rounded,
            couleur: AppColors.success,
            titre: 'Paiement envoyé',
            texte: 'Le paiement a été traité : cotisations, épargne et '
                'commission ont été répartis sur le compte du destinataire.',
          ),
        _Etat.echec => _buildResultat(
            icone: Icons.error_rounded,
            couleur: AppColors.error,
            titre: 'Échec du paiement',
            texte: _erreur ?? 'Une erreur est survenue. Veuillez réessayer.',
            reessayer: () => setState(() => _etat = _Etat.formulaire),
          ),
        _Etat.formulaire || _Etat.enCours => _buildFormulaire(),
      },
    );
  }

  Widget _buildFormulaire() {
    final enCours = _etat == _Etat.enCours;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bandeau informatif — honnête sur la limite actuelle (pas de
            // débit réel via l'opérateur mobile money).
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.20)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.primaryBlue, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ce paiement sera immédiatement réparti (cotisations, '
                      'épargne, commission) sur le compte du destinataire. '
                      'Le débit réel via votre opérateur n\'est pas encore '
                      'intégré.',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Destinataire',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: AppColors.primaryBlue, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.destinataire.titulaire,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.destinataire.operateur} · '
                          '${widget.destinataire.numeroMasque}',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              'Compte à débiter',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                '${widget.compteSource.operateur} · '
                '${widget.compteSource.numeroCompte}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'Montant à payer',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _montantController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
              ],
              autofocus: true,
              onChanged: (_) {
                if (_erreur != null) setState(() => _erreur = null);
              },
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
              decoration: const InputDecoration(
                hintText: '0',
                suffixText: 'FCFA',
                suffixStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            if (_erreur != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.error, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _erreur!,
                      style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: enCours ? null : _envoyer,
              child: enCours
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text('Envoyer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultat({
    required IconData icone,
    required Color couleur,
    required String titre,
    required String texte,
    VoidCallback? reessayer,
  }) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: couleur.withValues(alpha: 0.12),
                ),
                child: Icon(icone, color: couleur, size: 50),
              ),
              const SizedBox(height: 20),
              Text(
                titre,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                texte,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              if (reessayer != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: reessayer,
                    child: const Text('Réessayer'),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  ),
                  child: const Text('Retour à l\'accueil'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
