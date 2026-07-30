import '../entities/demande_inscription.dart';
import '../entities/session_auth.dart';

/// Contrat d'authentification.
///
/// Toutes les méthodes lèvent une [ApiException] en cas d'échec ; le jeton
/// renvoyé par [verifierOtpInscription] / [confirmerConnexion] est persisté par
/// l'implémentation.
abstract class AuthRepository {
  /// Crée le compte et déclenche l'envoi d'un OTP. Renvoie le message serveur.
  Future<String> inscrire(DemandeInscription demande);

  /// Valide l'OTP reçu après inscription.
  Future<SessionAuth> verifierOtpInscription({
    required String telephone,
    required String codeOtp,
  });

  /// Redemande l'envoi d'un code OTP.
  Future<String> renvoyerOtp(String telephone);

  /// Définit le code PIN à la fin de l'inscription.
  Future<String> definirCodePin({
    required String telephone,
    required String codePin,
  });

  /// Déclenche l'envoi d'un OTP de connexion pour un compte existant.
  Future<String> demanderConnexion(String telephone);

  /// Valide l'OTP de connexion et ouvre la session.
  Future<SessionAuth> confirmerConnexion({
    required String telephone,
    required String codeOtp,
  });

  /// Invalide le jeton côté serveur puis localement.
  Future<void> seDeconnecter();

  /// Jeton persisté d'une session précédente, `null` si aucune.
  Future<String?> tokenPersiste();

  /// Dernier numéro utilisé, pour pré-remplir les écrans.
  Future<String?> telephonePersiste();

  /// Purge la session locale sans appeler le serveur (cas du 401).
  Future<void> purgerSessionLocale();
}
