import '../../core/utils/json_utils.dart';
import 'utilisateur.dart';

/// Résultat d'une vérification OTP réussie : jeton Sanctum + profil.
class SessionAuth {
  final String token;
  final Utilisateur? utilisateur;

  const SessionAuth({required this.token, this.utilisateur});

  bool get estValide => token.isNotEmpty;

  /// L'API place le jeton sous `token`, `access_token` ou `data.token` selon
  /// la route ; le profil peut être absent.
  factory SessionAuth.depuisJson(Map<String, dynamic> json) {
    final token = Json.texteOu(json, [
      'token',
      'access_token',
      'accessToken',
      'plainTextToken',
    ]);

    final profilJson = Json.objet(json, ['utilisateur', 'user', 'profil']);

    return SessionAuth(
      token: token,
      utilisateur: profilJson == null
          ? null
          : Utilisateur.depuisJson(profilJson),
    );
  }
}
