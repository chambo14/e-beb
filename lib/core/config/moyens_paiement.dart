/// Identifiants des moyens de paiement mobile money.
///
/// ⚠️ À COMPLÉTER AVEC L'ÉQUIPE BACK-END.
///
/// `POST /espace-utilisateur/comptes-mobile-money` exige un `moyen_paiement_id`
/// (UUID), mais la collection Postman n'expose aucune route publique listant
/// ces moyens de paiement. Deux façons de lever ce point :
///
///  1. Le back-end ajoute une route publique (ex.
///     `GET /administration/public/moyens-paiement`) — c'est la solution
///     durable, et il suffira alors de brancher un provider dessus ;
///  2. En attendant, renseignez ici les UUID communiqués par l'équipe.
///
/// Tant qu'un opérateur n'a pas d'UUID, l'écran de configuration le présente
/// comme indisponible plutôt que d'envoyer une requête vouée à échouer.
class MoyensPaiement {
  const MoyensPaiement._();

  /// Libellé affiché → UUID attendu par l'API.
  ///
  /// Exemple relevé dans la collection Postman :
  ///   'Wave': '019edff7-b9a9-724b-ad81-90e7f4a9cab4',
  static const Map<String, String> identifiants = {
    // 'Wave': '…',
    // 'Orange Money': '…',
    // 'MTN MoMo': '…',
    // 'Moov Money': '…',
  };

  static String? idPour(String libelle) => identifiants[libelle];

  static bool estDisponible(String libelle) => identifiants.containsKey(libelle);

  /// `true` si aucun identifiant n'est encore renseigné.
  static bool get aucunConfigure => identifiants.isEmpty;
}
