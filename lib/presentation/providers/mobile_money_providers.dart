import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../domain/entities/compte_mobile_money.dart';
import 'repository_providers.dart';
import 'session_provider.dart';

/// ViewModel des comptes mobile money de l'utilisateur.
class ComptesMobileMoneyController
    extends AsyncNotifier<List<CompteMobileMoney>> {
  @override
  Future<List<CompteMobileMoney>> build() async {
    final session = ref.watch(sessionProvider);
    if (!session.estAuthentifie) return const [];
    return ref.watch(mobileMoneyRepositoryProvider).comptes();
  }

  Future<void> recharger() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(mobileMoneyRepositoryProvider).comptes(),
    );
  }

  Future<bool> ajouter({
    required String moyenPaiementId,
    required String numeroCompte,
    bool estPrincipal = false,
  }) => _muter(
    () => ref.read(mobileMoneyRepositoryProvider).ajouterCompte(
      moyenPaiementId: moyenPaiementId,
      numeroCompte: numeroCompte,
      estPrincipal: estPrincipal,
    ),
  );

  Future<bool> definirPrincipal(String compteId) => _muter(
    () => ref.read(mobileMoneyRepositoryProvider).definirPrincipal(compteId),
  );

  Future<bool> _muter(Future<void> Function() action) async {
    final precedent = state;
    state = const AsyncLoading();
    try {
      await action();
      state = AsyncData(
        await ref.read(mobileMoneyRepositoryProvider).comptes(),
      );
      return true;
    } on ApiException catch (e, st) {
      state = AsyncError<List<CompteMobileMoney>>(
        e,
        st,
      ).copyWithPrevious(precedent);
      return false;
    }
  }
}

final comptesMobileMoneyProvider =
    AsyncNotifierProvider<ComptesMobileMoneyController, List<CompteMobileMoney>>(
      ComptesMobileMoneyController.new,
    );

/// Compte sur lequel les virements sont effectués par défaut.
final comptePrincipalProvider = Provider<CompteMobileMoney?>((ref) {
  final comptes = ref.watch(comptesMobileMoneyProvider).valueOrNull;
  if (comptes == null || comptes.isEmpty) return null;
  for (final compte in comptes) {
    if (compte.estPrincipal) return compte;
  }
  return comptes.first;
});
