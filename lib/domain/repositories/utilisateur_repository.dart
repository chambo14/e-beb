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

  /// Code PIN oublié — étape 1 : envoie un OTP par email. Lève une
  /// [ApiException] (message affichable tel quel) en cas d'échec, par
  /// exemple si aucune adresse email n'est renseignée sur le compte.
  Future<void> demanderReinitialisationPin();

  /// Code PIN oublié — étape 2 : vérifie le code reçu par email. Lève une
  /// [ApiException] (message affichable tel quel, ex. « Il vous reste N
  /// tentative(s) ») s'il est incorrect, expiré, ou après trop d'essais.
  Future<void> verifierOtpReinitialisationPin(String codeOtp);

  /// Code PIN oublié — étape 3 : définit le nouveau code PIN. N'aboutit que
  /// si l'étape 2 a réussi pour cet utilisateur (contrôlé côté serveur).
  Future<void> reinitialiserPin(String nouveauPin);
}
