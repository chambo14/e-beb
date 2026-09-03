import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../domain/entities/compte_mobile_money.dart';
import '../../../domain/entities/operation.dart';
import '../../../domain/entities/recapitulatif.dart';
import '../../../domain/entities/solde.dart';
import '../../../domain/entities/utilisateur.dart';
import '../../../presentation/providers/mobile_money_providers.dart';
import '../../../presentation/providers/notification_providers.dart';
import '../../../presentation/providers/session_provider.dart';
import '../../../presentation/providers/transaction_providers.dart';
import '../../../presentation/providers/utilisateur_providers.dart';
import '../../auth/screens/settings_page.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../paiements/screens/paiement_qr_screen.dart';
import '../../paiements/screens/scanner_qr_screen.dart';
import '../screens/recapitulatif_general_screen.dart';
import '../screens/toutes_transactions_screen.dart';

class AccueilTab extends ConsumerWidget {
  const AccueilTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final utilisateur = ref.watch(utilisateurCourantProvider);
    final recapitulatif = ref.watch(recapitulatifProvider);
    final operations = ref.watch(operationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(recapitulatifProvider);
            ref.invalidate(operationsProvider);
            ref.invalidate(soldeProvider);
            await ref.read(sessionProvider.notifier).rafraichirUtilisateur();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _UserHeader(
                  user: utilisateur,
                  onSettingsTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SettingsPage()),
                    );
                  },
                ),
                if (utilisateur?.enAttenteVerification == true) ...[
                  const SizedBox(height: 16),
                  const _BanniereVerificationEnCours(),
                ],
                const SizedBox(height: 24),
                ref
                    .watch(soldeProvider)
                    .when(
                      data: (solde) => _SoldeCard(
                        solde: solde,
                        recapitulatif: recapitulatif.valueOrNull,
                      ),
                      loading: () => const _BlocChargement(hauteur: 150),
                      error: (e, _) => _BlocErreur(
                        message: _messageErreur(e),
                        onRetry: () => ref.invalidate(soldeProvider),
                      ),
                    ),
                const SizedBox(height: 24),
                const _NetworkCardsSection(),
                const SizedBox(height: 32),
                const _CotisationTracker(),
                const SizedBox(height: 32),
                operations.when(
                  data: (liste) => _TransactionsList(operations: liste),
                  loading: () => const _BlocChargement(hauteur: 260),
                  error: (e, _) => _BlocErreur(
                    message: _messageErreur(e),
                    onRetry: () => ref.invalidate(operationsProvider),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _messageErreur(Object erreur) => erreur is ApiException
    ? erreur.message
    : 'Impossible de charger ces données.';

/// Squelette affiché pendant le chargement d'un bloc.
class _BlocChargement extends StatelessWidget {
  final double hauteur;

  const _BlocChargement({required this.hauteur});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: hauteur,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(strokeWidth: 2.5),
    );
  }
}

/// Erreur de chargement d'un bloc, avec relance.
class _BlocErreur extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _BlocErreur({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded,
              color: AppColors.error, size: 28),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}

/// Photo selfie du dossier KYC (`DocumentKYC.photo_selfie`) si disponible,
/// sinon repli sur les initiales — jamais d'image cassée affichée.
class _AvatarUtilisateur extends StatelessWidget {
  final Utilisateur? user;
  const _AvatarUtilisateur({required this.user});

  @override
  Widget build(BuildContext context) {
    final photo = user?.urlSelfie;
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.30),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: photo == null || photo.isEmpty
          ? _Initiales(user: user)
          : Image.network(
              photo,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _Initiales(user: user),
            ),
    );
  }
}

class _Initiales extends StatelessWidget {
  final Utilisateur? user;
  const _Initiales({required this.user});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        user?.initiales ?? '…',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ─── Header utilisateur ───────────────────────────────────────────────────────
class _UserHeader extends ConsumerWidget {
  final Utilisateur? user;
  final VoidCallback onSettingsTap; // Callback pour la redirection

