import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../domain/entities/recapitulatif.dart';
import '../../../domain/entities/type_cotisation.dart';
import '../../../presentation/providers/cotisation_providers.dart';
import '../../../presentation/providers/session_provider.dart';
import '../../../presentation/providers/utilisateur_providers.dart';
import '../screens/recapitulatif_par_type_screen.dart';

class CotisationsTab extends ConsumerWidget {
  const CotisationsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = NumberFormat('#,##0', 'fr_FR');
    final cotisations = ref.watch(cotisationsControllerProvider);
    final recap = ref.watch(recapitulatifProvider);
    final compteActif = ref.watch(utilisateurCourantProvider)?.estActif ?? true;

    // Le dossier est « à jour » quand le versé couvre la cible du mois.
    final aJour = recap.valueOrNull?.let(
          (r) => r.totalCibleMensuel <= 0 || r.resteMensuel <= 0,
        ) ??
        true;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Mes cotisations',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _StatusPill(aJour: aJour),
          ),
        ],
      ),
      body: cotisations.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (erreur, _) => _buildErreur(ref, erreur),
        data: (types) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(recapitulatifProvider);
            await ref.read(cotisationsControllerProvider.notifier).recharger();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusBanner(aJour, recap.valueOrNull, fmt),
                const SizedBox(height: 24),
                const _SectionTitle('Cotisations sociales obligatoires'),
                const SizedBox(height: 12),
                ..._cartes(
                  context,
                  ref,
                  ref.watch(cotisationsPlateformeProvider),
                  fmt,
                  messageVide:
                      'Aucune cotisation proposée par la plateforme pour le moment.',
                ),
                const SizedBox(height: 24),
                const _SectionTitle('Mes cotisations personnalisées'),
                const SizedBox(height: 12),
                ..._cartes(
                  context,
                  ref,
                  ref.watch(cotisationsPersonnaliseesProvider),
                  fmt,
                  messageVide:
                      'Ajoutez vos assurances privées ou toute autre cotisation '
                      'à prélever automatiquement.',
                  personnalisees: true,
                ),
                const SizedBox(height: 24),
                if (recap.valueOrNull != null)
                  _buildRecapMensuel(context, ref, recap.value!, fmt),
                const SizedBox(height: 24),
                if (!compteActif) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.orange.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: AppColors.orange, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'L\'ajout de nouvelles cotisations sera possible '
                            'une fois votre compte activé.',
                            style: TextStyle(
                                fontSize: 11.5, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                OutlinedButton.icon(
                  onPressed: compteActif
                      ? () => _ouvrirFormulaireCotisation(context, ref)
                      : null,
                  icon: Icon(
                    compteActif ? Icons.add_rounded : Icons.lock_outline_rounded,
                    color: compteActif
                        ? AppColors.primaryBlue
                        : AppColors.textHint,
                    size: 18,
                  ),
                  label: Text(
                    'Ajouter une cotisation',
                    style: TextStyle(
                        color: compteActif
                            ? AppColors.primaryBlue
                            : AppColors.textHint,
                        fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    side: BorderSide(
                        color: compteActif
                            ? AppColors.primaryBlue
                            : AppColors.border,
                        width: 1.5),
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

  List<Widget> _cartes(
    BuildContext context,
    WidgetRef ref,
    List<TypeCotisation> types,
    NumberFormat fmt, {
    required String messageVide,
    bool personnalisees = false,
  }) {
    if (types.isEmpty) {
      return [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          child: Text(
            messageVide,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
        ),
      ];
    }

    return [
      for (final type in types) ...[
        _CotisationCard(
          type: type,
          fmt: fmt,
          modifiable: personnalisees,
          onConfigurer: () => _ouvrirReglePrelevement(context, ref, type),
          onModifier: personnalisees
              ? () => _ouvrirFormulaireCotisation(context, ref, existant: type)
              : null,
          onSupprimer: personnalisees
              ? () => _confirmerSuppression(context, ref, type)
              : null,
          onBasculer: (actif) async {
            final succes = await ref
                .read(cotisationsControllerProvider.notifier)
                .basculerActivation(type, actif);
            if (!context.mounted) return;
            _feedback(context, ref, succes,
                succesMessage: actif
                    ? 'Prélèvement activé.'
                    : 'Prélèvement désactivé.');
          },
        ),
        const SizedBox(height: 12),
      ],
    ];
  }

  Widget _buildErreur(WidgetRef ref, Object erreur) {
    final message = erreur is ApiException
        ? erreur.message
        : 'Impossible de charger vos cotisations.';
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
                  ref.read(cotisationsControllerProvider.notifier).recharger(),
              style: ElevatedButton.styleFrom(minimumSize: const Size(160, 44)),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(
    bool aJour,
    Recapitulatif? recap,
    NumberFormat fmt,
  ) {
    final reste = recap?.resteMensuel ?? 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: aJour
              ? [const Color(0xFF2E9E5B), const Color(0xFF1A7540)]
              : [AppColors.red, const Color(0xFF8B1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            child: Icon(
              aJour ? Icons.verified_rounded : Icons.warning_amber_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  aJour
                      ? 'Vos cotisations sont à jour'
                      : 'Cotisations incomplètes',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  aJour
                      ? 'Vos prélèvements automatiques couvrent votre objectif du mois.'
                      : 'Il reste ${fmt.format(reste)} FCFA à verser ce mois-ci.',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecapMensuel(
    BuildContext context,
    WidgetRef ref,
    Recapitulatif recap,
    NumberFormat fmt,
  ) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Récapitulatif du mois',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const RecapitulatifParTypeScreen(),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_month_rounded,
                          color: AppColors.primaryBlue, size: 15),
                      SizedBox(width: 5),
                      Text(
                        'Par type',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...recap.ventilationCotisations.map(
            (ligne) => _RecapRow(
              label: ligne.libelle,
              value: '${fmt.format(ligne.montant)} FCFA',
              isHighlight: false,
            ),
          ),
          if (recap.ventilationCotisations.isNotEmpty)
            const Divider(height: 24, color: AppColors.border),
          _RecapRow(
            label: 'Objectif du mois',
            value: '${fmt.format(recap.totalObjectifMensuel)} FCFA',
            isHighlight: false,
          ),
          _RecapRow(
            label: 'Déjà versé',
            value: '${fmt.format(recap.totalCotisations)} FCFA',
            isHighlight: true,
          ),
          _RecapRow(
            label: 'Reste à cotiser',
            value: '${fmt.format(recap.resteACotiser)} FCFA',
            isHighlight: false,
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: recap.progressionCotisations,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
            ),
          ),
        ],
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _ouvrirReglePrelevement(
    BuildContext context,
    WidgetRef ref,
    TypeCotisation type,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FormulaireRegle(type: type),
    );
  }

  Future<void> _ouvrirFormulaireCotisation(
    BuildContext context,
    WidgetRef ref, {
    TypeCotisation? existant,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FormulaireCotisation(existant: existant),
    );
  }

  Future<void> _confirmerSuppression(
    BuildContext context,
    WidgetRef ref,
    TypeCotisation type,
  ) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer la cotisation'),
        content: Text(
          '« ${type.libelle} » et sa règle de prélèvement seront supprimées.',
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
        .read(cotisationsControllerProvider.notifier)
        .supprimerTypePersonnalise(type.id);

    if (!context.mounted) return;
    _feedback(context, ref, succes, succesMessage: 'Cotisation supprimée.');
  }
}

/// Feedback commun aux mutations de cotisations.
void _feedback(
  BuildContext context,
  WidgetRef ref,
  bool succes, {
  required String succesMessage,
}) {
  final erreur = ref.read(cotisationsControllerProvider).error;
  final message = succes
      ? succesMessage
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

// ─── Carte d'une cotisation ───────────────────────────────────────────────────

class _CotisationCard extends StatelessWidget {
  final TypeCotisation type;
  final NumberFormat fmt;
  final bool modifiable;
  final VoidCallback onConfigurer;
  final VoidCallback? onModifier;
  final VoidCallback? onSupprimer;
  final ValueChanged<bool> onBasculer;

  const _CotisationCard({
    required this.type,
    required this.fmt,
    required this.modifiable,
    required this.onConfigurer,
    required this.onBasculer,
    this.onModifier,
    this.onSupprimer,
  });

  /// Pictogramme déduit du code ou du libellé du type de cotisation.
  String get _emoji {
    final cle = '${type.code ?? ''} ${type.libelle}'.toUpperCase();
    if (cle.contains('CNPS') || cle.contains('RETRAITE')) return '🏛️';
    if (cle.contains('CMU') || cle.contains('AMU') || cle.contains('SANTE')) {
      return '🏥';
    }
    if (cle.contains('ASSUR')) return '🛡️';
    if (cle.contains('COMMISSION') || cle.contains('FRAIS')) return '⚙️';
    return '📄';
  }

  @override
  Widget build(BuildContext context) {
    final regle = type.regle;
    final actif = type.estActif;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                    child: Text(_emoji, style: const TextStyle(fontSize: 21))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.libelle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (type.description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        type.description!,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (modifiable)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded,
                      color: AppColors.textSecondary, size: 20),
                  onSelected: (action) =>
                      action == 'modifier' ? onModifier?.call() : onSupprimer?.call(),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'modifier', child: Text('Modifier')),
                    PopupMenuItem(value: 'supprimer', child: Text('Supprimer')),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (type.montantPaiementMensuel != null)
                _InfoChip(
                  label:
                      '${fmt.format(type.montantPaiementMensuel)} FCFA / mois',
                  color: AppColors.primaryBlue,
                ),
              if (regle != null) ...[
                const SizedBox(width: 8),
                _InfoChip(
                  label: regle.valeurAffichee,
                  color: AppColors.purple,
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: regle == null
                    ? const Text(
                        'Prélèvement non configuré',
                        style: TextStyle(
                            color: AppColors.textHint, fontSize: 12),
                      )
                    : Text(
                        actif
                            ? 'Prélèvement automatique actif'
                            : 'Prélèvement en pause',
                        style: TextStyle(
                          color:
                              actif ? AppColors.success : AppColors.textHint,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              if (regle != null)
                Switch.adaptive(value: actif, onChanged: onBasculer),
              TextButton(
                onPressed: onConfigurer,
                child: Text(regle == null ? 'Configurer' : 'Ajuster'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Formulaire de règle de prélèvement ───────────────────────────────────────

class _FormulaireRegle extends ConsumerStatefulWidget {
  final TypeCotisation type;

  const _FormulaireRegle({required this.type});

  @override
  ConsumerState<_FormulaireRegle> createState() => _FormulaireRegleState();
}

class _FormulaireRegleState extends ConsumerState<_FormulaireRegle> {
  late final TextEditingController _valeur;
  late TypeCalcul _typeCalcul;
  late bool _estActif;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    final regle = widget.type.regle;
    _valeur = TextEditingController(
      text: regle == null ? '' : regle.valeur.round().toString(),
    );
    _typeCalcul = regle?.typeCalcul ?? TypeCalcul.pourcentage;
    _estActif = regle?.estActif ?? true;
  }

  @override
  void dispose() {
    _valeur.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    final valeur = double.tryParse(_valeur.text.replaceAll(' ', '')) ?? 0;
    if (valeur <= 0) {
      setState(() => _erreur = 'Indiquez une valeur supérieure à 0.');
      return;
    }
    if (_typeCalcul == TypeCalcul.pourcentage && valeur > 100) {
      setState(() => _erreur = 'Un pourcentage ne peut pas dépasser 100.');
      return;
    }

    setState(() => _erreur = null);

    final succes = await ref
        .read(cotisationsControllerProvider.notifier)
        .configurerRegle(
          typeCotisationId: widget.type.id,
          typeCalcul: _typeCalcul,
          valeur: valeur,
          estActif: _estActif,
        );

    if (!mounted) return;

    if (!succes) {
      final erreur = ref.read(cotisationsControllerProvider).error;
      setState(
        () => _erreur = erreur is ApiException
            ? erreur.message
            : 'L\'enregistrement a échoué.',
      );
      return;
    }

    Navigator.pop(context);
    _feedback(context, ref, true,
        succesMessage: 'Règle de prélèvement enregistrée.');
  }

  @override
  Widget build(BuildContext context) {
    final enCours = ref.watch(cotisationsControllerProvider).isLoading;

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
          Text(
            widget.type.libelle,
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Définissez ce qui est prélevé sur chaque paiement que vous recevez.',
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),
          SegmentedButton<TypeCalcul>(
            segments: const [
              ButtonSegment(
                  value: TypeCalcul.pourcentage, label: Text('Pourcentage')),
              ButtonSegment(value: TypeCalcul.fixe, label: Text('Montant fixe')),
            ],
            selected: {_typeCalcul},
            onSelectionChanged: (s) => setState(() => _typeCalcul = s.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _valeur,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) {
              if (_erreur != null) setState(() => _erreur = null);
            },
            decoration: InputDecoration(
              labelText: _typeCalcul == TypeCalcul.pourcentage
                  ? 'Pourcentage prélevé (%)'
                  : 'Montant prélevé (FCFA)',
              hintText: _typeCalcul == TypeCalcul.pourcentage ? '3' : '5000',
            ),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _estActif,
            onChanged: (v) => setState(() => _estActif = v),
            title: const Text('Activer le prélèvement',
                style: TextStyle(fontSize: 14)),
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
                : const Text('Enregistrer la règle'),
          ),
        ],
      ),
    );
  }
}

// ─── Formulaire de cotisation personnalisée ───────────────────────────────────

class _FormulaireCotisation extends ConsumerStatefulWidget {
  final TypeCotisation? existant;

  const _FormulaireCotisation({this.existant});

  @override
  ConsumerState<_FormulaireCotisation> createState() =>
      _FormulaireCotisationState();
}

/// Marqueur choisi dans le sélecteur de type quand aucune proposition ne
/// correspond et que l'utilisateur veut créer un type entièrement nouveau.
const String _nouveauTypeSentinel = '__nouveau_type__';

/// Marqueur choisi dans le sélecteur de catégorie pour en saisir une libre,
/// quand aucune des catégories déjà utilisées ne correspond.
const String _autreCategorieSentinel = '__autre_categorie__';

/// Catégorie appliquée par défaut par le back-end quand l'utilisateur crée un
/// type entièrement nouveau sans en préciser — reprise ici comme valeur par
/// défaut du sélecteur pour rester cohérent avec ce comportement.
const String _categoriePersonnaliseeParDefaut = 'COTISATION PERSONNALISE';

class _FormulaireCotisationState extends ConsumerState<_FormulaireCotisation> {
  late final TextEditingController _libelle;
  late final TextEditingController _code;
  late final TextEditingController _description;
  late final TextEditingController _montant;
  late final TextEditingController _categorieLibre;
  String? _erreur;

  /// `null` : rien choisi. Une [SuggestionTypeCotisation] : proposition
  /// reprise telle quelle. [_nouveauTypeSentinel] : création d'un type
  /// entièrement nouveau. Sans objet en modification (le type est déjà fixé).
  Object? _choix;
  String _categorieChoisie = _categoriePersonnaliseeParDefaut;

  bool get _estModification => widget.existant != null;
  bool get _suggestionChoisie => _choix is SuggestionTypeCotisation;
  bool get _nouveauTypeChoisi => _choix == _nouveauTypeSentinel;

  @override
  void initState() {
    super.initState();
    final t = widget.existant;
    _libelle = TextEditingController(text: t?.libelle ?? '');
    _code = TextEditingController(text: t?.code ?? '');
    _description = TextEditingController(text: t?.description ?? '');
    _montant = TextEditingController(
      text: t?.montantPaiementMensuel?.round().toString() ?? '',
    );
    _categorieLibre = TextEditingController();
  }

  @override
  void dispose() {
    _libelle.dispose();
    _code.dispose();
    _description.dispose();
    _montant.dispose();
    _categorieLibre.dispose();
    super.dispose();
  }

  /// Génère un code à partir du libellé quand l'utilisateur n'en saisit pas.
  String _codeParDefaut(String libelle) => libelle
      .toUpperCase()
      .replaceAll(RegExp(r'[^A-Z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');

  Future<void> _enregistrer() async {
    if (!_estModification && _choix == null) {
      setState(() => _erreur =
          'Sélectionnez une proposition ou créez un nouveau type.');
      return;
    }

    final libelle = _libelle.text.trim();
    final montant = double.tryParse(_montant.text.replaceAll(' ', '')) ?? 0;

    if (libelle.isEmpty) {
      setState(() => _erreur = 'Donnez un nom à la cotisation.');
      return;
    }
    if (montant <= 0) {
      setState(() => _erreur = 'Indiquez le montant mensuel de la cotisation.');
      return;
    }
    if (!_estModification &&
        _nouveauTypeChoisi &&
        _categorieChoisie == _autreCategorieSentinel &&
        _categorieLibre.text.trim().isEmpty) {
      setState(() => _erreur = 'Précisez la catégorie.');
      return;
    }

    setState(() => _erreur = null);

    final code = _code.text.trim().isEmpty
        ? _codeParDefaut(libelle)
        : _code.text.trim().toUpperCase();
    final description =
        _description.text.trim().isEmpty ? null : _description.text.trim();

    // La catégorie suit toujours le choix de type : reprise telle quelle
    // d'une proposition existante (jamais modifiée), ou celle sélectionnée
    // pour un type entièrement nouveau.
    final categorie = _estModification
        ? null
        : _suggestionChoisie
            ? (_choix as SuggestionTypeCotisation).categorie
            : _categorieChoisie == _autreCategorieSentinel
                ? _categorieLibre.text.trim()
                : _categorieChoisie;

    final controller = ref.read(cotisationsControllerProvider.notifier);
    final succes = _estModification
        ? await controller.modifierTypePersonnalise(
            id: widget.existant!.id,
            libelle: libelle,
            code: code,
            montantPaiementMensuel: montant,
            description: description,
          )
        : await controller.ajouterTypePersonnalise(
            libelle: libelle,
            code: code,
            montantPaiementMensuel: montant,
            description: description,
            categorie: categorie,
          );

    if (!mounted) return;

    if (!succes) {
      final erreur = ref.read(cotisationsControllerProvider).error;
      setState(
        () => _erreur = erreur is ApiException
            ? erreur.message
            : 'L\'enregistrement a échoué.',
      );
      return;
    }

    Navigator.pop(context);
    _feedback(context, ref, true,
        succesMessage: _estModification
            ? 'Cotisation mise à jour.'
            : 'Cotisation ajoutée.');
  }

  void _choisir(Object? valeur) {
    setState(() {
      _choix = valeur;
      _erreur = null;
      if (valeur is SuggestionTypeCotisation) {
        _libelle.text = valeur.libelle;
        _code.text = valeur.code;
      } else if (valeur == _nouveauTypeSentinel) {
        _libelle.clear();
        _code.clear();
        _categorieChoisie = _categoriePersonnaliseeParDefaut;
      }
    });
  }

  /// Catégories réellement utilisées par les propositions, dédupliquées et
  /// complétées de la valeur par défaut — jamais de liste figée en dur.
  List<String> _categoriesDisponibles(List<SuggestionTypeCotisation> suggestions) {
    final categories = <String>{_categoriePersonnaliseeParDefaut};
    for (final s in suggestions) {
      final c = s.categorie?.trim().toUpperCase();
      if (c != null && c.isNotEmpty) categories.add(c);
    }
    final liste = categories.toList()..sort();
    return liste;
  }

  @override
  Widget build(BuildContext context) {
    final enCours = ref.watch(cotisationsControllerProvider).isLoading;
    final suggestions = _estModification
        ? const <SuggestionTypeCotisation>[]
        : ref.watch(suggestionsTypesCotisationProvider).valueOrNull ??
            const <SuggestionTypeCotisation>[];

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
                  ? 'Modifier la cotisation'
                  : 'Nouvelle cotisation',
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 20),
            if (_estModification) ...[
              TextField(
                controller: _libelle,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  hintText: 'Ex : Axa assurance',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _code,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Code (optionnel)',
                  hintText: 'Ex : AXA',
                ),
              ),
            ] else ...[
              DropdownButtonFormField<Object>(
                initialValue: _choix,
                decoration: const InputDecoration(
                  labelText: 'Type de cotisation',
                ),
                hint: const Text('Sélectionner ou créer un type'),
                isExpanded: true,
                items: [
                  for (final s in suggestions)
                    DropdownMenuItem<Object>(
                      value: s,
                      child: Text(
                        '${s.libelle} (${s.code})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const DropdownMenuItem<Object>(
                    value: _nouveauTypeSentinel,
                    child: Text('+ Créer un nouveau type'),
                  ),
                ],
                onChanged: _choisir,
              ),
              const SizedBox(height: 14),
            ],
            if (_suggestionChoisie) ...[
              _CarteTypeSuggere(suggestion: _choix as SuggestionTypeCotisation),
              const SizedBox(height: 14),
            ],
            if (_estModification || _nouveauTypeChoisi || _suggestionChoisie) ...[
              if (_nouveauTypeChoisi) ...[
                TextField(
                  controller: _libelle,
                  decoration: const InputDecoration(
                    labelText: 'Libellé',
                    hintText: 'Ex : Axa assurance',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Code (optionnel)',
                    hintText: 'Ex : AXA',
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _categorieChoisie,
                  decoration: const InputDecoration(labelText: 'Catégorie'),
                  isExpanded: true,
                  items: [
                    for (final c in _categoriesDisponibles(suggestions))
                      DropdownMenuItem(value: c, child: Text(c)),
                    const DropdownMenuItem(
                      value: _autreCategorieSentinel,
                      child: Text('Autre…'),
                    ),
                  ],
                  onChanged: (v) => setState(
                      () => _categorieChoisie = v ?? _categoriePersonnaliseeParDefaut),
                ),
                if (_categorieChoisie == _autreCategorieSentinel) ...[
                  const SizedBox(height: 14),
                  TextField(
                    controller: _categorieLibre,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Précisez la catégorie',
                    ),
                  ),
                ],
                const SizedBox(height: 14),
              ],
              TextField(
                controller: _description,
                decoration: const InputDecoration(
                  labelText: 'Description (optionnel)',
                  hintText: 'Ex : Assurance privée',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _montant,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) {
                  if (_erreur != null) setState(() => _erreur = null);
                },
                decoration: const InputDecoration(
                  labelText: 'Cotisation mensuelle (FCFA)',
                  hintText: '11500',
                ),
              ),
            ],
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
                  : Text(_estModification ? 'Enregistrer' : 'Ajouter'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Informations communes d'une proposition reprise telle quelle — non
/// modifiables : seules la description et le montant sont propres à
/// l'utilisateur courant.
class _CarteTypeSuggere extends StatelessWidget {
  final SuggestionTypeCotisation suggestion;

  const _CarteTypeSuggere({required this.suggestion});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_outline_rounded,
                  size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                suggestion.libelle,
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Code : ${suggestion.code}'
            '${suggestion.categorie != null && suggestion.categorie!.isNotEmpty ? ' · ${suggestion.categorie}' : ''}',
            style: const TextStyle(
                fontSize: 12.5, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets utilitaires ──────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final bool aJour;
  const _StatusPill({required this.aJour});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (aJour ? AppColors.success : AppColors.red)
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: aJour ? AppColors.success : AppColors.red,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            aJour ? 'À jour' : 'En retard',
            style: TextStyle(
              color: aJour ? AppColors.success : AppColors.red,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;

  const _InfoChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _RecapRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;

  const _RecapRow({
    required this.label,
    required this.value,
    required this.isHighlight,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isHighlight
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color:
                  isHighlight ? AppColors.primaryBlue : AppColors.textPrimary,
              fontSize: 13,
              fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

extension _Let<T> on T {
  /// Applique [transform] à une valeur non nulle — évite les variables
  /// intermédiaires dans les expressions conditionnelles.
  R let<R>(R Function(T) transform) => transform(this);
}
