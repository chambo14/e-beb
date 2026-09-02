import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../domain/entities/type_cotisation.dart';
import '../../../presentation/providers/cotisation_providers.dart';
import '../../../presentation/providers/repository_providers.dart';
import '../../../presentation/providers/utilisateur_providers.dart';

/// Vue « Vos taux » : édition en lot des règles de prélèvement
/// (`/espace-utilisateur/regle-prelevements`).
class TauxTab extends ConsumerWidget {
  const TauxTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cotisations = ref.watch(cotisationsControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Vos taux',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: cotisations.when(
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
                      : 'Impossible de charger vos taux.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.5),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref
                      .read(cotisationsControllerProvider.notifier)
                      .recharger(),
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(160, 44)),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (types) => types.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Aucun type de cotisation n\'est disponible pour le moment.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.5),
                  ),
                ),
              )
            : SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: _ParametresFinanciers(
                  // La clé force la reconstruction des contrôleurs quand la
                  // liste change (ajout / suppression de cotisation).
                  key: ValueKey(types.map((t) => t.id).join('|')),
                  types: types,
                ),
              ),
      ),
    );
  }
}

// ─── Paramètres financiers ────────────────────────────────────────────────────

/// Contraintes minimales communes à toutes les cotisations (plateforme et
/// personnalisées) : en dessous, la règle n'a pas de sens économique.
const double _tauxMinimum = 4;
const double _montantMinimum = 200;

class _ServiceParam {
  /// Non `final` : resynchronisé en place après l'enregistrement avec la
  /// version fraîchement relue en base, sans reconstruire tout le widget
  /// (voir `_ParametresFinanciersState._resynchroniser`).
  TypeCotisation type;
  final Color color;
  final TextEditingController tauxController;
  final TextEditingController montantController;

  /// `true` = prélèvement en pourcentage, `false` = montant fixe.
  bool tauxActive;
  bool montantActive;

  _ServiceParam({
    required this.type,
    required this.color,
    required this.tauxController,
    required this.montantController,
    this.tauxActive = true,
    this.montantActive = true,
  });

  /// Code court affiché sur la vignette (le libellé complet est trop long
  /// pour l'espace disponible) — repli sur le libellé si aucun code.
  String get label =>
      (type.code != null && type.code!.isNotEmpty) ? type.code! : type.libelle;

  double get valeurSaisie => tauxActive
      ? (double.tryParse(tauxController.text) ?? 0)
      : (double.tryParse(montantController.text) ?? 0);

  TypeCalcul get typeCalcul =>
      tauxActive ? TypeCalcul.pourcentage : TypeCalcul.fixe;

  /// `true` pour une cotisation personnalisée dont la règle de prélèvement
  /// n'a pas encore été configurée et validée côté serveur (aucune règle
  /// enregistrée, ou règle enregistrée mais inactive) — tant que c'est le
  /// cas, le back-end n'effectue aucun prélèvement pour ce type (voir
  /// `PaiementService::calculerRepartition`). Les cotisations plateforme
  /// (CNPS, AMU…) ne sont jamais concernées : elles ont toujours une valeur
  /// par défaut.
  bool get reglePasEncoreValidee =>
      type.estPersonnalise && !(type.estConfigure && type.estActif);

  /// `null` si la valeur active respecte la contrainte minimale (ou vaut 0,
  /// donc pas encore configurée), sinon le message à afficher.
  String? get erreurMinimum {
    final valeur = valeurSaisie;
    if (valeur <= 0) return null;
    if (tauxActive && valeur < _tauxMinimum) {
      return 'Le taux minimum est de ${_tauxMinimum.round()} %.';
    }
    if (montantActive && valeur < _montantMinimum) {
      return 'Le montant minimum est de ${_montantMinimum.round()} FCFA.';
    }
    return null;
  }
}

class _ParametresFinanciers extends ConsumerStatefulWidget {
  final List<TypeCotisation> types;

  const _ParametresFinanciers({super.key, required this.types});

  @override
  ConsumerState<_ParametresFinanciers> createState() =>
      _ParametresFinanciersState();
}

