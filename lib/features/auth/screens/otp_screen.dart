import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../presentation/providers/auth_controller.dart';
import '../../home/screens/home_screen.dart';
import 'pin_setup_screen.dart';

/// Parcours dont provient l'écran : le code OTP est validé par deux routes
/// différentes selon qu'il s'agit d'une création de compte ou d'une connexion.
enum ModeOtp { connexion, inscription }

class OtpScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final ModeOtp mode;
  final String? prenom;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    this.mode = ModeOtp.connexion,
    this.prenom,
  });

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _hasError = false;
  String _errorMessage = '';

  int _secondsRemaining = 60;
  Timer? _timer;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  bool get _isLoading => ref.watch(authControllerProvider).isLoading;

  String get _telephoneAffiche =>
      Formatters.telephoneApi(widget.phoneNumber);

  @override
  void initState() {
    super.initState();
    _startTimer();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  void _startTimer() {
    _secondsRemaining = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining == 0) {
        t.cancel();
      } else {
        if (mounted) setState(() => _secondsRemaining--);
      }
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  String get _enteredOtp => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() {
      _hasError = false;
      _errorMessage = '';
    });
    if (_enteredOtp.length == 6) {
      Future.delayed(const Duration(milliseconds: 200), _verifyOtp);
    }
  }

  void _onDigitDeleted(int index) {
    if (_controllers[index].text.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
    }
  }

  Future<void> _verifyOtp() async {
    if (_enteredOtp.length < 6 || _isLoading) return;

    setState(() => _hasError = false);

    final controller = ref.read(authControllerProvider.notifier);
    final succes = switch (widget.mode) {
      ModeOtp.connexion => await controller.confirmerConnexion(
        telephoneSaisi: widget.phoneNumber,
        codeOtp: _enteredOtp,
      ),
      ModeOtp.inscription => await controller.verifierOtpInscription(
        telephoneSaisi: widget.phoneNumber,
        codeOtp: _enteredOtp,
      ),
    };

    if (!mounted) return;

    if (succes) {
      _showSuccessDialog();
      return;
    }

    setState(() {
      _hasError = true;
      _errorMessage =
          ref.read(messageErreurAuthProvider) ??
          'Code incorrect. Veuillez réessayer.';
    });
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
    HapticFeedback.heavyImpact();
  }

  void _showSuccessDialog() {
    HapticFeedback.lightImpact();

    final estInscription = widget.mode == ModeOtp.inscription;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success.withValues(alpha: 0.12),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 44,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              estInscription ? 'Numéro vérifié !' : 'Connexion réussie !',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              estInscription
                  ? 'Définissez maintenant votre code PIN'
                  : 'Bienvenue sur Ebeb Finance',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );

    // Redirection automatique après 2 secondes
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => estInscription
              ? PinSetupScreen(
                  phoneNumber: widget.phoneNumber,
                  prenom: widget.prenom,
                )
              : const HomeScreen(),
        ),
        (route) => false,
      );
    });
  }

  Future<void> _resendOtp() async {
    if (_secondsRemaining > 0 || _isLoading) return;

    final succes = await ref
        .read(authControllerProvider.notifier)
        .renvoyerOtp(widget.phoneNumber);
    if (!mounted) return;

    if (!succes) {
      setState(() {
        _hasError = true;
        _errorMessage = ref.read(messageErreurAuthProvider) ??
            'Impossible de renvoyer le code.';
      });
      return;
    }

    _startTimer();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Code renvoyé au $_telephoneAffiche'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                _buildHeader(),
                const SizedBox(height: 40),
                _buildOtpCard(),
                const SizedBox(height: 28),
                _buildResendSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Image.asset('assets/logo.jpeg', fit: BoxFit.contain),
        ),
        const SizedBox(height: 20),
        const Text(
          'Vérification',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            children: [
              const TextSpan(text: 'Un code à 6 chiffres a été envoyé au\n'),
              TextSpan(
                text: _telephoneAffiche,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOtpCard() {
    return Container(
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
              (i) => _OtpBox(
                controller: _controllers[i],
                focusNode: _focusNodes[i],
                hasError: _hasError,
                autofocus: i == 0,
                onChanged: (v) => _onDigitChanged(i, v),
                onDelete: () => _onDigitDeleted(i),
              ),
            ),
          ),
          if (_hasError) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppColors.error, size: 16),
                const SizedBox(width: 6),
                Text(
                  _errorMessage,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed:
                _isLoading || _enteredOtp.length < 6 ? null : _verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              disabledBackgroundColor:
                  AppColors.primaryBlue.withValues(alpha: 0.4),
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : const Text(
                    'Vérifier le code',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildResendSection() {
    return Center(
      child: _secondsRemaining > 0
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer_outlined,
                    color: AppColors.textSecondary, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Renvoyer le code dans $_secondsRemaining s',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 14),
                ),
              ],
            )
          : GestureDetector(
              onTap: _resendOtp,
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
    );
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final bool autofocus;
  final ValueChanged<String> onChanged;
  final VoidCallback onDelete;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onChanged,
    required this.onDelete,
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
          fillColor: hasError
              ? AppColors.error.withValues(alpha: 0.06)
              : AppColors.inputFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: hasError ? AppColors.error : AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: hasError ? AppColors.error : AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: hasError ? AppColors.error : AppColors.primaryBlue,
              width: 2,
            ),
          ),
        ),
        onChanged: (v) {
          if (v.isEmpty) {
            onDelete();
          } else {
            onChanged(v);
          }
        },
      ),
    );
  }
}
