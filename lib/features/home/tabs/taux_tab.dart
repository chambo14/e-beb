import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/user_model.dart';

class TauxTab extends StatelessWidget {
  final UserModel user;

  const TauxTab({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            const _ParametresFinanciers(),
            const SizedBox(height: 24),
            const _ValiderButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Bouton Valider ───────────────────────────────────────────────────────────

class _ValiderButton extends StatelessWidget {
  const _ValiderButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Vos taux de prélèvement ont été enregistrés',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: AppColors.primaryBlue,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
        icon: const Icon(Icons.check_circle_rounded, size: 20),
        label: const Text(
          'VALIDER',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.5),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 2,
        ),
      ),
    );
  }
}

// ─── Paramètres financiers ────────────────────────────────────────────────────

// ─── Paramètres financiers ────────────────────────────────────────────────────

class _ServiceParam {
  final String label;
  final Color color;
  final bool hasToggle;
  final TextEditingController tauxController;
  final TextEditingController montantController;
  bool tauxActive;
  bool montantActive;

  _ServiceParam({
    required this.label,
    required this.color,
    required this.hasToggle,
    required this.tauxController,
    required this.montantController,
    this.tauxActive = true,
    this.montantActive = true,
  });
}

class _ParametresFinanciers extends StatefulWidget {
  const _ParametresFinanciers();

  @override
  State<_ParametresFinanciers> createState() => _ParametresFinanciersState();
}

class _ParametresFinanciersState extends State<_ParametresFinanciers> {
  late final List<_ServiceParam> _services;

  @override
  void initState() {
    super.initState();
    _services = [
      _ServiceParam(
        label: 'CNPS',
        color: const Color(0xFFF97316),
        hasToggle: false,
        tauxController: TextEditingController(text: '12'),
        montantController: TextEditingController(text: '0'),
      ),
      _ServiceParam(
        label: 'CMU',
        color: const Color(0xFF9CA3AF),
        hasToggle: false,
        tauxController: TextEditingController(text: '3'),
        montantController: TextEditingController(text: '0'),
      ),
      _ServiceParam(
        label: 'ASSU 1',
        color: const Color(0xFFF59E0B),
        hasToggle: true,
        tauxController: TextEditingController(text: '5'),
        montantController: TextEditingController(text: '0'),
        tauxActive: true,
        montantActive: true,
      ),
      _ServiceParam(
        label: 'ASSU 2',
        color: const Color(0xFF3B82F6),
        hasToggle: true,
        tauxController: TextEditingController(text: '5'),
        montantController: TextEditingController(text: '0'),
        tauxActive: true,
        montantActive: true,
      ),
      _ServiceParam(
        label: 'EPAR 1',
        color: const Color(0xFF22C55E),
        hasToggle: true,
        tauxController: TextEditingController(text: '10'),
        montantController: TextEditingController(text: '0'),
        tauxActive: false,
        montantActive: false,
      ),
    ];

    // Écouter les changements de texte pour mettre à jour la somme instantanément
    for (final s in _services) {
      s.tauxController.addListener(_updateSomme);
    }
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

  // Calcul dynamique de la somme globale des taux actifs
  int get _sommeTotaleTaux {
    int total = 0;
    for (final s in _services) {
      if (!s.hasToggle || s.tauxActive) {
        final valeur = int.tryParse(s.tauxController.text) ?? 0;
        total += valeur;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
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
              onToggleTaux: () => setState(() {
                _services[i].tauxActive = !_services[i].tauxActive;
              }),
              onToggleMontant: () => setState(() {
                _services[i].montantActive = !_services[i].montantActive;
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