class _ParametresFinanciersState
    extends ConsumerState<_ParametresFinanciers> {
  late final List<_ServiceParam> _services;

  /// État de chargement local, indépendant du provider partagé : le bouton
  /// « Valider » ne doit refléter que l'enregistrement en cours dans CE
  /// formulaire, pas l'état global des cotisations (voir `_enregistrer`).
  bool _enregistrement = false;

  static const _palette = [
    Color(0xFFF97316),
    Color(0xFF9CA3AF),
    Color(0xFFF59E0B),
    Color(0xFF3B82F6),
    Color(0xFF22C55E),
    Color(0xFF8B5CF6),
  ];

  @override
  void initState() {
    super.initState();
    _services = [
      for (var i = 0; i < widget.types.length; i++)
        _construireService(widget.types[i], _palette[i % _palette.length]),
    ];

    // Met à jour les sommes affichées à chaque frappe.
    for (final s in _services) {
      s.tauxController.addListener(_updateSomme);
      s.montantController.addListener(_updateSomme);
    }
  }

  /// Priorité : règle déjà enregistrée par l'utilisateur > configuration par
  /// défaut du système (obligatoire pour CNPS/CMU) > 5 % à défaut de tout
  /// (voir `TypeCotisation.valeurEffective`/`typeCalculEffectif`).
  ///
  /// Si les deux modes étaient renseignés (cas normalement impossible, un
  /// type n'a qu'un seul `type_calcul`), le taux serait prioritaire : c'est
  /// exactement le comportement de `typeCalculEffectif`, qui retombe sur
  /// POURCENTAGE quand rien n'est déterminé.
  _ServiceParam _construireService(TypeCotisation type, Color couleur) {
    final enPourcentage = type.typeCalculEffectif == TypeCalcul.pourcentage;
    final valeur = type.valeurEffective;
    return _ServiceParam(
      type: type,
      color: couleur,
      tauxController: TextEditingController(
        text: enPourcentage ? valeur.round().toString() : '0',
      ),
      montantController: TextEditingController(
        text: !enPourcentage ? valeur.round().toString() : '0',
      ),
      // Un seul champ actif par défaut, celui de la règle actuellement
      // configurée — l'autre reste désactivé tant que l'utilisateur ne
      // bascule pas explicitement (évite d'envoyer une valeur non voulue).
      tauxActive: enPourcentage,
      montantActive: !enPourcentage,
    );
  }

  void _updateSomme() {
    setState(() {});
  }

  /// Recale chaque `_ServiceParam` sur la version fraîchement relue en base
  /// — sans reconstruire le formulaire ni perdre les contrôleurs (donc sans
  /// perdre le focus ou une saisie en cours dans une autre ligne). C'est ce
  /// qui garantit que les valeurs affichées après « Valider » sont bien
  /// celles réellement enregistrées, plutôt qu'un état local potentiellement
  /// périmé.
  void _resynchroniser(List<TypeCotisation> typesActualises) {
    final parId = {for (final t in typesActualises) t.id: t};
    for (final service in _services) {
      final actualise = parId[service.type.id];
      if (actualise == null) continue;

      service.type = actualise;
      final enPourcentage =
          actualise.typeCalculEffectif == TypeCalcul.pourcentage;
      final valeur = actualise.valeurEffective;
      service.tauxController.text =
          enPourcentage ? valeur.round().toString() : '0';
      service.montantController.text =
          !enPourcentage ? valeur.round().toString() : '0';
      service.tauxActive = enPourcentage;
      service.montantActive = !enPourcentage;
    }
  }

  @override
  void dispose() {
    for (final s in _services) {
      s.tauxController.removeListener(_updateSomme);
      s.montantController.removeListener(_updateSomme);
      s.tauxController.dispose();
      s.montantController.dispose();
    }
    super.dispose();
  }

  // Total des taux en pourcentage actifs.
  int get _totalTaux {
    var total = 0;
    for (final s in _services) {
      if (s.tauxActive) {
        total += int.tryParse(s.tauxController.text) ?? 0;
      }
    }
    return total;
  }

  // Cotisations personnalisées dont la règle n'est pas encore configurée et
  // validée : leur prélèvement est ignoré par le back-end tant que ce n'est
  // pas le cas (voir `_ServiceParam.reglePasEncoreValidee`).
  List<_ServiceParam> get _servicesNonConfigures =>
      _services.where((s) => s.reglePasEncoreValidee).toList();

  // Total des montants fixes actifs.
  int get _totalMontant {
    var total = 0;
    for (final s in _services) {
      if (s.montantActive) {
        total += int.tryParse(s.montantController.text) ?? 0;
      }
    }
    return total;
  }

  /// Enregistre une règle par type de cotisation.
  ///
  /// Passe par le dépôt directement plutôt que par
  /// `cotisationsControllerProvider`, dont chaque appel bascule l'état
  /// partagé en `AsyncLoading` *avant* la requête réseau : `TauxTab` réagit
  /// à ce changement en remplaçant `_ParametresFinanciers` par un simple
  /// indicateur de chargement (`cotisations.when(loading: ...)`), ce qui
  /// démonte ce widget — et donc interrompt cette boucle via le garde
  /// `if (!mounted)` — dès la première règle enregistrée. Les cotisations
  /// suivantes (par ex. CNPS quand elle n'est pas la première de la liste)
  /// n'étaient alors jamais envoyées, et le message de succès final
  /// n'était jamais atteint.
  ///
  /// Toutes les règles sont désormais tentées, chaque échec est collecté
  /// individuellement (avec le vrai message serveur), et la liste globale
  /// n'est rafraîchie qu'une seule fois à la fin.
  Future<void> _enregistrer() async {
    if (_totalTaux > 100) {
      _snack(
        'Le total des taux dépasse 100 %. Ajustez vos valeurs.',
        succes: false,
      );
      return;
    }

    // Contraintes minimales (taux ≥ 4 %, montant ≥ 200 FCFA) : on bloque
    // avant tout appel réseau plutôt que de laisser le serveur les rejeter
    // une à une.
    for (final service in _services) {
      final erreur = service.erreurMinimum;
      if (erreur != null) {
        _snack('${service.label} : $erreur', succes: false);
        return;
      }
    }

    setState(() => _enregistrement = true);

    final repo = ref.read(cotisationRepositoryProvider);
    final erreurs = <String>[];
    var nombreEnregistrees = 0;

    for (final service in _services) {
      final valeur = service.valeurSaisie;
      // Une valeur nulle sur un type jamais configuré : rien à enregistrer.
      if (valeur <= 0 && service.type.regle == null) continue;

      try {
        await repo.configurerRegle(
          typeCotisationId: service.type.id,
          typeCalcul: service.typeCalcul,
          valeur: valeur,
          estActif: valeur > 0,
        );
        nombreEnregistrees++;
      } on ApiException catch (e) {
        erreurs.add('${service.label} : ${e.message}');
      } catch (_) {
        erreurs.add('${service.label} : échec de l\'enregistrement.');
      }
    }

    // Relit les données une seule fois, une fois la boucle terminée — sans
    // passer par `recharger()` (qui bascule en `AsyncLoading` et ferait
    // disparaître tout l'écran le temps de la requête). Les valeurs
    // affichées sont resynchronisées en place à partir de ce qui est
    // réellement en base, et le provider partagé est mis à jour
    // silencieusement pour que les autres écrans (onglet Cotisations…)
    // restent cohérents sans flash de chargement ici.
    List<TypeCotisation> typesActualises;
    try {
      typesActualises = await repo.typesDisponibles();
    } on ApiException {
      typesActualises = const [];
    }

    if (!mounted) return;

    if (typesActualises.isNotEmpty) {
      ref
          .read(cotisationsControllerProvider.notifier)
          .definirDonnees(typesActualises);
      setState(() => _resynchroniser(typesActualises));
    }
    ref.invalidate(recapitulatifProvider);

    setState(() => _enregistrement = false);

    if (erreurs.isNotEmpty) {
      _snack(erreurs.join('\n'), succes: false);
      return;
    }

    if (nombreEnregistrees == 0) {
      _snack('Aucune règle à enregistrer.', succes: false);
      return;
    }

    _snack(
      nombreEnregistrees == 1
          ? 'Votre règle de prélèvement a été enregistrée.'
          : 'Vos $nombreEnregistrees règles de prélèvement ont été enregistrées.',
      succes: true,
    );
  }

  void _snack(String message, {required bool succes}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: succes ? AppColors.primaryBlue : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enCours = _enregistrement;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête violet
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF5B21B6), Color(0xFF3730A3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            children: [
              Icon(Icons.percent_rounded, color: Colors.white70, size: 22),
              SizedBox(height: 8),
              Text(
                'Taux de prélèvement sur mon revenu',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // En-têtes colonnes
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: const [
              Spacer(),
              SizedBox(
                width: 58,
                child: Text(
                  'Taux',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              SizedBox(width: 8),
              SizedBox(
                width: 82,
                child: Text(
                  'Montant',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Liste des services
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
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _services.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: AppColors.border,
            ),
            itemBuilder: (_, i) => _ServiceRow(
              service: _services[i],
              // Taux et montant s'excluent : l'API n'accepte qu'un seul mode
              // de calcul par règle.
              onToggleTaux: () => setState(() {
                _services[i].tauxActive = !_services[i].tauxActive;
                _services[i].montantActive = !_services[i].tauxActive;
              }),
              onToggleMontant: () => setState(() {
                _services[i].montantActive = !_services[i].montantActive;
                _services[i].tauxActive = !_services[i].montantActive;
              }),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ─── Avertissement : règles non configurées/validées ───────────────
        if (_servicesNonConfigures.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.warning, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _servicesNonConfigures.length == 1
                        ? 'Une cotisation n\'est pas encore configurée. Son '
                            'prélèvement sera ignoré jusqu\'à validation de sa '
                            'règle.'
                        : 'Certaines cotisations ne sont pas encore '
                            'configurées. Leurs prélèvements seront ignorés '
                            'jusqu\'à validation de leurs règles.',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ─── Récapitulatif : total des prélèvements ────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primaryBlue.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.functions_rounded,
                      color: AppColors.primaryBlue, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Total des prélèvements',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _TotalBadge(label: 'Taux', valeur: '$_totalTaux %'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TotalBadge(
                        label: 'Montant', valeur: '$_totalMontant FCFA'),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ─── Bouton Valider ─────────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: enCours ? null : _enregistrer,
            icon: enCours
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : const Icon(Icons.check_circle_rounded, size: 20),
            label: const Text(
              'VALIDER',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: 0.5),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

/// Vignette du récapitulatif : label + valeur totale (taux ou montant).
class _TotalBadge extends StatelessWidget {
  final String label;
  final String valeur;

  const _TotalBadge({required this.label, required this.valeur});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            valeur,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceRow extends StatefulWidget {
  final _ServiceParam service;
  final VoidCallback onToggleTaux;
  final VoidCallback onToggleMontant;

  const _ServiceRow({
    required this.service,
    required this.onToggleTaux,
    required this.onToggleMontant,
  });

  @override
  State<_ServiceRow> createState() => _ServiceRowState();
}

class _ServiceRowState extends State<_ServiceRow> {
  @override
  void initState() {
    super.initState();
    widget.service.tauxController.addListener(_refresh);
    widget.service.montantController.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    widget.service.tauxController.removeListener(_refresh);
    widget.service.montantController.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final tauxActive = service.tauxActive;
    final montantActive = service.montantActive;
    final erreur = service.erreurMinimum;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Code coloré
              Container(
                width: 68,
                padding: const EdgeInsets.symmetric(
                    vertical: 6, horizontal: 4),
                decoration: BoxDecoration(
                  color: service.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  service.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),

              const Spacer(),

              // Champ Taux (%)
              SizedBox(
                width: 58,
                height: 38,
                child: TextField(
                  controller: service.tauxController,
                  enabled: tauxActive,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: tauxActive
                        ? AppColors.textPrimary
                        : AppColors.textHint,
                  ),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.zero,
                    suffixText: '%',
                    suffixStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: tauxActive ? service.color : AppColors.textHint,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: service.color, width: 1.5),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: service.color, width: 2),
                    ),
                    filled: true,
                    fillColor:
                        tauxActive ? Colors.white : AppColors.inputFill,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Champ Montant (F)
              SizedBox(
                width: 82,
                height: 38,
                child: TextField(
                  controller: service.montantController,
                  enabled: montantActive,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: montantActive
                        ? AppColors.textPrimary
                        : AppColors.textHint,
                  ),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.zero,
                    suffixText: 'F',
                    suffixStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color:
                          montantActive ? service.color : AppColors.textHint,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: service.color, width: 1.5),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: service.color, width: 2),
                    ),
                    filled: true,
                    fillColor:
                        montantActive ? Colors.white : AppColors.inputFill,
                  ),
                ),
              ),
            ],
          ),

          if (service.reglePasEncoreValidee) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.error_outline_rounded,
                    color: AppColors.warning.withValues(alpha: 0.9), size: 13),
                const SizedBox(width: 4),
                const Text(
                  'Prélèvement non configuré',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],

          if (erreur != null) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                erreur,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          // Bascule taux / montant — un seul mode actif à la fois.
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 72),
              const Spacer(),
              GestureDetector(
                onTap: tauxActive ? null : widget.onToggleTaux,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: tauxActive
                        ? const Color(0xFF22C55E)
                        : AppColors.inputFill,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tauxActive ? 'Taux actif' : 'Passer au taux',
                    style: TextStyle(
                      color: tauxActive
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: montantActive ? null : widget.onToggleMontant,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 90,
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    color: montantActive
                        ? const Color(0xFF22C55E)
                        : AppColors.inputFill,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    montantActive ? 'Montant actif' : 'Passer au montant',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: montantActive
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
