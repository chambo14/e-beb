import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../domain/entities/demande_inscription.dart';
import '../../domain/entities/recapitulatif.dart';
import '../../domain/entities/solde.dart';
import 'repository_providers.dart';
import 'session_provider.dart';

/// Solde courant. Rechargé automatiquement quand la session change.
final soldeProvider = FutureProvider<Solde>((ref) async {
  final session = ref.watch(sessionProvider);
  if (!session.estAuthentifie) return Solde.vide;
  return ref.watch(utilisateurRepositoryProvider).solde();
});

/// Récapitulatif des cotisations.
final recapitulatifProvider = FutureProvider<Recapitulatif>((ref) async {
  final session = ref.watch(sessionProvider);
  if (!session.estAuthentifie) return Recapitulatif.vide;
  return ref.watch(utilisateurRepositoryProvider).recapitulatif();
});

/// ViewModel des actions sur le profil (mise à jour, changement de code PIN).
class ProfilController extends AsyncNotifier<String?> {
  @override
  FutureOr<String?> build() => null;

  Future<bool> mettreAJour(MiseAJourProfil mise) async {
    if (mise.estVide) return true;
    state = const AsyncLoading();
    try {
      await ref.read(utilisateurRepositoryProvider).mettreAJourProfil(mise);
      // Le profil en session doit refléter la modification.
      await ref.read(sessionProvider.notifier).rafraichirUtilisateur();
      state = const AsyncData('Profil mis à jour.');
      return true;
    } on ApiException catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> modifierCodePin({
    required String ancienCodePin,
    required String nouveauCodePin,
  }) async {
    state = const AsyncLoading();
    try {
      final message = await ref
          .read(utilisateurRepositoryProvider)
          .modifierCodePin(
            ancienCodePin: ancienCodePin,
            nouveauCodePin: nouveauCodePin,
          );
      state = AsyncData(message);
      return true;
    } on ApiException catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  void reinitialiser() => state = const AsyncData(null);
}

final profilControllerProvider =
    AsyncNotifierProvider<ProfilController, String?>(ProfilController.new);
