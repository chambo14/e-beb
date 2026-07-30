import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../presentation/providers/auth_controller.dart';
import '../../account_setup/account_setup_flow.dart';

/// Dernière étape de l'inscription : choix du code PIN à 6 chiffres
/// (`POST /auth/configurer-code-pin`).
class PinSetupScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final String? prenom;

  const PinSetupScreen({super.key, required this.phoneNumber, this.prenom});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  final _pinController = TextEditingController();
  final _confirmationController = TextEditingController();
  String? _erreur;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _valider() async {
    final pin = _pinController.text;
    final confirmation = _confirmationController.text;

    if (pin.length != 6) {
      setState(() => _erreur = 'Le code PIN doit comporter 6 chiffres.');
      return;
    }
    if (pin != confirmation) {
      setState(() => _erreur = 'Les deux codes ne correspondent pas.');
      return;
    }

    setState(() => _erreur = null);

    final succes = await ref
        .read(authControllerProvider.notifier)
        .definirCodePin(telephoneSaisi: widget.phoneNumber, codePin: pin);

    if (!mounted) return;

    if (!succes) {
      setState(
        () => _erreur = ref.read(messageErreurAuthProvider) ??
            'Impossible d\'enregistrer le code PIN.',
      );
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => AccountSetupFlow(
          prenom: widget.prenom ?? '',
          telephone: widget.phoneNumber,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final enCours = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.lock_outline_rounded,
                    color: AppColors.primaryBlue, size: 26),
              ),
              const SizedBox(height: 20),
              const Text(
                'Votre code PIN',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ce code à 6 chiffres protégera l\'accès à votre compte et '
                'validera vos opérations.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _champPin(
                      label: 'Nouveau code PIN',
                      controller: _pinController,
                    ),
                    const SizedBox(height: 20),
                    _champPin(
                      label: 'Confirmez le code PIN',
                      controller: _confirmationController,
                    ),
                    if (_erreur != null) ...[
                      const SizedBox(height: 16),
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
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: enCours ? null : _valider,
                      child: enCours
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text('Enregistrer mon code PIN'),
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

  Widget _champPin({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) {
            if (_erreur != null) setState(() => _erreur = null);
          },
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 8,
            color: AppColors.textPrimary,
          ),
          decoration: const InputDecoration(
            counterText: '',
            hintText: '••••••',
          ),
        ),
      ],
    );
  }
}
