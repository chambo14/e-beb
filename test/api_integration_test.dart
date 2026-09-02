@Tags(['reseau'])
library;

import 'package:e_beb_app/core/network/api_client.dart';
import 'package:e_beb_app/core/network/api_endpoints.dart';
import 'package:e_beb_app/core/network/api_exception.dart';
import 'package:e_beb_app/data/datasources/plateforme_remote_datasource.dart';
import 'package:e_beb_app/data/repositories/plateforme_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/token_storage_memoire.dart';

/// Tests d'intégration contre l'API de production.
///
/// Ils n'appellent que des routes sans effet de bord : l'endpoint public, et
/// des cas d'erreur (401 / 422). Aucune inscription ni aucun envoi de SMS.
///
///   flutter test test/api_integration_test.dart
void main() {
  late ApiClient client;

  setUp(() {
    client = ApiClient(tokenStorage: TokenStorageMemoire());
  });

  test('infos plateforme : la route publique répond et se mappe', () async {
    final repo = PlateformeRepositoryImpl(PlateformeRemoteDataSource(client));

    final infos = await repo.infos();

    expect(infos.nomPlateforme, isNotEmpty);
    expect(infos.logoPrincipalUrl, startsWith('http'));
  });

  test('sans jeton, une route protégée lève une erreur non authentifié', () async {
    await expectLater(
      client.get(ApiEndpoints.details),
      throwsA(
        isA<ApiException>()
            .having((e) => e.type, 'type', ApiErrorType.nonAuthentifie)
            .having((e) => e.statusCode, 'statusCode', 401),
      ),
    );
  });

  test('un numéro invalide remonte les erreurs de validation par champ', () async {
    await expectLater(
      client.post(ApiEndpoints.connexion, body: {'telephone': 'abc'}),
      throwsA(
        isA<ApiException>()
            .having((e) => e.type, 'type', ApiErrorType.validation)
            .having((e) => e.statusCode, 'statusCode', 422)
            .having((e) => e.erreurPour('telephone'), 'erreur téléphone', isNotNull),
      ),
    );
  });

  test('le callback 401 est déclenché une fois par réponse non authentifiée', () async {
    var appels = 0;
    client.onNonAuthentifie = () => appels++;

    // L'assertion porte sur le type : si le serveur répond autre chose qu'un
    // 401 (429 sous charge, coupure réseau), l'échec est explicite.
    await expectLater(
      client.get(ApiEndpoints.solde),
      throwsA(
        isA<ApiException>()
            .having((e) => e.type, 'type', ApiErrorType.nonAuthentifie),
      ),
    );
    expect(appels, 1);
  });
}
