import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persistance chiffrée du jeton Sanctum et de l'identité de session.
///
/// Le jeton ne transite jamais par SharedPreferences : Keychain (iOS) /
/// EncryptedSharedPreferences (Android).
class TokenStorage {
  static const _cleToken = 'ebeb_token';
  static const _cleTelephone = 'ebeb_telephone';

  final FlutterSecureStorage _storage;

  TokenStorage([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
          );

  /// Cache mémoire : évite un appel plateforme sur chaque requête HTTP.
  String? _tokenCache;
  bool _tokenCharge = false;

  Future<String?> lireToken() async {
    if (_tokenCharge) return _tokenCache;
    _tokenCache = await _storage.read(key: _cleToken);
    _tokenCharge = true;
    return _tokenCache;
  }

  Future<void> ecrireToken(String token) async {
    _tokenCache = token;
    _tokenCharge = true;
    await _storage.write(key: _cleToken, value: token);
  }

  Future<String?> lireTelephone() => _storage.read(key: _cleTelephone);

  Future<void> ecrireTelephone(String telephone) =>
      _storage.write(key: _cleTelephone, value: telephone);

  Future<void> vider() async {
    _tokenCache = null;
    _tokenCharge = true;
    await _storage.delete(key: _cleToken);
    await _storage.delete(key: _cleTelephone);
  }
}
