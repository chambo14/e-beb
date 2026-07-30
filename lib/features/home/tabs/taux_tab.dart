import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../domain/entities/type_cotisation.dart';
import '../../../presentation/providers/cotisation_providers.dart';

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

class _ServiceParam {
  final TypeCotisation type;
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

  String get label => type.libelle;

  /// Les cotisations de la plateforme ne peuvent pas être désactivées.
  bool get hasToggle => type.estPersonnalise;

  double get valeurSaisie => tauxActive
      ? (double.tryParse(tauxController.text) ?? 0)
      : (double.tryParse(montantController.text) ?? 0);

  TypeCalcul get typeCalcul =>
      tauxActive ? TypeCalcul.pourcentage : TypeCalcul.fixe;
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

    // Met à jour la somme affichée à chaque frappe.
    for (final s in _services) {
      s.tauxController.addListener(_updateSomme);
    }
  }

  _ServiceParam _construireService(TypeCotisation type, Color couleur) {
    final regle = type.regle;
    final enPourcentage = regle?.typeCalcul != TypeCalcul.fixe;
    return _ServiceParam(
      type: type,
      color: couleur,
      tauxController: TextEditingController(
        text: enPourcentage && regle != null ? regle.valeur.round().toString() : '0',
      ),
      montantController: TextEditingController(
        text: !enPourcentage && regle != null
            ? regle.valeur.round().toString()
            : '0',
      ),
      tauxActive: enPourcentage,
      montantActive: !enPourcentage,
    );
  }

  void _updateSomme() {
    setState(() {});
  }

  @override
  void dispose() {
    for (final s in _services) {
      s.tauxController.removeListener(_updateSomme);
      s.tauxController.dispose();
      s.montantController.dispose();
    }
    super.dispose();
  }

  // Calcul dynamique de la somme globale des taux en pourcentage
  int get _sommeTotaleTaux {
    var total = 0;
    for (final s in _services) {
      if (s.tauxActive) {
        total += int.tryParse(s.tauxController.text) ?? 0;
      }
    }
    return total;
  }

  /// Enregistre une règle par type de cotisation ; s'arrête à la première
  /// erreur pour ne pas masquer le message du serveur.
  Future<void> _enregistrer() async {
    if (_sommeTotaleTaux > 100) {
      _snack(
        'La somme des pourcentages dépasse 100 %. Ajustez vos taux.',
        succes: false,
      );
      return;
    }

    final controller = ref.read(cotisationsControllerProvider.notifier);

    for (final service in _services) {
      final valeur = service.valeurSaisie;
      // Une valeur nulle sur un type jamais configuré : rien à enregistrer.
      if (valeur <= 0 && service.type.regle == null) continue;

      final succes = await controller.configurerRegle(
        typeCotisationId: service.type.id,
        typeCalcul: service.typeCalcul,
        valeur: valeur,
        estActif: valeur > 0,
      );

      if (!mounted) return;
      if (!succes) {
        final erreur = ref.read(cotisationsControllerProvider).error;
        _snack(
          erreur is ApiException
              ? '${service.label} : ${erreur.message}'
              : 'Échec de l\'enregistrement pour ${service.label}.',
          succes: false,
        );
        return;
      }
    }

    if (!mounted) return;
    _snack('Vos taux de prélèvement ont été enregistrés', succes: true);
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
    final enCours = ref.watch(cotisationsControllerProvider).isLoading;

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

        // ─── Nouveau : Container Récapitulatif Somme Totale ───────────────────
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.functions_rounded, // Icône mathématique de la somme
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Somme totale des prélèvements',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_sommeTotaleTaux %',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Label coloré
              Container(
                width: 56,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: service.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  service.label,
                  textAlign: TextAlign.center,
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
                  enabled: service.hasToggle ? tauxActive : true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: (service.hasToggle && !tauxActive)
                        ? AppColors.textHint
                        : AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.zero,
                    suffixText: '%',
                    suffixStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: (service.hasToggle && !tauxActive)
                          ? AppColors.textHint
                          : service.color,
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
                    fillColor: (service.hasToggle && !tauxActive)
                        ? AppColors.inputFill
                        : Colors.white,
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
                  enabled: service.hasToggle ? montantActive : true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: (service.hasToggle && !montantActive)
                        ? AppColors.textHint
                        : AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.zero,
                    suffixText: 'F',
                    suffixStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: (service.hasToggle && !montantActive)
                          ? AppColors.textHint
                          : service.color,
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
                    fillColor: (service.hasToggle && !montantActive)
                        ? AppColors.inputFill
                        : Colors.white,
                  ),
                ),
              ),
            ],
          ),

          // Boutons toggle (uniquement si la ligne est toggleable)
          if (service.hasToggle) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 64),
                const Spacer(),
                // Toggle Taux
                GestureDetector(
                  onTap: widget.onToggleTaux,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: tauxActive
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFF97316),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tauxActive ? 'Désactiver' : 'Activer',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Toggle Montant
                GestureDetector(
                  onTap: widget.onToggleMontant,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 82,
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      color: montantActive
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFF97316),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      montantActive ? 'Désactiver' : 'Activer',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
