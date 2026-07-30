import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/objectif_epargne.dart';
import '../../../domain/entities/type_cotisation.dart';
import '../../../presentation/providers/epargne_providers.dart';

class EpargneTab extends ConsumerWidget {
  const EpargneTab({super.key});

  /// Palette tournante : l'API ne fournit pas de couleur par objectif.
  static const _couleurs = [
    AppColors.primaryBlue,
    Color(0xFF2E9E5B),
    AppColors.orange,
    AppColors.purple,
  ];

  /// Pictogramme déduit du libellé de l'objectif.
  static String _emoji(String libelle) {
    final l = libelle.toLowerCase();
    if (l.contains('logement') || l.contains('maison') || l.contains('terrain')) {
      return '🏠';
    }
    if (l.contains('scolar') || l.contains('école') || l.contains('étude')) {
      return '🎓';
    }
    if (l.contains('santé') || l.contains('maladie')) return '🏥';
    if (l.contains('sécurité') || l.contains('urgence')) return '🛡️';
    if (l.contains('voyage')) return '✈️';
    return '💼';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = NumberFormat('#,##0', 'fr_FR');
    final objectifs = ref.watch(objectifsEpargneProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Mon épargne',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded,
                color: AppColors.primaryBlue, size: 26),
            onPressed: () => _ouvrirFormulaire(context, ref),
          ),
        ],
      ),
      body: objectifs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (erreur, _) => _buildErreur(context, ref, erreur),
        data: (liste) => RefreshIndicator(
          onRefresh: () =>
              ref.read(objectifsEpargneProvider.notifier).recharger(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTotalCard(fmt, ref.watch(totalEpargneProvider)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Mes objectifs',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      liste.length > 1
                          ? '${liste.length} objectifs'
                          : '${liste.length} objectif',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (liste.isEmpty)
                  _buildVide()
                else
                  ...liste.asMap().entries.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _GoalCard(
                            objectif: e.value,
                            couleur: _couleurs[e.key % _couleurs.length],
                            emoji: _emoji(e.value.libelle),
                            fmt: fmt,
                            onModifier: () => _ouvrirFormulaire(
                              context,
                              ref,
                              existant: e.value,
                            ),
                            onSupprimer: () =>
                                _confirmerSuppression(context, ref, e.value),
                          ),
                        ),
                      ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _ouvrirFormulaire(context, ref),
                  icon: const Icon(Icons.add_rounded,
                      color: AppColors.primaryBlue, size: 18),
                  label: const Text(
                    'Ajouter un objectif',
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

  Widget _buildVide() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: const Column(
        children: [
          Icon(Icons.savings_outlined, color: AppColors.textHint, size: 34),
          SizedBox(height: 12),
          Text(
            'Aucun objectif d\'épargne',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Créez un objectif : une part de chaque paiement reçu y sera '
            'automatiquement versée.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErreur(BuildContext context, WidgetRef ref, Object erreur) {
    final message = erreur is ApiException
        ? erreur.message
        : 'Impossible de charger vos objectifs d\'épargne.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                color: AppColors.error, size: 34),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () =>
                  ref.read(objectifsEpargneProvider.notifier).recharger(),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(160, 44),
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard(NumberFormat fmt, double total) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E9E5B), Color(0xFF1A7540)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E9E5B).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total épargné',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  fmt.format(total),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text(
                  'FCFA',
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.15),
            ),
            child: const Icon(Icons.savings_rounded,
                color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }

  Future<void> _ouvrirFormulaire(
    BuildContext context,
    WidgetRef ref, {
    ObjectifEpargne? existant,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FormulaireObjectif(existant: existant),
    );
  }

  Future<void> _confirmerSuppression(
    BuildContext context,
    WidgetRef ref,
    ObjectifEpargne objectif,
  ) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer l\'objectif'),
        content: Text(
          'L\'objectif « ${objectif.libelle} » sera définitivement supprimé, '
          'ainsi que la règle de versement associée.',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              minimumSize: const Size(120, 44),
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    final succes = await ref
        .read(objectifsEpargneProvider.notifier)
        .supprimer(objectif.id);

    if (!context.mounted) return;
    _afficherResultat(
      context,
      ref,
      succes,
      messageSucces: 'Objectif supprimé.',
    );
  }
}

