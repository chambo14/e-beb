import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../domain/entities/infos_plateforme.dart';
import '../../../presentation/providers/plateforme_providers.dart';
import '../../../presentation/providers/repository_providers.dart';

/// Écran « Support » — aide, coordonnées de contact réelles (récupérées du
/// back-end, modifiables sans mise à jour de l'app) et signalement d'un
/// problème.
class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final infosAsync = ref.watch(infosPlateformeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Support',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: infosAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (erreur, _) => _SupportBody(infos: InfosPlateforme.defaut),
          data: (infos) => _SupportBody(infos: infos),
        ),
      ),
    );
  }
}

class _SupportBody extends StatelessWidget {
  final InfosPlateforme infos;
  const _SupportBody({required this.infos});

  Uri? get _canalPrincipal {
    if (infos.whatsapp != null && infos.whatsapp!.trim().isNotEmpty) {
      return _uriWhatsapp(infos.whatsapp!);
    }
    if (infos.emailContact != null && infos.emailContact!.trim().isNotEmpty) {
      return _uriEmail(infos.emailContact!);
    }
    if (infos.telephoneContact != null &&
        infos.telephoneContact!.trim().isNotEmpty) {
      return _uriTelephone(infos.telephoneContact!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Besoin d'aide ? ───────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryBlue, AppColors.purple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.support_agent_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Besoin d\'aide ?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Notre équipe est disponible pour répondre à vos '
                  'questions sur votre compte, vos cotisations ou votre '
                  'épargne.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _canalPrincipal == null
                        ? null
                        : () => _ouvrir(context, _canalPrincipal!),
                    icon: const Icon(Icons.headset_mic_rounded, size: 18),
                    label: const Text('Contacter le service d\'aide'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryBlue,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ─── Nous contacter ────────────────────────────────────────────
          const Text(
            'Nous contacter',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                if (infos.emailContact != null &&
                    infos.emailContact!.trim().isNotEmpty)
                  _ContactRow(
                    icon: Icons.mail_outline_rounded,
                    couleur: AppColors.primaryBlue,
                    label: 'Email',
                    valeur: infos.emailContact!,
                    onTap: () =>
                        _ouvrir(context, _uriEmail(infos.emailContact!)),
                  ),
                if (infos.telephoneContact != null &&
                    infos.telephoneContact!.trim().isNotEmpty)
                  _ContactRow(
                    icon: Icons.phone_outlined,
                    couleur: AppColors.success,
                    label: 'Téléphone',
                    valeur: infos.telephoneContact!,
                    onTap: () => _ouvrir(
                        context, _uriTelephone(infos.telephoneContact!)),
                  ),
                if (infos.whatsapp != null && infos.whatsapp!.trim().isNotEmpty)
                  _ContactRow(
                    icon: Icons.chat_outlined,
                    couleur: const Color(0xFF25D366),
                    label: 'WhatsApp',
                    valeur: infos.whatsapp!,
                    onTap: () => _ouvrir(context, _uriWhatsapp(infos.whatsapp!)),
                  ),
                if (infos.siteWeb != null && infos.siteWeb!.trim().isNotEmpty)
                  _ContactRow(
                    icon: Icons.language_rounded,
                    couleur: AppColors.purple,
                    label: 'Site web',
                    valeur: infos.siteWeb!,
                    onTap: () => _ouvrir(context, _uriSiteWeb(infos.siteWeb!)),
                    dernier: true,
                  ),
                if ((infos.emailContact == null ||
                        infos.emailContact!.trim().isEmpty) &&
                    (infos.telephoneContact == null ||
                        infos.telephoneContact!.trim().isEmpty) &&
                    (infos.whatsapp == null || infos.whatsapp!.trim().isEmpty) &&
                    (infos.siteWeb == null || infos.siteWeb!.trim().isEmpty))
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Aucune coordonnée n\'est renseignée pour le moment.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ─── Signaler un problème ──────────────────────────────────────
          const Text(
            'Autre',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _ouvrirSignalement(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.flag_outlined,
                          color: AppColors.error, size: 20),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Signaler un problème',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Décrivez un bug ou un incident rencontré',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textHint),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _ouvrir(BuildContext context, Uri uri) async {
    final ouvert = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ouvert && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible d\'ouvrir ${uri.toString()}.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _ouvrirSignalement(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _FormulaireSignalement(),
    );
  }
}

Uri _uriEmail(String email) => Uri(
      scheme: 'mailto',
      path: email.trim(),
      queryParameters: {'subject': 'Demande d\'assistance — Ebeb Finance'},
    );

Uri _uriTelephone(String telephone) =>
    Uri(scheme: 'tel', path: _versE164(telephone));

Uri _uriWhatsapp(String numero) =>
    Uri.parse('https://wa.me/${_versE164(numero).replaceAll('+', '')}');

Uri _uriSiteWeb(String site) {
  final valeur = site.trim();
  final avecSchema =
      valeur.startsWith('http://') || valeur.startsWith('https://')
          ? valeur
          : 'https://$valeur';
  return Uri.parse(avecSchema);
}

/// Numéro saisi en base au format libre → E.164 pour `tel:`/`wa.me`.
String _versE164(String saisie) {
  var chiffres = saisie.replaceAll(RegExp(r'[^\d+]'), '');
  if (chiffres.startsWith('+')) return chiffres;
  if (chiffres.startsWith('00')) return '+${chiffres.substring(2)}';
  if (chiffres.startsWith('225')) return '+$chiffres';
  return '+225$chiffres';
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final Color couleur;
  final String label;
  final String valeur;
  final VoidCallback onTap;
  final bool dernier;

  const _ContactRow({
    required this.icon,
    required this.couleur,
    required this.label,
    required this.valeur,
    required this.onTap,
    this.dernier = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: dernier
              ? const BorderRadius.vertical(bottom: Radius.circular(16))
              : BorderRadius.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: couleur.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: couleur, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        valeur,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.open_in_new_rounded,
                    color: AppColors.textHint, size: 16),
              ],
            ),
          ),
        ),
        if (!dernier) const Divider(height: 1, indent: 66, color: AppColors.border),
      ],
    );
  }
}

