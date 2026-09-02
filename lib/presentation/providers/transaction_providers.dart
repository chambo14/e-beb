import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../domain/entities/operation.dart';
import '../../domain/entities/paiement.dart';
import 'repository_providers.dart';
import 'session_provider.dart';
import 'utilisateur_providers.dart';

/// Filtre courant de l'historique des opérations.
final filtreOperationsProvider = StateProvider<FiltreOperations>(
  (ref) => FiltreOperations.aucun,
);

/// Historique des opérations, filtré par [filtreOperationsProvider].
final operationsProvider = FutureProvider<List<Operation>>((ref) async {
  final session = ref.watch(sessionProvider);
  if (!session.estAuthentifie) return const [];
  final filtre = ref.watch(filtreOperationsProvider);
  return ref.watch(transactionRepositoryProvider).operations(filtre);
});

/// Détail d'une opération.
final operationProvider = FutureProvider.family<Operation, String>((
  ref,
  id,
) async {
  return ref.watch(transactionRepositoryProvider).operation(id);
});

/// Paiements clients encaissés.
final paiementsProvider = FutureProvider<List<Paiement>>((ref) async {
  final session = ref.watch(sessionProvider);
  if (!session.estAuthentifie) return const [];
  return ref.watch(transactionRepositoryProvider).paiements();
});

/// Détail d'un paiement, prélèvements inclus.
final paiementProvider = FutureProvider.family<Paiement, String>((
  ref,
  id,
) async {
  return ref.watch(transactionRepositoryProvider).paiement(id);
});

/// Les cinq dernières opérations, pour l'aperçu de l'accueil.
final dernieresOperationsProvider = Provider<List<Operation>>((ref) {
  final operations = ref.watch(operationsProvider).valueOrNull ?? const [];
  return operations.take(5).toList(growable: false);
});

/// ViewModel d'encaissement d'un paiement client.
class EncaissementController extends AsyncNotifier<Paiement?> {
  @override
  Paiement? build() => null;

  Future<bool> encaisser({
    required String referenceExterne,
    required String qrCodeRef,
    required double montantBrut,
    String? description,
  }) async {
    state = const AsyncLoading();
    try {
      final paiement = await ref
          .read(transactionRepositoryProvider)
          .enregistrerPaiement(
            referenceExterne: referenceExterne,
            qrCodeRef: qrCodeRef,
            montantBrut: montantBrut,
            description: description,
          );
      state = AsyncData(paiement);
      // L'encaissement modifie solde, opérations et avancement des cotisations.
      ref.invalidate(soldeProvider);
      ref.invalidate(operationsProvider);
      ref.invalidate(paiementsProvider);
      ref.invalidate(recapitulatifProvider);
      return true;
    } on ApiException catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  void reinitialiser() => state = const AsyncData(null);
}

final encaissementControllerProvider =
    AsyncNotifierProvider<EncaissementController, Paiement?>(
      EncaissementController.new,
    );
