import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../presentation/providers/auth_controller.dart';
import 'otp_screen.dart';
import 'register_screen.dart';

class PhoneInputScreen extends ConsumerStatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  ConsumerState<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends ConsumerState<PhoneInputScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _verifyPhone() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneController.text.replaceAll(' ', '');

    // L'API décide : elle envoie un OTP si le compte existe, et répond 422
    // « ce numéro n'existe pas » sinon.
    final succes = await ref
        .read(authControllerProvider.notifier)
        .demanderConnexion(phone);

    if (!mounted) return;

    if (succes) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpScreen(phoneNumber: phone),
        ),
      );
      return;
    }

    _proposerInscription(phone);
  }

  /// Affiche l'erreur renvoyée par l'API et, si le compte est inconnu, propose
  /// de basculer vers l'inscription.
  void _proposerInscription(String phone) {
    final message =
        ref.read(messageErreurAuthProvider) ?? 'Connexion impossible.';
    final compteInconnu = message.toLowerCase().contains('existe pas');

    if (!compteInconnu) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Aucun compte trouvé'),
        content: Text(
          'Le numéro +225 $phone n\'est pas encore enregistré. '
          'Souhaitez-vous créer votre compte Ebeb Finance ?',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Modifier le numéro'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RegisterScreen(phoneNumber: phone),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(140, 44),
            ),
            child: const Text('S\'inscrire'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  // En-tête
                  _buildHeader(),
                  const SizedBox(height: 48),
                  // Carte formulaire
                  _buildFormCard(),
                  const SizedBox(height: 32),
                  // Mention légale
                  _buildLegalNote(),
                  const SizedBox(height: 40),
                ],
              ),
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
        // Mini logo inline
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Image.asset("assets/logo.jpeg", fit: BoxFit.contain),
            ),
            const SizedBox(width: 10),
          ],
        ),
        const SizedBox(height: 36),
        const Text(
          'Bienvenue !',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Saisissez votre numéro de téléphone\npour continuer.',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    final enCours = ref.watch(authControllerProvider).isLoading;
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Numéro de téléphone',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            // Champ téléphone avec préfixe pays
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
                _PhoneNumberFormatter(),
              ],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: 2,
              ),
              decoration: InputDecoration(
                prefixIcon: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(color: AppColors.border, width: 1),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🇨🇮', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 6),
                      Text(
                        '+225',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                hintText: '07 00 00 00 00',
                hintStyle: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 18,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w400,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez saisir votre numéro de téléphone';
                }
                final digits = value.replaceAll(' ', '');
                if (digits.length < 10) {
                  return 'Le numéro doit comporter 10 chiffres';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            // Bouton continuer
            ElevatedButton(
              onPressed: enCours ? null : _verifyPhone,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                disabledBackgroundColor: AppColors.primaryBlue.withValues(alpha: 0.6),
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: enCours
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Continuer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalNote() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            children: [
              TextSpan(text: 'En continuant, vous acceptez nos '),
              TextSpan(
                text: 'Conditions d\'utilisation',
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
              TextSpan(text: ' et notre '),
              TextSpan(
                text: 'Politique de confidentialité',
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
              TextSpan(text: '.'),
            ],
          ),
        ),
      ),
    );
  }
}

// Formateur de numéro ivoirien : XXXXXXXXXX → XX XX XX XX XX
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 2 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
