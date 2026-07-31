import '../../core/storage/token_storage.dart';
import '../../core/utils/json_utils.dart';
import '../../domain/entities/demande_inscription.dart';
import '../../domain/entities/session_auth.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final TokenStorage _storage;

  const AuthRepositoryImpl(this._remote, this._storage);

  @override
  Future<String> inscrire(DemandeInscription demande) async {
    final reponse = await _remote.inscrire(demande);
    await _storage.ecrireTelephone(demande.telephone);

    // Le compte peut être créé alors que l'envoi de l'OTP a échoué : l'API le
    // signale dans un sous-objet `otp_envoi` distinct, sans passer en erreur.
    // Mieux vaut le dire que d'envoyer l'utilisateur attendre un code qui
    // n'arrivera pas — il pourra le redemander depuis l'écran suivant.
    final envoi = Json.objet(reponse.donnees, ['otp_envoi']);
    if (envoi != null && !Json.booleen(envoi, ['success'], defaut: true)) {
      return Json.texteOu(
        envoi,
        ['message'],
        'Compte créé, mais l\'envoi du code a échoué. '
            'Utilisez « Renvoyer le code ».',
      );
    }

    return reponse.message ?? 'Inscription enregistrée.';
  }

  @override
  Future<SessionAuth> verifierOtpInscription({
    required String telephone,
    required String codeOtp,
  }) async {
    final reponse = await _remote.verifierOtp(
      telephone: telephone,
      codeOtp: codeOtp,
    );
    return _ouvrirSession(reponse.donnees, telephone);
  }

  @override
  Future<String> renvoyerOtp(String telephone) async {
    final reponse = await _remote.renvoyerOtp(telephone);
    return reponse.message ?? 'Un nouveau code vous a été envoyé.';
  }

  @override
  Future<String> definirCodePin({
    required String telephone,
    required String codePin,
  }) async {
    final reponse = await _remote.definirCodePin(
      telephone: telephone,
      codePin: codePin,
    );
    return reponse.message ?? 'Code PIN enregistré.';
  }

  @override
  Future<String> demanderConnexion(String telephone) async {
    final reponse = await _remote.connexion(telephone);
    await _storage.ecrireTelephone(telephone);
    return reponse.message ?? 'Un code de connexion vous a été envoyé.';
  }

  @override
  Future<SessionAuth> confirmerConnexion({
    required String telephone,
    required String codeOtp,
  }) async {
    final reponse = await _remote.confirmerConnexion(
      telephone: telephone,
      codeOtp: codeOtp,
    );
    return _ouvrirSession(reponse.donnees, telephone);
  }

  @override
  Future<void> seDeconnecter() async {
    try {
      await _remote.deconnexion();
    } finally {
      // Même si le serveur refuse (jeton déjà expiré), la session locale part.
      await _storage.vider();
    }
  }

  @override
  Future<String?> tokenPersiste() => _storage.lireToken();

  @override
  Future<String?> telephonePersiste() => _storage.lireTelephone();

  @override
  Future<void> purgerSessionLocale() => _storage.vider();

  Future<SessionAuth> _ouvrirSession(
    Map<String, dynamic> donnees,
    String telephone,
  ) async {
    final session = SessionAuth.depuisJson(donnees);
    if (session.estValide) {
      await _storage.ecrireToken(session.token);
      await _storage.ecrireTelephone(telephone);
    }
    return session;
  }
}