  const _UserHeader({
    required this.user,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        // Avatar
        _AvatarUtilisateur(user: user),
        const SizedBox(width: 14),
        // Nom + matricule
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.nomComplet ?? 'Chargement…',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  user?.matricule ?? '—',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Bloc des boutons d'action (Notification + Settings)
        Row(
          children: [
            // Cloche notification
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    // Pastille des notifications non lues.
                    if (ref.watch(nombreNotificationsNonLuesProvider) > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.red,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10), // Espace entre les deux icônes

            // Bouton Paramètres (Settings)
            GestureDetector(
              onTap: onSettingsTap,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.settings_outlined, // Icône moderne style outline
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Rappel persistant tant que le dossier KYC n'a pas été validé par un
/// administrateur (`statut = EN_ATTENTE`). Ouvre un détail rassurant au tap :
/// ce qui se passe, et ce qui reste déjà utilisable en attendant.
class _BanniereVerificationEnCours extends StatelessWidget {
  const _BanniereVerificationEnCours();

  void _ouvrirDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _DetailVerificationSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _ouvrirDetail(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.orange.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.orange.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.hourglass_top_rounded,
                  color: AppColors.orange, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vérification de vos documents en cours',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Votre compte sera activé dès la validation. Touchez pour en savoir plus.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.orange, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Détail rassurant de l'état « en attente » : ce qui se passe, combien de
/// temps ça prend, et ce que l'utilisateur peut déjà faire en attendant.
class _DetailVerificationSheet extends StatelessWidget {
  const _DetailVerificationSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(top: 60),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
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
              const SizedBox(height: 24),
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.hourglass_top_rounded,
                      color: AppColors.orange, size: 30),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Vérification en cours',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),
              const Text(
                'Votre pièce d\'identité et vos informations ont bien été '
                'reçues. Notre équipe les vérifie avant d\'activer votre '
                'compte — vous recevrez une notification dès que ce sera fait.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13.5, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Déjà disponible en attendant',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    const _PointDisponible(
                        texte: 'Choisir votre compte mobile money principal'),
                    const SizedBox(height: 8),
                    const _PointDisponible(
                        texte: 'Configurer vos taux de prélèvement (CNPS, CMU, épargne…)'),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: 12),
                    const _PointIndisponible(
                        texte: 'Modifier votre profil et vos informations personnelles'),
                    const SizedBox(height: 8),
                    const _PointIndisponible(
                        texte: 'Ajouter de nouvelles cotisations personnalisées'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(0, 52)),
                  child: const Text('Compris'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PointDisponible extends StatelessWidget {
  final String texte;
  const _PointDisponible({required this.texte});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_rounded,
            color: AppColors.success, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texte,
            style: const TextStyle(
                fontSize: 12.5, color: AppColors.textPrimary, height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _PointIndisponible extends StatelessWidget {
  final String texte;
  const _PointIndisponible({required this.texte});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.lock_outline_rounded,
            color: AppColors.textHint, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texte,
            style: const TextStyle(
                fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
          ),
        ),
      ],
    );
  }
}

// ─── Carte solde ─────────────────────────────────────────────────────────────

class _SoldeCard extends StatelessWidget {
  final Solde solde;

  /// Récapitulatif du mois courant, pour le « Total prélevé » — `null` tant
  /// qu'il n'a pas fini de charger (le solde s'affiche déjà sans attendre).
  final Recapitulatif? recapitulatif;

  const _SoldeCard({required this.solde, this.recapitulatif});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'fr_FR');
    final totalPreleveMois = recapitulatif?.totalPrelevementsHorsEpargne;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Solde disponible',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${fmt.format(solde.disponible)} ${solde.devise}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _SoldeStat(
                label: 'Total épargné',
                value: '+${fmt.format(solde.epargne)} ${solde.devise}',
                color: const Color(0xFF7FFFB2),
              ),
              const SizedBox(width: 24),
              _SoldeStat(
                label: 'Prélevé ce mois',
                value: totalPreleveMois == null
                    ? '…'
                    : '-${fmt.format(totalPreleveMois)} ${solde.devise}',
                color: Colors.white54,
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const RecapitulatifGeneralScreen(),
              ),
            ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bar_chart_rounded,
                      color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Voir le récapitulatif détaillé',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoldeStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SoldeStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

// ─── Liste des transactions ───────────────────────────────────────────────────

class _TransactionsList extends StatelessWidget {
  final List<Operation> operations;
  const _TransactionsList({required this.operations});

  /// Pictogramme déduit du type d'opération renvoyé par l'API.
  static String _icone(Operation op) {
    final type = (op.type ?? op.libelle).toUpperCase();
    if (type.contains('CNPS')) return '🏛️';
    if (type.contains('CMU') || type.contains('AMU') || type.contains('SANTE')) {
      return '🏥';
    }
    if (type.contains('EPARGNE')) return '🏠';
    if (type.contains('MOBILE') || type.contains('VIREMENT')) return '📲';
    if (type.contains('COTISATION') || type.contains('PRELEV')) return '🧾';
    return op.estCredit ? '💰' : '🏦';
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'fr_FR');
    final dateFmt = DateFormat('dd MMM · HH:mm', 'fr_FR');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Transactions récentes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ToutesTransactionsScreen(),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_rounded,
                        color: AppColors.primaryBlue, size: 15),
                    SizedBox(width: 5),
                    Text(
                      'Voir tout',
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
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: operations.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          color: AppColors.textHint, size: 32),
                      SizedBox(height: 10),
                      Text(
                        'Aucune opération pour le moment.\nVos encaissements et prélèvements '
                        'apparaîtront ici.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: operations.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.border,
            ),
            itemBuilder: (_, i) {
              final tx = operations[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    // Icône
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: tx.estCredit
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFF5F5F5),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(_icone(tx),
                            style: const TextStyle(fontSize: 18)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Libellé + description + date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.libelle,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (tx.description != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              tx.estCredit
                                  ? 'De : ${tx.description}'
                                  : tx.description!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: tx.estCredit
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: tx.estCredit
                                    ? AppColors.primaryBlue
                                    : AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 3),
                          Text(
                            dateFmt.format(tx.date),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Montant
                    Text(
                      '${tx.estCredit ? '+' : '-'}${fmt.format(tx.montant)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: tx.estCredit
                            ? const Color(0xFF2E7D32)
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Comptes mobile money réels de l'utilisateur ──────────────────────────────

/// `#RRGGBB` → [Color] ; `null` si absent ou mal formé — jamais de couleur
/// devinée par nom d'opérateur côté mobile (voir `moyen_paiements.couleur`).
Color? _couleurDepuisHex(String? hex) {
  if (hex == null) return null;
  final nettoye = hex.trim().replaceFirst('#', '');
  if (nettoye.length != 6) return null;
  final valeur = int.tryParse(nettoye, radix: 16);
  return valeur == null ? null : Color(0xFF000000 | valeur);
}

/// Comptes triés avec le compte principal en tête — l'API les renvoie déjà
/// dans cet ordre, ce tri est une garantie supplémentaire côté client.
List<CompteMobileMoney> _triesPrincipalEnTete(List<CompteMobileMoney> comptes) {
  final tries = [...comptes];
  tries.sort((a, b) {
    if (a.estPrincipal == b.estPrincipal) return 0;
    return a.estPrincipal ? -1 : 1;
  });
  return tries;
}

// ─── Section cartes réseau (PageView) ────────────────────────────────────────

class _NetworkCardsSection extends ConsumerStatefulWidget {
  const _NetworkCardsSection();

  @override
  ConsumerState<_NetworkCardsSection> createState() =>
      _NetworkCardsSectionState();
}

class _NetworkCardsSectionState extends ConsumerState<_NetworkCardsSection> {
  final _pageController = PageController(viewportFraction: 0.88);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final comptesAsync = ref.watch(comptesMobileMoneyProvider);

    return comptesAsync.when(
      loading: () => const SizedBox(
        height: 230,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (erreur, _) => _CarteAucunCompte(
        message: erreur is ApiException
            ? erreur.message
            : 'Impossible de charger vos comptes mobile money.',
        onRetry: () =>
            ref.read(comptesMobileMoneyProvider.notifier).recharger(),
      ),
      data: (comptesBruts) {
        final comptes = _triesPrincipalEnTete(comptesBruts);
        if (comptes.isEmpty) {
          return const _CarteAucunCompte(
            message: 'Aucun compte mobile money configuré pour le moment. '
                'Ajoutez-en un depuis votre profil pour générer vos QR codes.',
          );
        }

        return Column(
          children: [
            // PageView des cartes — un seul compte : le PageView reste, sans
            // indicateurs de page superflus.
            SizedBox(
              height: 230,
              child: PageView.builder(
                controller: _pageController,
                itemCount: comptes.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) {
                  final compte = comptes[i];
                  return AnimatedScale(
                    scale: _currentPage == i ? 1.0 : 0.93,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: _NetworkCard(compte: compte),
                    ),
                  );
                },
              ),
            ),

            if (comptes.length > 1) ...[
              const SizedBox(height: 14),
              // Indicateurs de page
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(comptes.length, (i) {
                  final active = i == _currentPage;
                  final couleur = _couleurDepuisHex(
                        comptes[i].moyenPaiement?.couleur,
                      ) ??
                      AppColors.primaryBlue;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active ? couleur : AppColors.border,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// État vide ou d'erreur, à la place du carrousel.
class _CarteAucunCompte extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _CarteAucunCompte({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 230,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.qr_code_2_rounded,
              color: AppColors.textHint, size: 32),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 12.5, color: AppColors.textSecondary, height: 1.5),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ],
      ),
    );
  }
}

// ─── Carte d'un compte ────────────────────────────────────────────────────────

class _NetworkCard extends StatelessWidget {
  final CompteMobileMoney compte;

  const _NetworkCard({required this.compte});

  void _afficherMonQrCode(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => _QrScanPage(compte: compte),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final couleur =
        _couleurDepuisHex(compte.moyenPaiement?.couleur) ?? AppColors.primaryBlue;
    final qr = compte.qrPayload;

    return GestureDetector(
      onTap: qr == null ? null : () => _afficherMonQrCode(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [couleur, Color.lerp(couleur, Colors.black, 0.35)!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Motif décoratif générique (indépendant de l'opérateur).
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: CustomPaint(painter: _WaveBgPainter()),
              ),
            ),

            Positioned(
              top: 14,
              left: 18,
              right: 18,
              child: Row(
                children: [
                  _LogoMoyen(moyen: compte.moyenPaiement, taille: 26),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      compte.operateur,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (compte.estPrincipal)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Principal',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
                            child: qr == null
                                ? const Center(
                                    child: Icon(Icons.qr_code_2_rounded,
                                        color: AppColors.textHint, size: 40),
                                  )
                                : QrImageView(
                                    data: qr,
                                    version: QrVersions.auto,
                                    eyeStyle: const QrEyeStyle(
                                      eyeShape: QrEyeShape.square,
                                      color: Colors.black,
                                    ),
                                    dataModuleStyle: const QrDataModuleStyle(
                                      dataModuleShape: QrDataModuleShape.square,
                                      color: Colors.black,
                                    ),
                                    backgroundColor: Colors.white,
                                  ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(18),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_rounded,
                                  size: 12, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                'Scanner',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Logo réel du moyen de paiement (`logo_url`), repli sur une icône
/// générique s'il est absent ou ne charge pas — jamais de logo par opérateur
/// codé en dur.
class _LogoMoyen extends StatelessWidget {
  final MoyenPaiement? moyen;
  final double taille;

  const _LogoMoyen({required this.moyen, required this.taille});

  @override
  Widget build(BuildContext context) {
    final url = moyen?.logoUrl;
    return Container(
      width: taille,
      height: taille,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(taille * 0.3),
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null || url.isEmpty
          ? Icon(Icons.phone_android_rounded,
              color: Colors.white, size: taille * 0.6)
          : Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.phone_android_rounded,
                color: Colors.white,
                size: taille * 0.6,
              ),
            ),
    );
  }
}

// ─── Page QR scan plein écran ─────────────────────────────────────────────────

enum _ModeQr { carte, scanner }

/// Écran QR de l'accueil : affiche directement le QR code du compte (mode
/// « Ma carte »), avec une bascule en bas pour passer en mode « Scanner un
/// code » — sur le même écran, sans navigation séparée — et payer un compte
/// compatible.
class _QrScanPage extends ConsumerStatefulWidget {
  final CompteMobileMoney compte;

  const _QrScanPage({required this.compte});

  @override
  ConsumerState<_QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends ConsumerState<_QrScanPage> {
  _ModeQr _mode = _ModeQr.carte;

  // La caméra n'est créée (et démarrée — `autoStart` par défaut) que lorsque
  // [ScannerQrCorps] est effectivement construit ci-dessous, et libérée
  // (`dispose`) dès qu'on bascule sur « Ma carte » : pas besoin de piloter
  // manuellement son démarrage/arrêt ici.
  void _basculer(_ModeQr nouveauMode) {
    if (nouveauMode == _mode) return;
    setState(() => _mode = nouveauMode);
  }

  @override
  Widget build(BuildContext context) {
    final compte = widget.compte;
    final couleur =
        _couleurDepuisHex(compte.moyenPaiement?.couleur) ?? AppColors.primaryBlue;
    final qr = compte.qrPayload;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [couleur, Color.lerp(couleur, Colors.black, 0.35)!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _WaveBgPainter()),
            ),

            SafeArea(
              child: Column(
                children: [
                  // Barre de navigation
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        _LogoMoyen(moyen: compte.moyenPaiement, taille: 30),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            compte.operateur,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: _mode == _ModeQr.scanner
                        ? ScannerQrCorps(
                            compteSource: compte,
                            onIdentifie: (destinataire, qrScanne) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PaiementQrScreen(
                                    compteSource: compte,
                                    destinataire: destinataire,
                                    qrScanne: qrScanne,
                                  ),
                                ),
                              );
                            },
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Instruction haut
                              Text(
                                'Présentez ce code à l\'opérateur',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // QR code
                              Container(
                                width: 300,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                                      child: qr == null
                                          ? const SizedBox(
                                              width: 260,
                                              height: 260,
                                              child: Center(
                                                child: Icon(Icons.qr_code_2_rounded,
                                                    color: AppColors.textHint, size: 64),
                                              ),
                                            )
                                          : QrImageView(
                                              data: qr,
                                              version: QrVersions.auto,
                                              size: 260,
                                              eyeStyle: const QrEyeStyle(
                                                eyeShape: QrEyeShape.square,
                                                color: Colors.black,
                                              ),
                                              dataModuleStyle: const QrDataModuleStyle(
                                                dataModuleShape: QrDataModuleShape.square,
                                                color: Colors.black,
                                              ),
                                              backgroundColor: Colors.white,
                                            ),
                                    ),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: const BorderRadius.vertical(
                                          bottom: Radius.circular(24),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.camera_alt_rounded,
                                              size: 16, color: Colors.grey.shade600),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Scanner pour recevoir',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Numéro du compte
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  compte.numeroCompte,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),

                  // Bascule Scanner un code / Ma carte.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Row(
                        children: [
                          _SegmentBascule(
                            libelle: 'Scanner un code',
                            selectionne: _mode == _ModeQr.scanner,
                            onTap: () => _basculer(_ModeQr.scanner),
                          ),
                          _SegmentBascule(
                            libelle: 'Ma carte',
                            selectionne: _mode == _ModeQr.carte,
                            onTap: () => _basculer(_ModeQr.carte),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentBascule extends StatelessWidget {
  final String libelle;
  final bool selectionne;
  final VoidCallback onTap;

  const _SegmentBascule({
    required this.libelle,
    required this.selectionne,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selectionne ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            libelle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selectionne ? AppColors.textPrimary : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Wave background painter ─────────────────────────────────────────────────

class _WaveBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Grille de losanges (motif Wave)
    const spacing = 28.0;
    const half = spacing / 2;

    for (double y = -spacing; y < size.height + spacing; y += spacing) {
      for (double x = -spacing; x < size.width + spacing; x += spacing) {
        final path = Path()
          ..moveTo(x, y - half)
          ..lineTo(x + half, y)
          ..lineTo(x, y + half)
          ..lineTo(x - half, y)
          ..close();
        canvas.drawPath(path, paint);
      }
    }

    // Losanges pleins accentués (quelques-uns)
    final fillPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;

    final accents = [
      Offset(size.width * 0.15, size.height * 0.25),
      Offset(size.width * 0.80, size.height * 0.15),
      Offset(size.width * 0.70, size.height * 0.75),
      Offset(size.width * 0.10, size.height * 0.80),
    ];
    for (final center in accents) {
      const r = 18.0;
      final path = Path()
        ..moveTo(center.dx, center.dy - r)
        ..lineTo(center.dx + r, center.dy)
        ..lineTo(center.dx, center.dy + r)
        ..lineTo(center.dx - r, center.dy)
        ..close();
      canvas.drawPath(path, fillPaint);
    }
  }

  @override
  bool shouldRepaint(_WaveBgPainter _) => false;
}

// ─── Suivi cotisations ────────────────────────────────────────────────────────

class _CotisationTracker extends ConsumerStatefulWidget {
  const _CotisationTracker();

  @override
  ConsumerState<_CotisationTracker> createState() =>
      _CotisationTrackerState();
}

class _CotisationTrackerState extends ConsumerState<_CotisationTracker> {
  int _tab = 0;

  static const _moisLabels = [
    'Janvier','Février','Mars','Avril','Mai','Juin',
    'Juillet','Août','Septembre','Octobre','Novembre','Décembre',
  ];

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'fr_FR');
    final isMois = _tab == 0;

    // Cible : déclarée par l'utilisateur à l'inscription (montant de
    // cotisation CNPS mensuel visé), reportée sur l'année à défaut d'un
    // objectif annuel distinct — il n'existe pas de « cible » côté API,
    // seuls les montants réellement versés le sont.
    final utilisateur = ref.watch(utilisateurCourantProvider);
    final cibleMensuelle = utilisateur?.montantCotisationMensuelle ?? 0;
    final cible = isMois ? cibleMensuelle : cibleMensuelle * 12;

    final recapAsync = isMois
        ? ref.watch(recapitulatifProvider)
        : ref.watch(recapitulatifPeriodeProvider(PeriodeRecap.annee));

    final color = isMois ? AppColors.primaryBlue : AppColors.purple;
    final icon = isMois ? '📅' : '📆';
    final titre = isMois
        ? 'Ce mois — ${_moisLabels[DateTime.now().month - 1]}'
        : 'Annuel ${DateTime.now().year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre + tab switcher sur la même ligne
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mes cotisations retraite',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            _TabSwitcher(
              selected: _tab,
              onTap: (i) => setState(() => _tab = i),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'CNPS — Suivi de vos versements',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),

        // Carte animée
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: Container(
            key: ValueKey(_tab),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.10),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: recapAsync.when(
              loading: () => const SizedBox(
                height: 88,
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
              error: (erreur, _) => SizedBox(
                height: 88,
                child: Center(
                  child: Text(
                    erreur is ApiException
                        ? erreur.message
                        : 'Impossible de charger vos cotisations.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              data: (recap) {
                final verse = recap.totalCotisationCnps;
                final progress =
                    cible <= 0 ? 0.0 : (verse / cible).clamp(0.0, 1.0);
                return _ProgressBloc(
                  icon: icon,
                  titre: titre,
                  verse: verse,
                  cible: cible,
                  progress: progress,
                  fmt: fmt,
                  color: color,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// Tab switcher Mois / Année
class _TabSwitcher extends StatelessWidget {
  final int selected;
  final void Function(int) onTap;

  const _TabSwitcher({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.border.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _TabItem(label: 'Mois',  selected: selected == 0, onTap: () => onTap(0)),
          _TabItem(label: 'Année', selected: selected == 1, onTap: () => onTap(1)),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabItem({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ProgressBloc extends StatelessWidget {
  final String icon;
  final String titre;
  final double verse;
  final double cible;
  final double progress;
  final NumberFormat fmt;
  final Color color;

  const _ProgressBloc({
    required this.icon,
    required this.titre,
    required this.verse,
    required this.cible,
    required this.progress,
    required this.fmt,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête : icône + titre + pourcentage
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                titre,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              '$pct %',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Barre de progression
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            backgroundColor: color.withValues(alpha: 0.10),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),

        const SizedBox(height: 8),

        // Versé / Objectif sous la barre
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${fmt.format(verse)} FCFA',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              '${fmt.format(cible)} FCFA',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textHint,

              ),
              
            ),
          ],
        ),
      ],
    );
  }
}

