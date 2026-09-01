import '../entities/demande_inscription.dart';
import '../entities/recapitulatif.dart';
import '../entities/solde.dart';
import '../entities/utilisateur.dart';

/// Contrat de l'espace utilisateur : profil, solde, récapitulatif, code PIN.
abstract class UtilisateurRepository {
  Future<Utilisateur> details();

  Future<Utilisateur> mettreAJourProfil(MiseAJourProfil mise);

  Future<Solde> solde();

  /// Sans paramètre : mois courant. Avec [dateDebut]/[dateFin] : récapitulatif
  /// sur cet intervalle (permet une vue par semaine ou par année).
  Future<Recapitulatif> recapitulatif({DateTime? dateDebut, DateTime? dateFin});

  Future<String> modifierCodePin({
    required String ancienCodePin,
    required String nouveauCodePin,
  });

  /// Déverrouillage de l'application (session déjà valide) : `true` si le
  /// code PIN est correct, `false` s'il est incorrect. Toute autre erreur
  /// (réseau, serveur…) est propagée telle quelle.
  Future<bool> verifierCodePin(String codePin);
}
