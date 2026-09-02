import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/compte_mobile_money.dart';
import '../../../presentation/providers/mobile_money_providers.dart';

/// Comptes mobile money rattachés à l'utilisateur — un seul peut être
/// principal ; chacun génère automatiquement son propre QR code, repris tel
/// quel (jamais recalculé côté mobile) sur la carrousel de l'accueil, qui
/// observe le même [comptesMobileMoneyProvider].
class ComptesMobileMoneyScreen extends ConsumerWidget {
  const ComptesMobileMoneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comptesAsync = ref.watch(comptesMobileMoneyProvider);

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
          'Comptes',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: comptesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (erreur, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded,
                    color: AppColors.error, size: 34),
                const SizedBox(height: 12),
                Text(
                  erreur is ApiException
                      ? erreur.message
                      : 'Impossible de charger vos comptes.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.5),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(comptesMobileMoneyProvider.notifier).recharger(),
                  style:
                      ElevatedButton.styleFrom(minimumSize: const Size(160, 44)),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (liste) => RefreshIndicator(
          onRefresh: () =>
              ref.read(comptesMobileMoneyProvider.notifier).recharger(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (liste.isEmpty)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                    child: const Column(
                      children: [
                        Icon(Icons.account_balance_wallet_outlined,
                            color: AppColors.textHint, size: 34),
                        SizedBox(height: 12),
                        Text(
                          'Aucun compte associé',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Ajoutez un compte mobile money pour recevoir vos '
                          'paiements et générer son QR code.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...liste.map(
                    (compte) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CompteTile(compte: compte),
                    ),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _ouvrirFormulaireAjout(context, ref),
                  icon: const Icon(Icons.add_rounded,
                      color: AppColors.primaryBlue, size: 18),
                  label: const Text(
                    'Ajouter un compte',
                    style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    side: const BorderSide(
                        color: AppColors.primaryBlue, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _ouvrirFormulaireAjout(BuildContext context, WidgetRef ref) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _FormulaireAjoutCompte(),
    );
  }
}

class _CompteTile extends ConsumerWidget {
  final CompteMobileMoney compte;
  const _CompteTile({required this.compte});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enCours = ref.watch(comptesMobileMoneyProvider).isLoading;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: compte.estPrincipal
              ? AppColors.primaryBlue.withValues(alpha: 0.4)
              : AppColors.border,
          width: compte.estPrincipal ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _Logo(moyen: compte.moyenPaiement, taille: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  compte.operateur,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  Formatters.telephoneAffichage(compte.numeroCompte),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12.5),
                ),
                if (compte.estPrincipal) ...[
                  const SizedBox(height: 3),
                  const Text(
                    'Compte principal',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Checkbox(
            value: compte.estPrincipal,
            // Un seul compte peut être principal : on ne peut que le
            // *définir* (cocher un autre compte), jamais le décocher
            // directement — retirer le statut se fait en désignant un autre
            // compte comme principal.
            onChanged: enCours || compte.estPrincipal
                ? null
                : (_) async {
                    final succes = await ref
                        .read(comptesMobileMoneyProvider.notifier)
                        .definirPrincipal(compte.id);
                    if (!context.mounted) return;
                    if (!succes) {
                      final erreur =
                          ref.read(comptesMobileMoneyProvider).error;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            erreur is ApiException
                                ? erreur.message
                                : 'Impossible de définir ce compte comme principal.',
                          ),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    }
                  },
            activeColor: AppColors.primaryBlue,
          ),
        ],
      ),
    );
  }
}

/// Vignette d'un moyen de paiement : logo réel (`logo_url`) s'il est
/// configuré en base, sinon une icône générique teintée avec la couleur
/// configurée (`couleur`) — jamais de logo ou de couleur codés en dur par
/// opérateur.
class _Logo extends StatelessWidget {
  final MoyenPaiement? moyen;
  final double taille;

  const _Logo({required this.moyen, required this.taille});

  static Color? _versCouleur(String? hex) {
    if (hex == null) return null;
    final nettoye = hex.trim().replaceFirst('#', '');
    if (nettoye.length != 6) return null;
    final valeur = int.tryParse(nettoye, radix: 16);
    return valeur == null ? null : Color(0xFF000000 | valeur);
  }

