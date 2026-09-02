import '../../core/network/api_exception.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/demande_inscription.dart';
import '../../domain/entities/recapitulatif.dart';
import '../../domain/entities/solde.dart';
import '../../domain/entities/utilisateur.dart';
import '../../domain/repositories/utilisateur_repository.dart';
import '../datasources/utilisateur_remote_datasource.dart';

class UtilisateurRepositoryImpl implements UtilisateurRepository {
  final UtilisateurRemoteDataSource _remote;

  const UtilisateurRepositoryImpl(this._remote);

  @override
  Future<Utilisateur> details() async {
    final reponse = await _remote.details();
    return Utilisateur.depuisJson(reponse.donnees);
  }

  @override
  Future<Utilisateur> mettreAJourProfil(MiseAJourProfil mise) async {
    final reponse = await _remote.mettreAJourProfil(mise);
    final donnees = reponse.donnees;
    // Certaines routes renvoient uniquement un message : on relit le profil.
    if (donnees.isEmpty) return details();
    return Utilisateur.depuisJson(donnees);
  }

  @override
  Future<Solde> solde() async {
    final reponse = await _remote.solde();
    return Solde.depuisJson(reponse.donnees);
  }

  @override
  Future<Recapitulatif> recapitulatif({
    DateTime? dateDebut,
    DateTime? dateFin,
  }) async {
    final reponse = await _remote.recapitulatif(
      dateDebut: dateDebut == null ? null : Formatters.dateApi(dateDebut),
      dateFin: dateFin == null ? null : Formatters.dateApi(dateFin),
    );
    return Recapitulatif.depuisJson(reponse.donnees);
  }

  @override
  Future<String> modifierCodePin({
    required String ancienCodePin,
    required String nouveauCodePin,
  }) async {
    final reponse = await _remote.modifierCodePin(
      ancienCodePin: ancienCodePin,
      nouveauCodePin: nouveauCodePin,
    );
    return reponse.message ?? 'Code PIN modifié.';
  }

  @override
  Future<bool> verifierCodePin(String codePin) async {
    try {
      await _remote.verifierCodePin(codePin);
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 400) return false;
      rethrow;
    }
  }

  @override
  Future<void> demanderReinitialisationPin() async {
    await _remote.demanderReinitialisationCodePin();
  }

  @override
  Future<void> verifierOtpReinitialisationPin(String codeOtp) async {
    await _remote.verifierOtpReinitialisationCodePin(codeOtp);
  }

  @override
  Future<void> reinitialiserPin(String nouveauPin) async {
    await _remote.reinitialiserCodePin(nouveauPin);
  }
}
