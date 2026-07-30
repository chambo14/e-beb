import 'package:e_beb_app/core/storage/token_storage.dart';

/// Remplace [TokenStorage] dans les tests : évite les canaux de plateforme de
/// flutter_secure_storage, indisponibles hors appareil.
class TokenStorageMemoire implements TokenStorage {
  String? _token;
  String? _telephone;

  TokenStorageMemoire({String? token, String? telephone})
    : _token = token,
      _telephone = telephone;

  @override
  Future<String?> lireToken() async => _token;

  @override
  Future<void> ecrireToken(String token) async => _token = token;

  @override
  Future<String?> lireTelephone() async => _telephone;

  @override
  Future<void> ecrireTelephone(String telephone) async =>
      _telephone = telephone;

  @override
  Future<void> vider() async {
    _token = null;
    _telephone = null;
  }
}