  @override
  Widget build(BuildContext context) {
    final url = moyen?.logoUrl;
    final teinte = _versCouleur(moyen?.couleur) ?? AppColors.primaryBlue;
    return Container(
      width: taille,
      height: taille,
      decoration: BoxDecoration(
        color: teinte.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(taille * 0.3),
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null || url.isEmpty
          ? Icon(Icons.account_balance_wallet_rounded,
              color: teinte, size: taille * 0.5)
          : Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.account_balance_wallet_rounded,
                  color: teinte,
                  size: taille * 0.5),
            ),
    );
  }
}

// ─── Formulaire d'ajout ────────────────────────────────────────────────────

class _FormulaireAjoutCompte extends ConsumerStatefulWidget {
  const _FormulaireAjoutCompte();

  @override
  ConsumerState<_FormulaireAjoutCompte> createState() =>
      _FormulaireAjoutCompteState();
}

class _FormulaireAjoutCompteState
    extends ConsumerState<_FormulaireAjoutCompte> {
  final _numero = TextEditingController();
  String? _moyenSelectionneId;
  String? _erreur;

  @override
  void dispose() {
    _numero.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (_moyenSelectionneId == null) {
      setState(() => _erreur = 'Choisissez un moyen de paiement.');
      return;
    }
    final numero = _numero.text.trim();
    if (numero.isEmpty) {
      setState(() => _erreur = 'Indiquez le numéro de téléphone associé.');
      return;
    }

    setState(() => _erreur = null);

    final succes = await ref.read(comptesMobileMoneyProvider.notifier).ajouter(
          moyenPaiementId: _moyenSelectionneId!,
          numeroCompte: Formatters.telephoneApi(numero),
        );

    if (!mounted) return;

    if (!succes) {
      final erreur = ref.read(comptesMobileMoneyProvider).error;
      setState(
        () => _erreur = erreur is ApiException
            ? erreur.message
            : 'L\'enregistrement a échoué.',
      );
      return;
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Compte ajouté, QR code généré.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enCours = ref.watch(comptesMobileMoneyProvider).isLoading;
    final moyensAsync = ref.watch(moyensPaiementProvider);
    final comptesExistants =
        ref.watch(comptesMobileMoneyProvider).valueOrNull ?? const [];
    final idsDejaUtilises =
        comptesExistants.map((c) => c.moyenPaiement?.id).whereType<String>().toSet();

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
              'Ajouter un compte',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 20),
            const Text(
              'Moyen de paiement',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            moyensAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (erreur, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      erreur is ApiException
                          ? erreur.message
                          : 'Impossible de charger les moyens de paiement.',
                      style: const TextStyle(
                          color: AppColors.error, fontSize: 13),
                    ),
                    TextButton(
                      onPressed: () => ref.invalidate(moyensPaiementProvider),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
              data: (tousLesMoyens) {
                final disponibles = tousLesMoyens
                    .where((m) => !idsDejaUtilises.contains(m.id))
                    .toList(growable: false);

                if (disponibles.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Vous avez déjà un compte pour tous les moyens de '
                      'paiement disponibles.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  );
                }

                return Column(
                  children: disponibles.map((m) {
                    final selectionne = m.id == _moyenSelectionneId;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _moyenSelectionneId = m.id;
                          _erreur = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selectionne
                                  ? AppColors.primaryBlue
                                  : AppColors.border,
                              width: selectionne ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              _Logo(moyen: m, taille: 36),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  m.libelle,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (selectionne)
                                const Icon(Icons.check_circle_rounded,
                                    color: AppColors.primaryBlue, size: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Numéro de téléphone associé',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _numero,
              keyboardType: TextInputType.phone,
              onChanged: (_) {
                if (_erreur != null) setState(() => _erreur = null);
              },
              decoration: const InputDecoration(hintText: '07 09 41 55 35'),
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
                  : const Text('Ajouter le compte'),
            ),
          ],
        ),
      ),
    );
  }
}
