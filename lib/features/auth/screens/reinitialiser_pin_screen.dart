import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../presentation/providers/repository_providers.dart';
import '../../../presentation/providers/session_provider.dart';

enum _Etape { otp, nouveauPin }

/// Parcours « code PIN oublié » : vérification d'identité par OTP (envoyé
/// par email à l'utilisateur déjà authentifié), puis définition d'un nouveau
/// code PIN. Poussé depuis [LockScreen] sur son Navigator imbriqué — ne
/// touche jamais à la pile de routes de l'application principale.
///
/// Le code PIN n'est à aucun moment récupéré ni affiché : uniquement
/// réinitialisé après authentification OTP réussie (voir le back-end,
/// `UserService::reinitialiserCodePin()`, qui refuse toute réinitialisation
/// sans OTP validé au préalable pour cet utilisateur).
class ReinitialiserPinScreen extends ConsumerStatefulWidget {
  const ReinitialiserPinScreen({super.key});

  @override
  ConsumerState<ReinitialiserPinScreen> createState() =>
      _ReinitialiserPinScreenState();
}

class _ReinitialiserPinScreenState
    extends ConsumerState<ReinitialiserPinScreen> {
  _Etape _etape = _Etape.otp;

  // ─── Étape OTP ──────────────────────────────────────────────────────────
  final _controleursOtp = List.generate(6, (_) => TextEditingController());
  final _focusOtp = List.generate(6, (_) => FocusNode());
  String? _erreurOtp;
  bool _enCoursOtp = false;
  int _secondesAvantRenvoi = 60;
  Timer? _minuteur;

  String get _otpSaisi => _controleursOtp.map((c) => c.text).join();

  // ─── Étape nouveau PIN ──────────────────────────────────────────────────
  final _nouveauPinController = TextEditingController();
  final _confirmationController = TextEditingController();
  String? _erreurPin;
  bool _enCoursPin = false;
  bool _succes = false;

  @override
  void initState() {
    super.initState();
    _demarrerMinuteur();
  }

  void _demarrerMinuteur() {
    _secondesAvantRenvoi = 60;
    _minuteur?.cancel();
    _minuteur = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondesAvantRenvoi == 0) {
        t.cancel();
      } else if (mounted) {
        setState(() => _secondesAvantRenvoi--);
      }
    });
  }

  @override
  void dispose() {
    for (final c in _controleursOtp) {
      c.dispose();
    }
    for (final f in _focusOtp) {
      f.dispose();
    }
    _minuteur?.cancel();
    _nouveauPinController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  void _surChiffreOtpChange(int index, String valeur) {
    if (valeur.isNotEmpty && index < 5) {
      _focusOtp[index + 1].requestFocus();
    }
    setState(() => _erreurOtp = null);
    if (_otpSaisi.length == 6) {
      Future.delayed(const Duration(milliseconds: 200), _verifierOtp);
    }
  }

  void _surChiffreOtpSupprime(int index) {
    if (_controleursOtp[index].text.isEmpty && index > 0) {
      _focusOtp[index - 1].requestFocus();
      _controleursOtp[index - 1].clear();
    }
  }

  Future<void> _verifierOtp() async {
    if (_otpSaisi.length < 6 || _enCoursOtp) return;
    setState(() {
      _enCoursOtp = true;
      _erreurOtp = null;
    });

    try {
      await ref
          .read(utilisateurRepositoryProvider)
          .verifierOtpReinitialisationPin(_otpSaisi);

      if (!mounted) return;
      setState(() {
        _enCoursOtp = false;
        _etape = _Etape.nouveauPin;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _enCoursOtp = false;
        _erreurOtp = e.message;
      });
      for (final c in _controleursOtp) {
        c.clear();
      }
      _focusOtp[0].requestFocus();
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> _renvoyerOtp() async {
    if (_secondesAvantRenvoi > 0 || _enCoursOtp) return;

    setState(() => _enCoursOtp = true);
    try {
      await ref.read(utilisateurRepositoryProvider).demanderReinitialisationPin();
      if (!mounted) return;
      setState(() => _enCoursOtp = false);
      _demarrerMinuteur();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Un nouveau code a été envoyé par email.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _enCoursOtp = false;
        _erreurOtp = e.message;
      });
    }
  }

  Future<void> _validerNouveauPin() async {
    final pin = _nouveauPinController.text;
    final confirmation = _confirmationController.text;

    if (pin.length != 6) {
      setState(() => _erreurPin = 'Le code PIN doit comporter 6 chiffres.');
      return;
    }
    if (pin != confirmation) {
      setState(() => _erreurPin = 'Les deux codes ne correspondent pas.');
      return;
    }

    setState(() {
      _erreurPin = null;
      _enCoursPin = true;
    });

    try {
      await ref.read(utilisateurRepositoryProvider).reinitialiserPin(pin);
      if (!mounted) return;
      setState(() {
        _enCoursPin = false;
        _succes = true;
      });
      // Laisse la confirmation visible un instant avant de déverrouiller —
      // le retrait de la superposition de verrouillage referme cet écran
      // avec elle (voir main.dart), aucun `pop` explicite n'est nécessaire.
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        ref.read(sessionProvider.notifier).deverrouiller();
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _enCoursPin = false;
        _erreurPin = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _succes
              ? _buildSucces()
              : _etape == _Etape.otp
                  ? _buildEtapeOtp()
                  : _buildEtapeNouveauPin(),
        ),
      ),
    );
  }

  Widget _buildEtapeOtp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.mark_email_read_outlined,
              color: AppColors.primaryBlue, size: 26),
        ),
        const SizedBox(height: 20),
        const Text(
          'Vérifiez votre identité',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Un code à 6 chiffres a été envoyé à l\'adresse email associée à '
          'votre compte.',
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
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  6,
                  (i) => _CaseOtp(
                    controller: _controleursOtp[i],
                    focusNode: _focusOtp[i],
                    enErreur: _erreurOtp != null,
                    autofocus: i == 0,
                    onChanged: (v) => _surChiffreOtpChange(i, v),
                    onSuppression: () => _surChiffreOtpSupprime(i),
                  ),
                ),
              ),
              if (_erreurOtp != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.error, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _erreurOtp!,
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
                onPressed:
                    _enCoursOtp || _otpSaisi.length < 6 ? null : _verifierOtp,
                child: _enCoursOtp
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('Vérifier le code'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: _secondesAvantRenvoi > 0
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer_outlined,
                        color: AppColors.textSecondary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Renvoyer le code dans $_secondesAvantRenvoi s',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 14),
                    ),
                  ],
                )
              : GestureDetector(
                  onTap: _renvoyerOtp,
                  child: const Text(
                    'Renvoyer le code',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildEtapeNouveauPin() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.lock_reset_rounded,
              color: AppColors.success, size: 26),
        ),
        const SizedBox(height: 20),
        const Text(
          'Nouveau code PIN',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Identité vérifiée. Choisissez le nouveau code à 6 chiffres qui '
          'protégera votre compte.',
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
                controller: _nouveauPinController,
              ),
              const SizedBox(height: 20),
              _champPin(
                label: 'Confirmez le code PIN',
                controller: _confirmationController,
              ),
              if (_erreurPin != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.error, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _erreurPin!,
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
                onPressed: _enCoursPin ? null : _validerNouveauPin,
                child: _enCoursPin
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('Enregistrer mon nouveau code PIN'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSucces() {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success.withValues(alpha: 0.12),
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 44),
          ),
          const SizedBox(height: 16),
          const Text(
            'Code PIN réinitialisé !',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Votre nouveau code PIN est actif. Vous accédez à votre espace.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
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
            if (_erreurPin != null) setState(() => _erreurPin = null);
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

/// Case de saisie d'un chiffre de l'OTP — un `TextField` indépendant par
/// case, chacun avec son propre contrôleur : aucune saisie ne peut donc se
/// répercuter sur les autres cases.
class _CaseOtp extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enErreur;
  final bool autofocus;
  final ValueChanged<String> onChanged;
  final VoidCallback onSuppression;

  const _CaseOtp({
    required this.controller,
    required this.focusNode,
    required this.enErreur,
    required this.onChanged,
    required this.onSuppression,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 52,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: enErreur
              ? AppColors.error.withValues(alpha: 0.06)
              : AppColors.inputFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: enErreur ? AppColors.error : AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: enErreur ? AppColors.error : AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: enErreur ? AppColors.error : AppColors.primaryBlue,
              width: 2,
            ),
          ),
        ),
        onChanged: (v) {
          if (v.isEmpty) {
            onSuppression();
          } else {
            onChanged(v);
          }
        },
      ),
    );
  }
}
