import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../domain/entities/demande_inscription.dart';
import '../../../presentation/providers/session_provider.dart';
import '../../../presentation/providers/utilisateur_providers.dart';

/// Édition des champs modifiables du profil
/// (`PATCH /espace-utilisateur/profil`).
class ProfilEditSheet extends ConsumerStatefulWidget {
  const ProfilEditSheet({super.key});

  @override
  ConsumerState<ProfilEditSheet> createState() => _ProfilEditSheetState();
}

class _ProfilEditSheetState extends ConsumerState<ProfilEditSheet> {
  late final TextEditingController _email;
  late final TextEditingController _ville;
  late final TextEditingController _quartier;
  late final TextEditingController _nombreEnfants;
  String? _situation;
  String? _erreur;

  static const _situations = [
    'celibataire',
    'marie',
    'divorce',
    'separe',
    'veuf',
  ];

  static const _libellesSituation = {
    'celibataire': 'Célibataire',
    'marie': 'Marié(e)',
    'divorce': 'Divorcé(e)',
    'separe': 'Séparé(e)',
    'veuf': 'Veuf / Veuve',
  };

  @override
  void initState() {
    super.initState();
    final user = ref.read(utilisateurCourantProvider);
    _email = TextEditingController(text: user?.email ?? '');
    _ville = TextEditingController(text: user?.ville ?? '');
    _quartier = TextEditingController(text: user?.quartier ?? '');
    _nombreEnfants = TextEditingController(
      text: user?.nombreEnfants?.toString() ?? '',
    );
    final situation = user?.situationFamiliale?.toLowerCase();
    _situation = _situations.contains(situation) ? situation : null;
  }

  @override
  void dispose() {
    _email.dispose();
    _ville.dispose();
    _quartier.dispose();
    _nombreEnfants.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    final email = _email.text.trim();
    if (email.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _erreur = 'Adresse e-mail invalide.');
      return;
    }

    setState(() => _erreur = null);

    final mise = MiseAJourProfil(
      email: email.isEmpty ? null : email,
      ville: _ville.text.trim().isEmpty ? null : _ville.text.trim(),
      quartier: _quartier.text.trim().isEmpty ? null : _quartier.text.trim(),
      situationFamiliale: _situation,
      nombreEnfants: int.tryParse(_nombreEnfants.text.trim()),
    );

    final succes =
        await ref.read(profilControllerProvider.notifier).mettreAJour(mise);

    if (!mounted) return;

    if (!succes) {
      final erreur = ref.read(profilControllerProvider).error;
      setState(
        () => _erreur = erreur is ApiException
            ? erreur.message
            : 'La mise à jour a échoué.',
      );
      return;
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Profil mis à jour.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enCours = ref.watch(profilControllerProvider).isLoading;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Mes informations',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _ville,
              decoration: const InputDecoration(labelText: 'Ville'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _quartier,
              decoration: const InputDecoration(labelText: 'Quartier'),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _situation,
              decoration:
                  const InputDecoration(labelText: 'Situation familiale'),
              items: [
                for (final s in _situations)
                  DropdownMenuItem(
                    value: s,
                    child: Text(_libellesSituation[s]!),
                  ),
              ],
              onChanged: (v) => setState(() => _situation = v),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _nombreEnfants,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Nombre d\'enfants'),
            ),
            if (_erreur != null) ...[
              const SizedBox(height: 12),
              Text(
                _erreur!,
                style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: enCours ? null : _enregistrer,
              child: enCours
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Changement de code PIN (`PATCH /espace-utilisateur/code-pin`).
class CodePinEditSheet extends ConsumerStatefulWidget {
  const CodePinEditSheet({super.key});

  @override
  ConsumerState<CodePinEditSheet> createState() => _CodePinEditSheetState();
}

class _CodePinEditSheetState extends ConsumerState<CodePinEditSheet> {
  final _ancien = TextEditingController();
  final _nouveau = TextEditingController();
  final _confirmation = TextEditingController();
  String? _erreur;

  @override
  void dispose() {
    _ancien.dispose();
    _nouveau.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (_ancien.text.length != 6) {
      setState(() => _erreur = 'Saisissez votre code PIN actuel (6 chiffres).');
      return;
    }
    if (_nouveau.text.length != 6) {
      setState(() => _erreur = 'Le nouveau code doit comporter 6 chiffres.');
      return;
    }
    if (_nouveau.text != _confirmation.text) {
      setState(() => _erreur = 'Les deux nouveaux codes ne correspondent pas.');
      return;
    }

    setState(() => _erreur = null);

    final succes = await ref
        .read(profilControllerProvider.notifier)
        .modifierCodePin(
          ancienCodePin: _ancien.text,
          nouveauCodePin: _nouveau.text,
        );

    if (!mounted) return;

    if (!succes) {
      final erreur = ref.read(profilControllerProvider).error;
      setState(
        () => _erreur = erreur is ApiException
            ? erreur.message
            : 'La modification a échoué.',
      );
      return;
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Code PIN modifié.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enCours = ref.watch(profilControllerProvider).isLoading;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Modifier mon code PIN',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 20),
            _champPin('Code PIN actuel', _ancien),
            const SizedBox(height: 14),
            _champPin('Nouveau code PIN', _nouveau),
            const SizedBox(height: 14),
            _champPin('Confirmez le nouveau code', _confirmation),
            if (_erreur != null) ...[
              const SizedBox(height: 12),
              Text(
                _erreur!,
                style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: enCours ? null : _enregistrer,
              child: enCours
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _champPin(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      obscureText: true,
      maxLength: 6,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (_) {
        if (_erreur != null) setState(() => _erreur = null);
      },
      style: const TextStyle(letterSpacing: 6, fontWeight: FontWeight.w700),
      decoration: InputDecoration(labelText: label, counterText: ''),
    );
  }
}
