/// Chemins de l'API, relatifs à [AppConfig.baseUrl].
///
/// Source : collection Postman « API UTILISATEUR FRONT ».
class ApiEndpoints {
  const ApiEndpoints._();

  // ---------------------------------------------------------------- Création de compte
  static const String inscription = '/auth/inscription';
  static const String otpVerifier = '/auth/otp/verifier';
  static const String otpRenvoyer = '/auth/otp/renvoyer';
  static const String configurerCodePin = '/auth/configurer-code-pin';

  // ---------------------------------------------------------------- Connexion
  static const String connexion = '/auth/connexion';
  static const String otpConfirmerConnexion = '/auth/otp/confirmerConnexion';

  // ---------------------------------------------------------------- Profil utilisateur
  static const String details = '/espace-utilisateur/details';
  static const String profil = '/espace-utilisateur/profil';
  static const String codePin = '/espace-utilisateur/code-pin';
  static const String verifierCodePin = '/espace-utilisateur/code-pin/verifier';
  // Code PIN oublié : identité prouvée par OTP (envoyé par email).
  static const String demanderReinitialisationCodePin =
      '/espace-utilisateur/code-pin/reinitialiser/demander-otp';
  static const String verifierOtpReinitialisationCodePin =
      '/espace-utilisateur/code-pin/reinitialiser/verifier-otp';
  static const String reinitialiserCodePin =
      '/espace-utilisateur/code-pin/reinitialiser';
  static const String deconnexion = '/espace-utilisateur/se-deconnecter';
  static const String recapitulatif = '/espace-utilisateur/recapitulatif';
  static const String solde = '/espace-utilisateur/solde';

  // ---------------------------------------------------------------- Règles de prélèvement
  static const String typesCotisation =
      '/espace-utilisateur/regle-prelevements/types';
  static const String configurerReglePrelevement =
      '/espace-utilisateur/regle-prelevements/configurer-regle-prelevement';

  // ---------------------------------------------------------------- Cotisations personnalisées
  static const String typesCotisationPersonnalises =
      '/espace-utilisateur/types-cotisation-personnalises';
  static const String suggestionsTypesCotisationPersonnalises =
      '$typesCotisationPersonnalises/suggestions';
  static String typeCotisationPersonnalise(String id) =>
      '$typesCotisationPersonnalises/$id';

  // ---------------------------------------------------------------- Transferts par QR code
  static const String identifierDestinataireQr =
      '/espace-utilisateur/paiements-qr/identifier';
  static const String envoyerTransfertQr =
      '/espace-utilisateur/paiements-qr/envoyer';

  // ---------------------------------------------------------------- Comptes mobile money
  static const String moyensPaiement = '/espace-utilisateur/moyens-paiement';
  static const String comptesMobileMoney =
      '/espace-utilisateur/comptes-mobile-money';
  static String compteMobileMoneyPrincipal(String id) =>
      '$comptesMobileMoney/$id/principal';

  // ---------------------------------------------------------------- Objectifs d'épargne
  static const String objectifsEpargne = '/espace-utilisateur/objectif-epargne';
  static String objectifEpargne(String id) => '$objectifsEpargne/$id';

  // ---------------------------------------------------------------- Paiements
  static const String paiementWebhook = '/paiements/webhook';
  static const String paiements = '/espace-utilisateur/paiements';
  static String paiement(String id) => '$paiements/$id';

  // ---------------------------------------------------------------- Opérations
  static const String operations = '/espace-utilisateur/operations';
  static String operation(String id) => '$operations/$id';

  // ---------------------------------------------------------------- Notifications
  static const String notifications = '/espace-utilisateur/notifications';
  static const String notificationsNonLues =
      '/espace-utilisateur/notifications/non-lues';
  static const String notificationsToutesLues =
      '/espace-utilisateur/notifications/marquer-toutes-lues';
  static String notificationLue(String id) => '$notifications/$id/lue';

  // ---------------------------------------------------------------- Pages CMS
  static String page(String type) => '/espace-utilisateur/pages/$type';

  // ---------------------------------------------------------------- Support
  static const String supportSignaler = '/espace-utilisateur/support/signaler';

  // ---------------------------------------------------------------- Public
  static const String infosPlateforme =
      '/administration/public/infos-plateforme';
}
