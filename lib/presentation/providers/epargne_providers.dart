import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../domain/entities/objectif_epargne.dart';
import '../../domain/entities/type_cotisation.dart';
import 'repository_providers.dart';
import 'session_provider.dart';
import 'utilisateur_providers.dart';

/// ViewModel des objectifs d'épargne.
class ObjectifsEpargneController extends AsyncNotifier<List<ObjectifEpargne>> {
  @override
  Future<List<ObjectifEpargne>> build() async {
    final session = ref.watch(sessionProvider);
    if (!session.estAuthentifie) return const [];
    return ref.watch(epargneRepositoryProvider).objectifs();
  }

  Future<void> recharger() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(epargneRepositoryProvider).objectifs(),
    );
  }

  Future<bool> ajouter({
    required String libelle,
    required double montantCible,
    required DateTime dateLimite,
    required TypeCalcul typeCalcul,
    required double valeur,
    double montantEpargne = 0,
    bool estActif = true,
  }) => _muter(
    () => ref.read(epargneRepositoryProvider).ajouter(
      libelle: libelle,
      montantCible: montantCible,
      dateLimite: dateLimite,
      typeCalcul: typeCalcul,
      valeur: valeur,
      montantEpargne: montantEpargne,
      estActif: estActif,
    ),
  );

  Future<bool> modifier({
    required String id,
    required String libelle,
    required double montantCible,
    required DateTime dateLimite,
    required TypeCalcul typeCalcul,
    required double valeur,
    double? montantEpargne,
    bool? estActif,
  }) => _muter(
    () => ref.read(epargneRepositoryProvider).modifier(
      id: id,
      libelle: libelle,
      montantCible: montantCible,
      dateLimite: dateLimite,
      typeCalcul: typeCalcul,
      valeur: valeur,
      montantEpargne: montantEpargne,
      estActif: estActif,
    ),
  );

  Future<bool> supprimer(String id) =>
      _muter(() => ref.read(epargneRepositoryProvider).supprimer(id));

  Future<bool> _muter(Future<void> Function() action) async {
    final precedent = state;
    state = const AsyncLoading();
    try {
      await action();
      state = AsyncData(await ref.read(epargneRepositoryProvider).objectifs());
      // Une règle d'épargne modifie les prélèvements sur les encaissements.
      ref.invalidate(soldeProvider);
      return true;
    } on ApiException catch (e, st) {
      state = AsyncError<List<ObjectifEpargne>>(e, st).copyWithPrevious(precedent);
      return false;
    }
  }
}

final objectifsEpargneProvider =
    AsyncNotifierProvider<ObjectifsEpargneController, List<ObjectifEpargne>>(
      ObjectifsEpargneController.new,
    );

/// Total épargné, tous objectifs confondus.
final totalEpargneProvider = Provider<double>((ref) {
  final objectifs = ref.watch(objectifsEpargneProvider).valueOrNull;
  if (objectifs == null) return 0;
  return objectifs.fold<double>(0, (total, o) => total + o.montantEpargne);
});