/// Feedback commun aux mutations d'objectifs.
void _afficherResultat(
  BuildContext context,
  WidgetRef ref,
  bool succes, {
  required String messageSucces,
}) {
  final erreur = ref.read(objectifsEpargneProvider).error;
  final message = succes
      ? messageSucces
      : (erreur is ApiException
            ? erreur.message
            : 'L\'opération n\'a pas abouti.');

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: succes ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

// ─── Formulaire création / modification ───────────────────────────────────────

class _FormulaireObjectif extends ConsumerStatefulWidget {
  final ObjectifEpargne? existant;

  const _FormulaireObjectif({this.existant});

  @override
  ConsumerState<_FormulaireObjectif> createState() =>
      _FormulaireObjectifState();
}

class _FormulaireObjectifState extends ConsumerState<_FormulaireObjectif> {
  late final TextEditingController _libelle;
  late final TextEditingController _montantCible;
  late final TextEditingController _valeur;
  late TypeCalcul _typeCalcul;
  late DateTime? _dateLimite;
  bool _estActif = true;
  String? _erreur;

  bool get _estModification => widget.existant != null;

  @override
  void initState() {
    super.initState();
    final o = widget.existant;
    _libelle = TextEditingController(text: o?.libelle ?? '');
    _montantCible = TextEditingController(
      text: o == null ? '' : o.montantCible.round().toString(),
    );
    _valeur = TextEditingController(
      text: o == null ? '' : o.valeur.round().toString(),
    );
    _typeCalcul = o?.typeCalcul ?? TypeCalcul.fixe;
    _dateLimite = o?.dateLimite;
    _estActif = o?.estActif ?? true;
  }

  @override
  void dispose() {
    _libelle.dispose();
    _montantCible.dispose();
    _valeur.dispose();
    super.dispose();
  }

  Future<void> _choisirDate() async {
    final maintenant = DateTime.now();
    final choisie = await showDatePicker(
      context: context,
      initialDate: _dateLimite ?? DateTime(maintenant.year + 1),
      firstDate: maintenant,
      lastDate: DateTime(maintenant.year + 30),
      locale: const Locale('fr'),
    );
    if (choisie != null) setState(() => _dateLimite = choisie);
  }

  Future<void> _enregistrer() async {
    final libelle = _libelle.text.trim();
    final cible = double.tryParse(_montantCible.text.replaceAll(' ', '')) ?? 0;
    final valeur = double.tryParse(_valeur.text.replaceAll(' ', '')) ?? 0;

    if (libelle.isEmpty) {
      setState(() => _erreur = 'Donnez un nom à votre objectif.');
      return;
    }
    if (cible <= 0) {
      setState(() => _erreur = 'Le montant cible doit être supérieur à 0.');
      return;
    }
    if (_dateLimite == null) {
      setState(() => _erreur = 'Choisissez une date limite.');
      return;
    }
    if (valeur <= 0) {
      setState(() => _erreur = 'Indiquez le montant ou le pourcentage prélevé.');
      return;
    }
    if (_typeCalcul == TypeCalcul.pourcentage && valeur > 100) {
      setState(() => _erreur = 'Un pourcentage ne peut pas dépasser 100.');
      return;
    }

    setState(() => _erreur = null);

    final controller = ref.read(objectifsEpargneProvider.notifier);
    final succes = _estModification
        ? await controller.modifier(
            id: widget.existant!.id,
            libelle: libelle,
            montantCible: cible,
            dateLimite: _dateLimite!,
            typeCalcul: _typeCalcul,
            valeur: valeur,
            estActif: _estActif,
          )
        : await controller.ajouter(
            libelle: libelle,
            montantCible: cible,
            dateLimite: _dateLimite!,
            typeCalcul: _typeCalcul,
            valeur: valeur,
            estActif: _estActif,
          );

    if (!mounted) return;

    if (!succes) {
      final erreur = ref.read(objectifsEpargneProvider).error;
      setState(
        () => _erreur = erreur is ApiException
            ? erreur.message
            : 'L\'enregistrement a échoué.',
      );
      return;
    }

    Navigator.pop(context);
    _afficherResultat(
      context,
      ref,
      true,
      messageSucces: _estModification
          ? 'Objectif mis à jour.'
          : 'Objectif créé.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final enCours = ref.watch(objectifsEpargneProvider).isLoading;

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
            Text(
              _estModification
                  ? 'Modifier l\'objectif'
                  : 'Nouvel objectif d\'épargne',
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 20),
            _champ(
              label: 'Nom de l\'objectif',
              controller: _libelle,
              hint: 'Ex : Épargne logement',
            ),
            const SizedBox(height: 16),
            _champ(
              label: 'Montant cible (FCFA)',
              controller: _montantCible,
              hint: '500000',
              chiffresUniquement: true,
            ),
            const SizedBox(height: 16),
            const Text(
              'Date limite',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _choisirDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _dateLimite == null
                            ? 'Choisir une date'
                            : Formatters.dateCourte(_dateLimite!),
                        style: TextStyle(
                          color: _dateLimite == null
                              ? AppColors.textHint
                              : AppColors.textPrimary,
                          fontWeight: _dateLimite == null
                              ? FontWeight.w400
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(Icons.calendar_today_rounded,
                        size: 18, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Prélèvement sur chaque paiement reçu',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            SegmentedButton<TypeCalcul>(
              segments: const [
                ButtonSegment(
                  value: TypeCalcul.fixe,
                  label: Text('Montant fixe'),
                ),
                ButtonSegment(
                  value: TypeCalcul.pourcentage,
                  label: Text('Pourcentage'),
                ),
              ],
              selected: {_typeCalcul},
              onSelectionChanged: (s) => setState(() => _typeCalcul = s.first),
            ),
            const SizedBox(height: 12),
            _champ(
              label: _typeCalcul == TypeCalcul.pourcentage
                  ? 'Pourcentage prélevé (%)'
                  : 'Montant prélevé (FCFA)',
              controller: _valeur,
              hint: _typeCalcul == TypeCalcul.pourcentage ? '10' : '2000',
              chiffresUniquement: true,
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _estActif,
              onChanged: (v) => setState(() => _estActif = v),
              title: const Text(
                'Activer le prélèvement automatique',
                style: TextStyle(fontSize: 14),
              ),
            ),
            if (_erreur != null) ...[
              const SizedBox(height: 8),
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
                  : Text(_estModification ? 'Enregistrer' : 'Créer l\'objectif'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _champ({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool chiffresUniquement = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType:
              chiffresUniquement ? TextInputType.number : TextInputType.text,
          inputFormatters:
              chiffresUniquement ? [FilteringTextInputFormatter.digitsOnly] : null,
          onChanged: (_) {
            if (_erreur != null) setState(() => _erreur = null);
          },
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

// ─── Carte d'un objectif ──────────────────────────────────────────────────────

class _GoalCard extends StatelessWidget {
  final ObjectifEpargne objectif;
  final Color couleur;
  final String emoji;
  final NumberFormat fmt;
  final VoidCallback onModifier;
  final VoidCallback onSupprimer;

  const _GoalCard({
    required this.objectif,
    required this.couleur,
    required this.emoji,
    required this.fmt,
    required this.onModifier,
    required this.onSupprimer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: couleur.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      objectif.libelle,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Objectif : ${fmt.format(objectif.montantCible)} FCFA',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fmt.format(objectif.montantEpargne),
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: couleur),
                  ),
                  Text(
                    '${(objectif.progression * 100).round()}%',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    color: AppColors.textSecondary, size: 20),
                onSelected: (action) =>
                    action == 'modifier' ? onModifier() : onSupprimer(),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'modifier', child: Text('Modifier')),
                  PopupMenuItem(value: 'supprimer', child: Text('Supprimer')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: objectif.progression,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(couleur),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Règle de versement configurée pour cet objectif.
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      objectif.estActif
                          ? Icons.autorenew_rounded
                          : Icons.pause_circle_outline_rounded,
                      size: 13,
                      color: objectif.estActif
                          ? AppColors.success
                          : AppColors.textHint,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        objectif.typeCalcul == TypeCalcul.pourcentage
                            ? '${objectif.valeur.round()} % par paiement'
                            : '${fmt.format(objectif.valeur)} FCFA par paiement',
                        style: const TextStyle(
                            color: AppColors.textHint, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (objectif.estAtteint)
                const Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: AppColors.success, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Objectif atteint !',
                      style: TextStyle(
                          color: AppColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                )
              else
                Text(
                  'Reste ${fmt.format(objectif.reste)} FCFA',
                  style: const TextStyle(
                      color: AppColors.textHint, fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
