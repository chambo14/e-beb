import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../domain/entities/type_cotisation.dart';
import 'repository_providers.dart';
import 'session_provider.dart';
import 'utilisateur_providers.dart';

/// ViewModel des types de cotisation et de leurs règles de prélèvement.
///
/// Toute mutation recharge la liste puis invalide le récapitulatif, dont les
/// montants dépendent des règles actives.
class CotisationsController extends AsyncNotifier<List<TypeCotisation>> {
  @override
  Future<List<TypeCotisation>> build() async {
    final session = ref.watch(sessionProvider);
    if (!session.estAuthentifie) return const [];
    return ref.watch(cotisationRepositoryProvider).typesDisponibles();
  }

  Future<void> recharger() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(cotisationRepositoryProvider).typesDisponibles(),
    );
  }

  /// Remplace directement les données sans passer par `AsyncLoading` : évite
  /// que les écrans utilisant `.when(loading: ...)` sur ce provider ne
  /// démontent leur contenu (perte de l'état local en cours) le temps du
  /// rafraîchissement — utile après une mutation où l'écran appelant gère
  /// déjà son propre indicateur de progression.
  void definirDonnees(List<TypeCotisation> donnees) {
    state = AsyncData(donnees);
  }

  Future<bool> configurerRegle({
    required String typeCotisationId,
    required TypeCalcul typeCalcul,
    required double valeur,
    bool estActif = true,
  }) => _muter(
    () => ref.read(cotisationRepositoryProvider).configurerRegle(
      typeCotisationId: typeCotisationId,
      typeCalcul: typeCalcul,
      valeur: valeur,
      estActif: estActif,
    ),
  );

  /// Active ou désactive une règle existante en conservant son paramétrage.
  Future<bool> basculerActivation(TypeCotisation type, bool actif) {
    final regle = type.regle;
    if (regle == null) return Future.value(false);
    return configurerRegle(
      typeCotisationId: type.id,
      typeCalcul: regle.typeCalcul,
      valeur: regle.valeur,
      estActif: actif,
    );
  }

  Future<bool> ajouterTypePersonnalise({
    required String libelle,
    required String code,
    required double montantPaiementMensuel,
    String? description,
    String? categorie,
  }) => _muter(
    () => ref.read(cotisationRepositoryProvider).ajouterTypePersonnalise(
      libelle: libelle,
      code: code,
      montantPaiementMensuel: montantPaiementMensuel,
      description: description,
      categorie: categorie,
    ),
  );

  Future<bool> modifierTypePersonnalise({
    required String id,
    required String libelle,
    required String code,
    required double montantPaiementMensuel,
    String? description,
  }) => _muter(
    () => ref.read(cotisationRepositoryProvider).modifierTypePersonnalise(
      id: id,
      libelle: libelle,
      code: code,
      montantPaiementMensuel: montantPaiementMensuel,
      description: description,
    ),
  );

  Future<bool> supprimerTypePersonnalise(String id) => _muter(
    () => ref.read(cotisationRepositoryProvider).supprimerTypePersonnalise(id),
  );

  /// Exécute une mutation puis resynchronise la liste et le récapitulatif.
  Future<bool> _muter(Future<void> Function() action) async {
    final precedent = state;
    state = const AsyncLoading();
    try {
      await action();
      state = AsyncData(
        await ref.read(cotisationRepositoryProvider).typesDisponibles(),
      );
      ref.invalidate(recapitulatifProvider);
      return true;
    } on ApiException catch (e, st) {
      // On garde la liste précédente affichable tout en signalant l'erreur.
      state = AsyncError<List<TypeCotisation>>(e, st).copyWithPrevious(precedent);
      return false;
    }
  }
}

final cotisationsControllerProvider =
    AsyncNotifierProvider<CotisationsController, List<TypeCotisation>>(
      CotisationsController.new,
    );

/// Suggestions de types de cotisations personnalisés déjà créés par d'autres
/// utilisateurs — pour proposer une saisie cohérente sans dupliquer les
/// informations communes. Chargées une fois par session.
final suggestionsTypesCotisationProvider =
    FutureProvider<List<SuggestionTypeCotisation>>((ref) async {
  final session = ref.watch(sessionProvider);
  if (!session.estAuthentifie) return const [];
  return ref.watch(cotisationRepositoryProvider).suggestionsTypesPersonnalises();
});

/// Cotisations créées par l'utilisateur (catégorie « personnalisée »).
final cotisationsPersonnaliseesProvider = Provider<List<TypeCotisation>>((ref) {
  return ref
          .watch(cotisationsControllerProvider)
          .valueOrNull
          ?.where((t) => t.estPersonnalise)
          .toList(growable: false) ??
      const [];
});

/// Cotisations obligatoires proposées par la plateforme (CNPS, CMU…).
final cotisationsPlateformeProvider = Provider<List<TypeCotisation>>((ref) {
  return ref
          .watch(cotisationsControllerProvider)
          .valueOrNull
          ?.where((t) => !t.estPersonnalise)
          .toList(growable: false) ??
      const [];
});