// ─── Signalement d'un problème ─────────────────────────────────────────────

class _FormulaireSignalement extends ConsumerStatefulWidget {
  const _FormulaireSignalement();

  @override
  ConsumerState<_FormulaireSignalement> createState() =>
      _FormulaireSignalementState();
}

class _FormulaireSignalementState
    extends ConsumerState<_FormulaireSignalement> {
  final _description = TextEditingController();
  String? _erreur;
  bool _enCours = false;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    final texte = _description.text.trim();
    if (texte.length < 5) {
      setState(() => _erreur = 'Décrivez votre problème (5 caractères minimum).');
      return;
    }

    setState(() {
      _erreur = null;
      _enCours = true;
    });

    try {
      final message =
          await ref.read(supportRepositoryProvider).signaler(texte);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = e.message;
        _enCours = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
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
            'Signaler un problème',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Décrivez ce qui ne fonctionne pas comme attendu — notre équipe '
            'sera notifiée et reviendra vers vous.',
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 12.5, height: 1.5),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _description,
            maxLines: 5,
            maxLength: 2000,
            onChanged: (_) {
              if (_erreur != null) setState(() => _erreur = null);
            },
            decoration: const InputDecoration(
              hintText: 'Ex : L\'application se ferme quand j\'essaie '
                  'd\'ajouter une cotisation.',
              alignLabelWithHint: true,
            ),
          ),
          if (_erreur != null) ...[
            const SizedBox(height: 4),
            Text(
              _erreur!,
              style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ],
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _enCours ? null : _envoyer,
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50)),
            child: _enCours
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : const Text('Envoyer le signalement'),
          ),
        ],
      ),
    );
  }
}
