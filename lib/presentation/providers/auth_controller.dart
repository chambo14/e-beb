import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/demande_inscription.dart';
import 'repository_providers.dart';
import 'session_provider.dart';

/// ViewModel des parcours d'authentification.
///
/// L'état porte le dernier message serveur ; `isLoading` et `error` alimentent
/// directement les écrans. Les méthodes renvoient `true` en cas de succès pour
/// piloter la navigation.
class AuthController extends AsyncNotifier<String?> {
  @override
  FutureOr<String?> build() => null;

  /// Étape 1 de la connexion : envoi de l'OTP au numéro saisi.
  Future<bool> demanderConnexion(String telephoneSaisi) {
    final telephone = Formatters.telephoneApi(telephoneSaisi);
    return _executer(
      () => ref.read(authRepositoryProvider).demanderConnexion(telephone),
    );
  }

  /// Étape 2 de la connexion : validation de l'OTP et ouverture de session.
  Future<bool> confirmerConnexion({
    required String telephoneSaisi,
    required String codeOtp,
  }) async {
    final telephone = Formatters.telephoneApi(telephoneSaisi);
    state = const AsyncLoading();
    try {
      final session = await ref
          .read(authRepositoryProvider)
          .confirmerConnexion(telephone: telephone, codeOtp: codeOtp);
      await ref
          .read(sessionProvider.notifier)
          .ouvrir(session, telephone: telephone);
      state = const AsyncData('Connexion réussie.');
      return true;
    } on ApiException catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// Création de compte (KYC complet + pièces jointes).
  Future<bool> inscrire(DemandeInscription demande) => _executer(
    () => ref.read(authRepositoryProvider).inscrire(demande),
  );

  /// Validation de l'OTP reçu après inscription.
  Future<bool> verifierOtpInscription({
    required String telephoneSaisi,
    required String codeOtp,
  }) async {
    final telephone = Formatters.telephoneApi(telephoneSaisi);
    state = const AsyncLoading();
    try {
      final session = await ref
          .read(authRepositoryProvider)
          .verifierOtpInscription(telephone: telephone, codeOtp: codeOtp);
      // La session n'est ouverte que si le serveur a délivré un jeton ; sinon
      // l'utilisateur doit encore définir son code PIN.
      if (session.estValide) {
        await ref
            .read(sessionProvider.notifier)
            .ouvrir(session, telephone: telephone);
      }
      state = const AsyncData('Numéro vérifié.');
      return true;
    } on ApiException catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> renvoyerOtp(String telephoneSaisi) {
    final telephone = Formatters.telephoneApi(telephoneSaisi);
    return _executer(
      () => ref.read(authRepositoryProvider).renvoyerOtp(telephone),
    );
  }

  /// Définition du code PIN en fin d'inscription : ouvre la session (jeton
  /// persisté) comme une connexion classique, faute de quoi les écrans
  /// suivants (configuration du compte principal, etc.) n'auraient aucun
  /// jeton à joindre à leurs appels API.
  Future<bool> definirCodePin({
    required String telephoneSaisi,
    required String codePin,
  }) async {
    final telephone = Formatters.telephoneApi(telephoneSaisi);
    state = const AsyncLoading();
    try {
      final session = await ref
          .read(authRepositoryProvider)
          .definirCodePin(telephone: telephone, codePin: codePin);
      await ref
          .read(sessionProvider.notifier)
          .ouvrir(session, telephone: telephone);
      state = const AsyncData('Code PIN configuré avec succès.');
      return true;
    } on ApiException catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> seDeconnecter() async {
    state = const AsyncLoading();
    try {
      await ref.read(sessionProvider.notifier).deconnecter();
      state = const AsyncData('Vous êtes déconnecté.');
      return true;
    } on ApiException catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// Efface l'erreur affichée (ex. quand l'utilisateur recommence à saisir).
  void reinitialiser() => state = const AsyncData(null);

  Future<bool> _executer(Future<String> Function() action) async {
    state = const AsyncLoading();
    try {
      final message = await action();
      state = AsyncData(message);
      return true;
    } on ApiException catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, String?>(
  AuthController.new,
);

/// Message d'erreur prêt à afficher, `null` si aucune erreur.
final messageErreurAuthProvider = Provider<String?>((ref) {
  final erreur = ref.watch(authControllerProvider).error;
  if (erreur == null) return null;
  if (erreur is ApiException) return erreur.message;
  return 'Une erreur inattendue est survenue.';
});
