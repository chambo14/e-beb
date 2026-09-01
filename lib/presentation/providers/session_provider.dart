import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/providers/core_providers.dart';
import '../../domain/entities/session_auth.dart';
import '../../domain/entities/utilisateur.dart';
import 'repository_providers.dart';

enum StatutSession {
  /// Jeton pas encore lu depuis le stockage sécurisé.
  initial,
  authentifie,
  nonAuthentifie,
}

/// État global d'authentification, source de vérité pour le routage.
class EtatSession {
  final StatutSession statut;
  final Utilisateur? utilisateur;
  final String? telephone;

  /// Application verrouillée par mise en arrière-plan alors que la session
  /// (jeton Sanctum) est toujours valide : l'écran de verrouillage ne
  /// demande que le code PIN, jamais d'OTP. N'affecte pas [estAuthentifie]
  /// ni la déconnexion forcée sur 401 (statut [StatutSession.nonAuthentifie]
  /// distinct) : les deux mécanismes restent indépendants.
  final bool verrouille;

  const EtatSession({
    this.statut = StatutSession.initial,
    this.utilisateur,
    this.telephone,
    this.verrouille = false,
  });

  bool get estAuthentifie => statut == StatutSession.authentifie;
  bool get estInitial => statut == StatutSession.initial;

  EtatSession copyWith({
    StatutSession? statut,
    Utilisateur? utilisateur,
    String? telephone,
    bool? verrouille,
  }) => EtatSession(
    statut: statut ?? this.statut,
    utilisateur: utilisateur ?? this.utilisateur,
    telephone: telephone ?? this.telephone,
    verrouille: verrouille ?? this.verrouille,
  );
}

/// Contrôleur de session : restauration au démarrage, ouverture après OTP,
/// fermeture manuelle ou forcée par un 401.
class SessionController extends Notifier<EtatSession> {
  @override
  EtatSession build() {
    // Un 401 sur n'importe quelle requête ferme la session côté application.
    ref.watch(apiClientProvider).onNonAuthentifie = _surNonAuthentifie;
    return const EtatSession();
  }

  /// À appeler au lancement (splash) : recharge le jeton persisté et le profil.
  Future<void> restaurer() async {
    final repo = ref.read(authRepositoryProvider);
    final token = await repo.tokenPersiste();
    final telephone = await repo.telephonePersiste();

    if (token == null || token.isEmpty) {
      state = EtatSession(
        statut: StatutSession.nonAuthentifie,
        telephone: telephone,
      );
      return;
    }

    try {
      final utilisateur = await ref.read(utilisateurRepositoryProvider).details();
      state = EtatSession(
        statut: StatutSession.authentifie,
        utilisateur: utilisateur,
        telephone: telephone ?? utilisateur.telephone,
        // Jeton encore valide au démarrage à froid (l'application avait été
        // totalement fermée, pas seulement mise en arrière-plan) : on
        // verrouille quand même, le code PIN reste la seule porte d'entrée
        // tant que la session n'a pas expiré.
        verrouille: true,
      );
    } on ApiException catch (e) {
      // Jeton révoqué ou expiré : on repart proprement sur l'écran de connexion.
      if (e.estNonAuthentifie) {
        await repo.purgerSessionLocale();
      }
      state = EtatSession(
        statut: StatutSession.nonAuthentifie,
        telephone: telephone,
      );
    }
  }

  /// Ouvre la session après une vérification OTP réussie.
  Future<void> ouvrir(SessionAuth session, {String? telephone}) async {
    state = EtatSession(
      statut: StatutSession.authentifie,
      utilisateur: session.utilisateur,
      telephone: telephone ?? session.utilisateur?.telephone,
    );
    // L'utilisateur renvoyé avec le jeton de connexion est un modèle brut,
    // sans ses relations chargées (déclaration de revenu, documents KYC,
    // comptes mobile money...) — toujours incomplet, jamais `null`. On
    // recharge donc systématiquement le profil complet via `/details`.
    await rafraichirUtilisateur();
  }

  Future<void> rafraichirUtilisateur() async {
    try {
      final utilisateur = await ref.read(utilisateurRepositoryProvider).details();
      state = state.copyWith(
        statut: StatutSession.authentifie,
        utilisateur: utilisateur,
      );
    } on ApiException {
      // Silencieux : l'écran concerné affichera l'erreur via son propre provider.
    }
  }

  Future<void> deconnecter() async {
    final telephone = state.telephone;
    try {
      await ref.read(authRepositoryProvider).seDeconnecter();
    } finally {
      state = EtatSession(
        statut: StatutSession.nonAuthentifie,
        telephone: telephone,
      );
    }
  }

  /// Verrouille l'application (mise en arrière-plan). Sans effet si la
  /// session n'est pas authentifiée : on ne verrouille jamais l'écran de
  /// connexion lui-même.
  void verrouiller() {
    if (!state.estAuthentifie) return;
    state = state.copyWith(verrouille: true);
  }

  /// Déverrouille l'application après vérification réussie du code PIN.
  void deverrouiller() {
    state = state.copyWith(verrouille: false);
  }

  void _surNonAuthentifie() {
    if (state.statut == StatutSession.nonAuthentifie) return;
    final telephone = state.telephone;
    ref.read(authRepositoryProvider).purgerSessionLocale();
    state = EtatSession(
      statut: StatutSession.nonAuthentifie,
      telephone: telephone,
    );
  }
}

final sessionProvider = NotifierProvider<SessionController, EtatSession>(
  SessionController.new,
);

/// Raccourci lecture seule pour les écrans qui n'ont besoin que du profil.
final utilisateurCourantProvider = Provider<Utilisateur?>(
  (ref) => ref.watch(sessionProvider).utilisateur,
);
