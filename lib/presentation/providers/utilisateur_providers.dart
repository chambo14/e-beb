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

/// Récapitulatif des cotisations (mois courant, comportement par défaut).
final recapitulatifProvider = FutureProvider<Recapitulatif>((ref) async {
  final session = ref.watch(sessionProvider);
  if (!session.estAuthentifie) return Recapitulatif.vide;
  return ref.watch(utilisateurRepositoryProvider).recapitulatif();
});

/// Période sélectionnable pour le récapitulatif général des prélèvements.
enum PeriodeRecap {
  semaine('Cette semaine'),
  mois('Ce mois'),
  annee('Cette année');

  final String libelle;
  const PeriodeRecap(this.libelle);

  /// Bornes `[début, fin]` couvrant la période, calculées côté client — le
  /// back-end accepte un intervalle libre (`date_debut`/`date_fin`) et ne
  /// connaît nativement que le découpage mensuel.
  (DateTime, DateTime) bornes(DateTime maintenant) {
    switch (this) {
      case PeriodeRecap.semaine:
        final debutSemaine = maintenant.subtract(
          Duration(days: maintenant.weekday - 1),
        );
        final debut =
            DateTime(debutSemaine.year, debutSemaine.month, debutSemaine.day);
        return (debut, debut.add(const Duration(days: 6)));
      case PeriodeRecap.mois:
        final debut = DateTime(maintenant.year, maintenant.month, 1);
        final finMois = DateTime(maintenant.year, maintenant.month + 1, 0);
        return (debut, finMois);
      case PeriodeRecap.annee:
        return (DateTime(maintenant.year, 1, 1), DateTime(maintenant.year, 12, 31));
    }
  }
}

/// Récapitulatif général, filtré par période (semaine / mois / année) — pour
/// l'écran détaillé ouvert depuis la carte de solde.
final recapitulatifPeriodeProvider =
    FutureProvider.family<Recapitulatif, PeriodeRecap>((ref, periode) async {
  final session = ref.watch(sessionProvider);
  if (!session.estAuthentifie) return Recapitulatif.vide;
  final (debut, fin) = periode.bornes(DateTime.now());
  return ref
      .watch(utilisateurRepositoryProvider)
      .recapitulatif(dateDebut: debut, dateFin: fin);
});

/// Récapitulatif d'un mois précis (navigable) — pour l'écran « par type de
/// cotisation », qui compare mois par mois l'objectif et le montant versé.
final recapitulatifMoisProvider =
    FutureProvider.family<Recapitulatif, ({int mois, int annee})>(
        (ref, cle) async {
  final session = ref.watch(sessionProvider);
  if (!session.estAuthentifie) return Recapitulatif.vide;
  final debut = DateTime(cle.annee, cle.mois, 1);
  final fin = DateTime(cle.annee, cle.mois + 1, 0);
  return ref
      .watch(utilisateurRepositoryProvider)
      .recapitulatif(dateDebut: debut, dateFin: fin);
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
