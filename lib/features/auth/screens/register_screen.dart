import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../home/screens/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String phoneNumber;

  const RegisterScreen({super.key, required this.phoneNumber});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _scrollController = ScrollController();
  int _currentStep = 0; // 0=Identification, 1=Pièces, 2=Finalisation

  // ── Étape 1 : Identité ─────────────────────────────────────────────────────
  final _cnamController = TextEditingController();
  final _nomController = TextEditingController();
  final _prenomsController = TextEditingController();
  String? _genre;
  String? _situationMatrimoniale;
  DateTime? _dateNaissance;

  // ── Étape 1 : Déclaration du revenu ─────────────────────────────────────────
  final _revenuController = TextEditingController();

  // ── Étape 1 : Informations professionnelles ──────────────────────────────────
  String? _categorieSocioPro;
  final _activiteController = TextEditingController();
  DateTime? _dateDebutActivite;
  final _villeProController = TextEditingController();
  final _quartierProController = TextEditingController();
  final _communeProController = TextEditingController();

  // ── Étape 1 : Informations personnelles ──────────────────────────────────────
  final _villeController = TextEditingController();
  final _communeController = TextEditingController();
  final _quartierController = TextEditingController();
  final _boitePostaleController = TextEditingController();
  final _emailController = TextEditingController();

  // ── Étape 2 : Pièces ─────────────────────────────────────────────────────
  String? _photoFileName;
  String? _idRectoFileName;
  String? _idVersoFileName;
  bool _infosConfirmees = false;

  bool _isLoading = false;

  static const _genreOptions = ['MASCULIN', 'FÉMININ'];
  static const _situationOptions = [
    'CÉLIBATAIRE',
    'MARIÉ(E)',
    'DIVORCÉ(E)',
    'SÉPARÉ(E)',
    'VEUF / VEUVE',
  ];
  static const _categorieOptions = [
    'ARTISAN',
    'COMMERÇANT(E)',
    'PRESTATAIRE DE SERVICES',
    'AGRICULTEUR',
    'CONSULTANT(E)',
    'PROFESSIONNEL DE SANTÉ',
    'ENSEIGNANT(E)',
    'AUTRE',
  ];

  @override
  void initState() {
    super.initState();
    _revenuController.addListener(_onRevenuChanged);
  }

  @override
  void dispose() {
    _cnamController.dispose();
    _nomController.dispose();
    _prenomsController.dispose();
    _revenuController.dispose();
    _activiteController.dispose();
    _villeProController.dispose();
    _quartierProController.dispose();
    _communeProController.dispose();
    _villeController.dispose();
    _communeController.dispose();
    _quartierController.dispose();
    _boitePostaleController.dispose();
    _emailController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onRevenuChanged() => setState(() {});

  double get _revenuMensuel =>
      double.tryParse(_revenuController.text.replaceAll(' ', '')) ?? 0;

  double get _cotisationBase => _revenuMensuel * 0.048;
  double get _cotisationComplementaire => _revenuMensuel * 0.012;
  double get _cotisationMensuelle => _cotisationBase + _cotisationComplementaire;
  double get _cotisationTrimestrielle => _cotisationMensuelle * 3;

  String _formatF(double v) =>
      '${NumberFormat('#,##0', 'fr_FR').format(v)} F CFA';

  Future<void> _pickDate({required bool isNaissance}) async {
    final now = DateTime.now();
    final initial = isNaissance ? DateTime(1990) : DateTime(now.year - 5);
    final first = isNaissance ? DateTime(1920) : DateTime(1970);
    final last = isNaissance
        ? now.subtract(const Duration(days: 365 * 18))
        : now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      locale: const Locale('fr'),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primaryBlue,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isNaissance) {
        _dateNaissance = picked;
      } else {
        _dateDebutActivite = picked;
      }
    });
  }

  bool _validateStep0() {
    if (_nomController.text.trim().isEmpty) return false;
    if (_prenomsController.text.trim().isEmpty) return false;
    if (_genre == null) return false;
    if (_situationMatrimoniale == null) return false;
    if (_dateNaissance == null) return false;
    if (_revenuController.text.trim().isEmpty) return false;
    if (_categorieSocioPro == null) return false;
    if (_activiteController.text.trim().isEmpty) return false;
    if (_villeProController.text.trim().isEmpty) return false;
    if (_quartierProController.text.trim().isEmpty) return false;
    if (_communeProController.text.trim().isEmpty) return false;
    if (_villeController.text.trim().isEmpty) return false;
    if (_communeController.text.trim().isEmpty) return false;
    if (_quartierController.text.trim().isEmpty) return false;
    return true;
  }

  void _next() {
    if (_currentStep == 0) {
      if (!_validateStep0()) {
        _showError('Veuillez remplir tous les champs obligatoires (*).');
        return;
      }
      setState(() => _currentStep = 1);
      _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else if (_currentStep == 1) {
      if (_photoFileName == null || _idRectoFileName == null || _idVersoFileName == null) {
        _showError('Veuillez importer tous les documents requis.');
        return;
      }
      if (!_infosConfirmees) {
        _showError('Veuillez confirmer que les informations sont correctes.');
        return;
      }
      setState(() => _currentStep = 2);
      _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      _submit();
    }
  }

  void _prev() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      Navigator.pop(context);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    setState(() => _isLoading = false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                    colors: [AppColors.primaryBlue, AppColors.purple]),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 44),
            ),
            const SizedBox(height: 20),
            const Text('Compte créé !',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            Text(
              'Bienvenue ${_prenomsController.text} ${_nomController.text} !\nVotre compte E-BEB SALARY a été créé avec succès.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Accéder à mon compte'),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEEF2F7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: _prev,
        ),
        title: const Text(
          'Inscription',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                children: [
                  if (_currentStep == 0) _buildStep0(),
                  if (_currentStep == 1) _buildStep1(),
                  if (_currentStep == 2) _buildStep2(),
                  const SizedBox(height: 20),
                  _buildNavButton(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Indicateur d'étapes ───────────────────────────────────────────────────

  Widget _buildStepIndicator() {
    const labels = ['Identification', 'Pièces', 'Finalisation'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(5, (i) {
          if (i.isEven) {
            final step = i ~/ 2;
            final isDone = step < _currentStep;
            final isActive = step == _currentStep;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone || isActive
                        ? AppColors.primaryBlue
                        : Colors.white,
                    border: Border.all(
                      color: isActive || isDone
                          ? AppColors.primaryBlue
                          : AppColors.border,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : Text(
                            '${step + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: isActive
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  labels[step],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w400,
                    color: isActive
                        ? AppColors.primaryBlue
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            );
          } else {
            // Ligne connectrice
            final stepBefore = (i - 1) ~/ 2;
            final isDone = stepBefore < _currentStep;
            return Expanded(
              child: Container(
                height: 1.5,
                margin: const EdgeInsets.only(bottom: 18),
                color: isDone ? AppColors.primaryBlue : AppColors.border,
              ),
            );
          }
        }),
      ),
    );
  }

  // ── Étape 0 : Identification ──────────────────────────────────────────────

  Widget _buildStep0() {
    return Column(
      children: [
        _sectionCard(
          title: 'IDENTITE DU TRAVAILLEUR',
          color: const Color(0xFF1A3A6B),
          children: [
            _cnpsField('N° CNAM', _cnamController,
                hint: '123', required: false),
            _divider(),
            _cnpsField('NOM', _nomController,
                caps: TextCapitalization.characters),
            _divider(),
            _cnpsField('PRENOMS', _prenomsController,
                caps: TextCapitalization.words),
            _divider(),
            _dropdownField('GENRE', _genreOptions, _genre,
                (v) => setState(() => _genre = v)),
            _divider(),
            _dropdownField(
                'SITUATION MATRIMONIALE',
                _situationOptions,
                _situationMatrimoniale,
                (v) => setState(() => _situationMatrimoniale = v)),
            _divider(),
            _dateField('DATE DE NAISSANCE', _dateNaissance,
                () => _pickDate(isNaissance: true)),
          ],
        ),
        const SizedBox(height: 16),
        _sectionCard(
          title: 'DECLARATION DU REVENU',
          color: const Color(0xFF2196F3),
          children: [
            _revenuField(),
            _divider(),
            _calcField('COTISATION REGIME DE BASE',
                _revenuMensuel > 0 ? _formatF(_cotisationBase) : ''),
            _divider(),
            _calcField('COTISATION REGIME COMPLEMENTAIRE',
                _revenuMensuel > 0 ? _formatF(_cotisationComplementaire) : ''),
            _divider(),
            _calcField('COTISATION MENSUELLE',
                _revenuMensuel > 0 ? _formatF(_cotisationMensuelle) : ''),
            _divider(),
            _calcField('COTISATION TRIMESTRIELLE',
                _revenuMensuel > 0 ? _formatF(_cotisationTrimestrielle) : ''),
          ],
        ),
        const SizedBox(height: 16),
        _sectionCard(
          title: 'INFORMATIONS PROFESSIONNELLES',
          color: const Color(0xFFE07B20),
          children: [
            _dropdownField('CATEGORIE SOCIOPROFESSIONNELLE',
                _categorieOptions, _categorieSocioPro,
                (v) => setState(() => _categorieSocioPro = v)),
            _divider(),
            _cnpsField('ACTIVITE / METIER EXERCE', _activiteController,
                hint: 'ACTIVITE'),
            _divider(),
            _dateField('DATE DE DEBUT D\'ACTIVITE', _dateDebutActivite,
                () => _pickDate(isNaissance: false),
                required: false),
            _divider(),
            _cnpsField('VILLE', _villeProController,
                hint: 'EX: ABIDJAN',
                caps: TextCapitalization.characters),
            _divider(),
            _cnpsField('QUARTIER', _quartierProController,
                hint: 'EX: RIVIERA',
                caps: TextCapitalization.characters),
            _divider(),
            _cnpsField('COMMUNE OU SOUS PREFECTURE', _communeProController,
                hint: 'EX: COCODY',
                caps: TextCapitalization.characters),
          ],
        ),
        const SizedBox(height: 16),
        _sectionCard(
          title: 'INFORMATIONS PERSONNELLES',
          color: const Color(0xFF2E7D32),
          children: [
            _cnpsField('VILLE', _villeController,
                hint: 'EX: ABIDJAN',
                caps: TextCapitalization.characters),
            _divider(),
            _cnpsField('COMMUNE OU SOUS PREFECTURE', _communeController,
                hint: 'EX: COCODY',
                caps: TextCapitalization.characters),
            _divider(),
            _cnpsField('QUARTIER', _quartierController,
                hint: 'EX: RIVIERA',
                caps: TextCapitalization.characters),
            _divider(),
            _cnpsField('BOITE POSTALE', _boitePostaleController,
                hint: 'BOITE POSTALE', required: false),
            _divider(),
            // Téléphone pré-rempli
            _labeledWidget(
              'TELEPHONE',
              required: true,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FB),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFBBD6F5)),
                ),
                child: Row(
                  children: [
                    const Text('🇨🇮 +225 ',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    Text(
                      widget.phoneNumber,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
            _divider(),
            _cnpsField('EMAIL', _emailController,
                hint: 'EMAIL',
                required: false,
                keyboardType: TextInputType.emailAddress),
          ],
        ),
      ],
    );
  }

  // ── Étape 1 : Pièces ─────────────────────────────────────────────────────

  Widget _buildStep1() {
    return Column(
      children: [
        // Carte principale avec ligne bleue en haut
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border(
              top: const BorderSide(color: AppColors.primaryBlue, width: 3),
              left: BorderSide(color: Colors.grey.shade200),
              right: BorderSide(color: Colors.grey.shade200),
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'POURSUIVEZ VOTRE ENREGISTREMENT EN IMPORTANT VOS PIECES TRAVAILLEUR',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A3A6B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFE0E0E0)),
              const SizedBox(height: 16),

              // IMPORTEZ VOTRE PHOTO
              _fileUploadField(
                label: 'IMPORTEZ VOTRE PHOTO',
                fileName: _photoFileName,
                onTap: () =>
                    setState(() => _photoFileName = 'photo_identite.jpg'),
              ),
              const SizedBox(height: 16),

              // Document d'identité recto
              _fileUploadField(
                label: 'Document d\'identité recto',
                fileName: _idRectoFileName,
                onTap: () =>
                    setState(() => _idRectoFileName = 'cni_recto.jpg'),
              ),
              const SizedBox(height: 16),

              // Document d'identité verso
              _fileUploadField(
                label: 'Document d\'identité verso',
                fileName: _idVersoFileName,
                onTap: () =>
                    setState(() => _idVersoFileName = 'cni_verso.jpg'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Checkbox confirmation
        GestureDetector(
          onTap: () =>
              setState(() => _infosConfirmees = !_infosConfirmees),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: _infosConfirmees,
                  onChanged: (v) =>
                      setState(() => _infosConfirmees = v ?? false),
                  activeColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3)),
                  side: const BorderSide(color: Color(0xFFBBBBBB)),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Les informations saisies sont bien correctes',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Bouton RETOUR
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _prev,
            icon: const Icon(Icons.keyboard_double_arrow_left_rounded,
                color: Colors.white, size: 18),
            label: const Text(
              'RETOUR',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A3A6B),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _fileUploadField({
    required String label,
    required String? fileName,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF444444),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFCCCCCC)),
                ),
                child: const Text(
                  'Choisir un fichier',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF333333),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            if (fileName != null) ...[
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  fileName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF22C55E),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF22C55E), size: 16),
            ] else
              const Padding(
                padding: EdgeInsets.only(left: 10),
                child: Text(
                  'Aucun fichier choisi',
                  style: TextStyle(
                      fontSize: 12, color: Color(0xFF888888)),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ── Étape 2 : Finalisation ────────────────────────────────────────────────

  Widget _buildStep2() {
    final dateFmt = DateFormat('dd/MM/yyyy');
    return Column(
      children: [
        _sectionCard(
          title: 'RÉCAPITULATIF',
          color: const Color(0xFF1A3A6B),
          children: [
            _recapRow('NOM', _nomController.text),
            _recapRow('PRÉNOMS', _prenomsController.text),
            _recapRow('GENRE', _genre ?? '-'),
            _recapRow('SITUATION',
                _situationMatrimoniale ?? '-'),
            _recapRow(
                'DATE DE NAISSANCE',
                _dateNaissance != null
                    ? dateFmt.format(_dateNaissance!)
                    : '-'),
            _recapRow('REVENU MENSUEL',
                _revenuMensuel > 0 ? _formatF(_revenuMensuel) : '-'),
            _recapRow('COTISATION MENSUELLE',
                _revenuMensuel > 0 ? _formatF(_cotisationMensuelle) : '-'),
            _recapRow('ACTIVITÉ', _activiteController.text),
            _recapRow('TÉLÉPHONE', '+225 ${widget.phoneNumber}'),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.primaryBlue.withValues(alpha: 0.2)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded,
                  color: AppColors.primaryBlue, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'En soumettant ce formulaire, vous certifiez que les informations fournies sont exactes et vous engagez à respecter les obligations de cotisation CNPS.',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _recapRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bouton de navigation ──────────────────────────────────────────────────

  Widget _buildNavButton() {
    // L'étape 2 gère ses propres boutons dans _buildStep1()
    if (_currentStep == 1) return const SizedBox.shrink();

    final labels = ['INFORMATIONS SUIVANTES', '', 'SOUMETTRE'];
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _next,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE07B20),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
            : Text(
                labels[_currentStep],
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5),
              ),
      ),
    );
  }

  // ── Helpers de widgets ────────────────────────────────────────────────────

  Widget _sectionCard({
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête coloré
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: color,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(4)),
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
                letterSpacing: 0.3,
              ),
            ),
          ),
          // Corps
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Divider(height: 1, color: Color(0xFFE8E8E8)),
      );

  Widget _labeledWidget(String label,
      {required Widget child, bool required = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF555555),
                letterSpacing: 0.3,
              ),
              children: required
                  ? const [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red),
                      ),
                    ]
                  : [],
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Widget _cnpsField(
    String label,
    TextEditingController controller, {
    String? hint,
    bool required = true,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization caps = TextCapitalization.none,
    List<TextInputFormatter>? formatters,
  }) {
    return _labeledWidget(
      label,
      required: required,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: caps,
        inputFormatters: formatters,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hint ?? label,
          hintStyle: const TextStyle(
              color: Color(0xFFAAAAAA), fontSize: 13),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide:
                const BorderSide(color: AppColors.primaryBlue, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _revenuField() {
    return _labeledWidget(
      'REVENU MENSUEL DECLARE',
      required: true,
      child: TextField(
        controller: _revenuController,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'REVENU MENSUEL',
          hintStyle:
              const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide:
                const BorderSide(color: AppColors.primaryBlue, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _calcField(String label, String value) {
    return _labeledWidget(
      label,
      required: false,
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFCCCCCC)),
        ),
        child: Text(
          value.isEmpty ? label : value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: value.isEmpty ? FontWeight.w400 : FontWeight.w700,
            color: value.isEmpty
                ? const Color(0xFFAAAAAA)
                : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _dropdownField(
    String label,
    List<String> options,
    String? value,
    void Function(String?) onChanged,
  ) {
    return _labeledWidget(
      label,
      required: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: value != null
                ? AppColors.primaryBlue.withValues(alpha: 0.6)
                : const Color(0xFFCCCCCC),
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            hint: const Text('',
                style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13)),
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF555555)),
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
            items: options
                .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Widget _dateField(
    String label,
    DateTime? date,
    VoidCallback onTap, {
    bool required = true,
  }) {
    return _labeledWidget(
      label,
      required: required,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: date != null
                  ? AppColors.primaryBlue.withValues(alpha: 0.6)
                  : const Color(0xFFCCCCCC),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  date != null
                      ? DateFormat('dd/MM/yyyy').format(date)
                      : '',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        date != null ? FontWeight.w600 : FontWeight.w400,
                    color: date != null
                        ? AppColors.textPrimary
                        : const Color(0xFFAAAAAA),
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF555555), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
