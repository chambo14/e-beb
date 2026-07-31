import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/demande_inscription.dart';
import '../../../presentation/providers/auth_controller.dart';
import 'otp_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final String phoneNumber;

  const RegisterScreen({super.key, required this.phoneNumber});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _scrollController = ScrollController();
  final _picker = ImagePicker();
  int _currentStep = 0; // 0=Identification, 1=Pièces, 2=Finalisation

  // ── Étape 1 : Identité ─────────────────────────────────────────────────────
  final _cnamController = TextEditingController();
  final _cnpsController = TextEditingController();
  final _nomController = TextEditingController();
  final _prenomsController = TextEditingController();
  final _lieuNaissanceController = TextEditingController();
  final _telephoneController = TextEditingController();
  String? _genre;
  String? _situationMatrimoniale;
  DateTime? _dateNaissance;

  // ── Étape 1 : Pièce d'identité ──────────────────────────────────────────────
  String? _typeDocument;
  final _numeroDocumentController = TextEditingController();
  DateTime? _documentEtablieLe;
  DateTime? _documentExpireLe;

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
  XFile? _selfie;
  XFile? _idRecto;
  XFile? _idVerso;
  bool _infosConfirmees = false;

  /// Valeurs envoyées à l'API (le libellé affiché reste en majuscules accentuées).
  static const _sexeApi = {'MASCULIN': 'HOMME', 'FÉMININ': 'FEMME'};
  static const _situationApi = {
    'CÉLIBATAIRE': 'celibataire',
    'MARIÉ(E)': 'marie',
    'DIVORCÉ(E)': 'divorce',
    'SÉPARÉ(E)': 'separe',
    'VEUF / VEUVE': 'veuf',
  };

  static const _genreOptions = ['MASCULIN', 'FÉMININ'];
  static const _situationOptions = [
    'CÉLIBATAIRE',
    'MARIÉ(E)',
    'DIVORCÉ(E)',
    'SÉPARÉ(E)',
    'VEUF / VEUVE',
  ];
  static const _typeDocumentOptions = [
    'CNI',
    'PASSEPORT',
    'PERMIS DE CONDUIRE',
    'ATTESTATION D\'IDENTITE',
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
    _telephoneController.text = widget.phoneNumber;
  }

  @override
  void dispose() {
    _cnamController.dispose();
    _cnpsController.dispose();
    _nomController.dispose();
    _prenomsController.dispose();
    _lieuNaissanceController.dispose();
    _telephoneController.dispose();
    _numeroDocumentController.dispose();
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

  Future<void> _pickDate(_ChampDate champ) async {
    final now = DateTime.now();
    final (initial, first, last) = switch (champ) {
      _ChampDate.naissance => (
        _dateNaissance ?? DateTime(1990),
        DateTime(1920),
        now.subtract(const Duration(days: 365 * 18)),
      ),
      _ChampDate.debutActivite => (
        _dateDebutActivite ?? DateTime(now.year - 5),
        DateTime(1970),
        now,
      ),
      _ChampDate.documentEtabli => (
        _documentEtablieLe ?? DateTime(now.year - 2),
        DateTime(1970),
        now,
      ),
      // Une pièce d'identité expire nécessairement dans le futur.
      _ChampDate.documentExpire => (
        _documentExpireLe ?? DateTime(now.year + 5),
        now,
        DateTime(now.year + 30),
      ),
    };

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
      switch (champ) {
        case _ChampDate.naissance:
          _dateNaissance = picked;
        case _ChampDate.debutActivite:
          _dateDebutActivite = picked;
        case _ChampDate.documentEtabli:
          _documentEtablieLe = picked;
        case _ChampDate.documentExpire:
          _documentExpireLe = picked;
      }
    });
  }

  /// Importe une photo depuis la galerie ou l'appareil photo.
  Future<void> _choisirImage(_ChampFichier champ) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choisir dans la galerie'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    // L'API n'accepte que des images ; on limite la taille pour l'upload.
    final fichier = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (fichier == null || !mounted) return;

    setState(() {
      switch (champ) {
        case _ChampFichier.selfie:
          _selfie = fichier;
        case _ChampFichier.recto:
          _idRecto = fichier;
        case _ChampFichier.verso:
          _idVerso = fichier;
      }
    });
  }

  /// Premier champ obligatoire non renseigné de l'étape 0, `null` si complète.
  String? _champManquantEtape0() {
    if (_nomController.text.trim().isEmpty) return 'le nom';
    if (_prenomsController.text.trim().isEmpty) return 'les prénoms';
    if (_situationMatrimoniale == null) return 'la situation matrimoniale';
    if (_dateNaissance == null) return 'la date de naissance';
    if (_revenuController.text.trim().isEmpty) return 'le revenu mensuel';
    if (_categorieSocioPro == null) return 'la catégorie socioprofessionnelle';
    if (_activiteController.text.trim().isEmpty) return 'l\'activité exercée';
    if (_dateDebutActivite == null) return 'la date de début d\'activité';
    if (_villeProController.text.trim().isEmpty) return 'la ville d\'activité';
    if (_quartierProController.text.trim().isEmpty) {
      return 'le quartier d\'activité';
    }
    if (_communeProController.text.trim().isEmpty) {
      return 'la commune d\'activité';
    }
    if (_villeController.text.trim().isEmpty) return 'la ville de résidence';
    if (_communeController.text.trim().isEmpty) return 'la commune';
    if (_quartierController.text.trim().isEmpty) return 'le quartier';
    if (_telephoneController.text.replaceAll(RegExp(r'\D'), '').length < 10) {
      return 'un numéro de téléphone à 10 chiffres';
    }
    if (!_emailValide) return 'une adresse e-mail valide';
    if (_typeDocument == null) return 'le type de pièce d\'identité';
    if (_numeroDocumentController.text.trim().isEmpty) {
      return 'le numéro de la pièce';
    }
    if (_documentEtablieLe == null) return 'la date d\'établissement de la pièce';
    if (_documentExpireLe == null) return 'la date d\'expiration de la pièce';
    return null;
  }

  bool get _emailValide {
    final email = _emailController.text.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  void _next() {
    if (_currentStep == 0) {
      final manquant = _champManquantEtape0();
      if (manquant != null) {
        _showError('Veuillez renseigner $manquant.');
        return;
      }
      setState(() => _currentStep = 1);
      _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      return;
    }

    // Étape 2 : pièces, récapitulatif et soumission.
    if (_selfie == null || _idRecto == null || _idVerso == null) {
      _showError('Veuillez importer tous les documents requis.');
      return;
    }
    if (!_infosConfirmees) {
      _showError('Veuillez confirmer que les informations sont correctes.');
      return;
    }
    _submit();
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

  /// Construit le payload attendu par `POST /auth/inscription`.
  ///
  /// Les images sont lues en mémoire : sur le web, `XFile.path` est une URL
  /// blob qu'aucune API de fichier ne sait ouvrir.
  Future<DemandeInscription> _construireDemande() async {
    final telephone = Formatters.telephoneApi(_telephoneController.text);
    final recto = await _versFichierJoint(_idRecto!);
    final verso = await _versFichierJoint(_idVerso!);
    final selfie = await _versFichierJoint(_selfie!);
    return DemandeInscription(
      nom: _nomController.text.trim(),
      prenom: _prenomsController.text.trim(),
      telephone: telephone,
      email: _emailController.text.trim(),
      dateNaissance: _dateNaissance!,
      situationFamiliale: _situationApi[_situationMatrimoniale] ?? 'celibataire',
      sexe: _genre == null ? null : _sexeApi[_genre],
      lieuNaissance: _texteOuNull(_lieuNaissanceController),
      numeroCnps: _texteOuNull(_cnpsController),
      numeroCmu: _texteOuNull(_cnamController),
      ville: _villeController.text.trim(),
      quartier: _quartierController.text.trim(),
      adressePostale: _texteOuNull(_boitePostaleController),
      metier: _activiteController.text.trim(),
      profession: _activiteController.text.trim(),
      categorieProfessionnelle: _categorieSocioPro!,
      montantRevenu: _revenuMensuel,
      dateDebutActivite: _dateDebutActivite!,
      villeActivite: _villeProController.text.trim(),
      quartierActivite: _quartierProController.text.trim(),
      communeSousPrefectureActivite: _communeProController.text.trim(),
      typeDocument: _typeDocument!,
      numeroDocument: _numeroDocumentController.text.trim(),
      documentEtablieLe: _documentEtablieLe!,
      documentExpireLe: _documentExpireLe!,
      recto: recto,
      verso: verso,
      selfie: selfie,
      montantCotisationRegimeBase: _cotisationBase,
      montantCotisationRegimeComplementaire: _cotisationComplementaire,
      montantCotisationMensuelle: _cotisationMensuelle,
      montantCotisationTrimestrielle: _cotisationTrimestrielle,
    );
  }

  Future<FichierJoint> _versFichierJoint(XFile fichier) async {
    return FichierJoint(nom: fichier.name, octets: await fichier.readAsBytes());
  }

  String? _texteOuNull(TextEditingController c) {
    final valeur = c.text.trim();
    return valeur.isEmpty ? null : valeur;
  }

  Future<void> _submit() async {
    final demande = await _construireDemande();
    if (!mounted) return;

    final succes =
        await ref.read(authControllerProvider.notifier).inscrire(demande);

    if (!mounted) return;

    if (!succes) {
      _showError(
        ref.read(messageErreurAuthProvider) ??
            'L\'inscription n\'a pas abouti.',
      );
      return;
    }

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
              'Bienvenue ${_prenomsController.text} ${_nomController.text} !\nVotre dossier Ebeb Finance a bien été enregistré.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Un code de vérification à 6 chiffres vient d\'être envoyé au '
                '${Formatters.telephoneApi(_telephoneController.text)}.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.5),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => OtpScreen(
                    phoneNumber: _telephoneController.text,
                    mode: ModeOtp.inscription,
                    prenom: _prenomsController.text.trim(),
                  ),
                ),
                (route) => false,
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Vérifier mon numéro'),
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
                  if (_currentStep == 0) _buildStep0() else _buildStep1(),
                  const SizedBox(height: 20),
                  _buildNavButton(),
                  if (_currentStep > 0) ...[
                    const SizedBox(height: 10),
                    _buildRetourButton(),
                  ],
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
    const labels = ['Identification', 'Pièces & validation'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        // Un rond par étape, une ligne de liaison entre deux ronds.
        children: List.generate(labels.length * 2 - 1, (i) {
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
            _cnpsField('N° CNAM / CMU', _cnamController,
                hint: '09876543219', required: false),
            _divider(),
            _cnpsField('N° CNPS', _cnpsController,
                hint: '00345678901', required: false),
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
                () => _pickDate(_ChampDate.naissance)),
            _divider(),
            _cnpsField('LIEU DE NAISSANCE', _lieuNaissanceController,
                hint: 'EX: ADZOPÉ',
                required: false,
                caps: TextCapitalization.characters),
          ],
        ),
        const SizedBox(height: 16),
        _sectionCard(
          title: 'PIÈCE D\'IDENTITÉ',
          color: const Color(0xFF6B35A8),
          children: [
            _dropdownField('TYPE DE DOCUMENT', _typeDocumentOptions,
                _typeDocument, (v) => setState(() => _typeDocument = v)),
            _divider(),
            _cnpsField('NUMÉRO DU DOCUMENT', _numeroDocumentController,
                hint: 'EX: CI1234567890',
                caps: TextCapitalization.characters),
            _divider(),
            _dateField('ÉTABLIE LE', _documentEtablieLe,
                () => _pickDate(_ChampDate.documentEtabli)),
            _divider(),
            _dateField('EXPIRE LE', _documentExpireLe,
                () => _pickDate(_ChampDate.documentExpire)),
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
                () => _pickDate(_ChampDate.debutActivite)),
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
            // Téléphone : pré-rempli depuis l'écran précédent, modifiable si
            // l'inscription est lancée directement depuis l'accueil.
            _labeledWidget(
              'TELEPHONE',
              required: true,
              child: TextField(
                controller: _telephoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  prefixText: '🇨🇮 +225  ',
                  prefixStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                  hintText: '0700000000',
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
                    borderSide: const BorderSide(
                        color: AppColors.primaryBlue, width: 1.5),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            _divider(),
            _cnpsField('EMAIL', _emailController,
                hint: 'exemple@mail.com',
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
        // Carte principale avec ligne bleue en haut.
        // Le liseré est un enfant clippé, pas un côté de bordure : Flutter
        // refuse de peindre un borderRadius sur une bordure aux couleurs non
        // uniformes.
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 3, color: AppColors.primaryBlue),
              Padding(
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
                fichier: _selfie,
                onTap: () => _choisirImage(_ChampFichier.selfie),
              ),
              const SizedBox(height: 16),

              // Document d'identité recto
              _fileUploadField(
                label: 'Document d\'identité recto',
                fichier: _idRecto,
                onTap: () => _choisirImage(_ChampFichier.recto),
              ),
              const SizedBox(height: 16),

              // Document d'identité verso
              _fileUploadField(
                label: 'Document d\'identité verso',
                fichier: _idVerso,
                onTap: () => _choisirImage(_ChampFichier.verso),
              ),
                  ],
                ),
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

        const SizedBox(height: 16),

        // Récapitulatif avant soumission
        _buildRecapitulatif(),

      ],
    );
  }

  Widget _fileUploadField({
    required String label,
    required XFile? fichier,
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
            if (fichier != null) ...[
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  fichier.name,
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

  // ── Récapitulatif (affiché en bas de l'étape 2, avant soumission) ─────────

  Widget _buildRecapitulatif() {
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
            _recapRow('PIÈCE D\'IDENTITÉ',
                '${_typeDocument ?? '-'} · ${_numeroDocumentController.text}'),
            _recapRow('EMAIL', _emailController.text),
            _recapRow(
                'TÉLÉPHONE', Formatters.telephoneApi(_telephoneController.text)),
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

  /// Retour à l'étape précédente — action secondaire, sous le bouton principal.
  Widget _buildRetourButton() {
    final enCours = ref.watch(authControllerProvider).isLoading;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: enCours ? null : _prev,
        icon: const Icon(Icons.keyboard_double_arrow_left_rounded,
            color: Color(0xFF1A3A6B), size: 18),
        label: const Text(
          'RETOUR',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A3A6B),
            letterSpacing: 0.5,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF1A3A6B), width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }

  Widget _buildNavButton() {
    final enCours = ref.watch(authControllerProvider).isLoading;
    const labels = ['INFORMATIONS SUIVANTES', 'SOUMETTRE MON INSCRIPTION'];
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enCours ? null : _next,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE07B20),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          elevation: 0,
        ),
        child: enCours
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

/// Champs date du formulaire, chacun avec sa plage autorisée.
enum _ChampDate { naissance, debutActivite, documentEtabli, documentExpire }

/// Pièces jointes attendues par `POST /auth/inscription`.
enum _ChampFichier { selfie, recto, verso }
