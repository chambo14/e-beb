import 'package:e_beb_app/core/network/api_response.dart';
import 'package:e_beb_app/core/utils/formatters.dart';
import 'package:e_beb_app/domain/entities/infos_plateforme.dart';
import 'package:e_beb_app/domain/entities/operation.dart';
import 'package:e_beb_app/domain/entities/paiement.dart';
import 'package:e_beb_app/domain/entities/session_auth.dart';
import 'package:e_beb_app/domain/entities/solde.dart';
import 'package:e_beb_app/domain/entities/type_cotisation.dart';
import 'package:e_beb_app/domain/entities/utilisateur.dart';
import 'package:flutter_test/flutter_test.dart';

/// Vérifie que le mapping tolère les variations de forme du back-end :
/// nombres en chaînes, booléens en entiers, listes paginées, clés alternatives.
void main() {
  group('ApiEnvelope', () {
    test('déballe une réponse standard', () {
      final env = ApiEnvelope.depuisJson({
        'success': true,
        'data': {'solde': '125000'},
        'message': 'OK',
      });

      expect(env.success, isTrue);
      expect(env.message, 'OK');
      expect(env.donnees['solde'], '125000');
    });

    test('gère une absence de data sans lever', () {
      final env = ApiEnvelope.depuisJson({
        'success': true,
        'message': 'Action effectuée.',
      });

      expect(env.donnees, isEmpty);
      expect(env.liste, isEmpty);
    });

    test('extrait la liste d\'une réponse paginée Laravel', () {
      final env = ApiEnvelope.depuisJson({
        'success': true,
        'data': {
          'data': [
            {'id': '1'},
            {'id': '2'},
          ],
          'meta': {'total': 2},
        },
      });

      expect(env.liste, hasLength(2));
      expect(env.pagination['total'], 2);
    });
  });

  group('Solde', () {
    test('parse les montants fournis en chaînes', () {
      final solde = Solde.depuisJson({
        'solde_disponible': '125 000.50',
        'total_recu': 450000,
        'devise': 'FCFA',
      });

      expect(solde.disponible, 125000.5);
      expect(solde.totalRecu, 450000);
      expect(solde.devise, 'FCFA');
    });

    test('retombe sur zéro quand le champ est absent', () {
      expect(Solde.depuisJson({}).disponible, 0);
    });
  });

  group('Utilisateur', () {
    test('lit un profil imbriqué sous « utilisateur »', () {
      final user = Utilisateur.depuisJson({
        'utilisateur': {
          'id': 'u-1',
          'nom': 'KONAN',
          'prenom': 'Jean-Baptiste',
          'telephone': '+2250709415535',
          'numero_cnps': '00345678901',
          'montant_revenu': '242000',
        },
      });

      expect(user.nomComplet, 'Jean-Baptiste KONAN');
      expect(user.initiales, 'JK');
      expect(user.numeroCnps, '00345678901');
      expect(user.montantRevenu, 242000);
    });

    test('ne plante pas sur un profil minimal', () {
      final user = Utilisateur.depuisJson({});
      expect(user.initiales, '?');
      expect(user.nomComplet, isEmpty);
    });
  });

  group('SessionAuth', () {
    test('accepte token et access_token', () {
      expect(SessionAuth.depuisJson({'token': 'abc'}).token, 'abc');
      expect(SessionAuth.depuisJson({'access_token': 'xyz'}).token, 'xyz');
      expect(SessionAuth.depuisJson({}).estValide, isFalse);
    });
  });

  group('TypeCotisation', () {
    test('rattache la règle de prélèvement et son mode de calcul', () {
      final type = TypeCotisation.depuisJson({
        'id': 't-1',
        'libelle': 'CNPS',
        'categorie': 'COTISATION SOCIALE',
        'regle_prelevement': {
          'type_calcul': 'POURCENTAGE',
          'valeur': 3,
          'est_actif': 1,
        },
      });

      expect(type.estConfigure, isTrue);
      expect(type.estActif, isTrue);
      expect(type.estPersonnalise, isFalse);
      expect(type.regle!.typeCalcul, TypeCalcul.pourcentage);
      expect(type.regle!.valeurAffichee, '3 %');
    });

    test('reconnaît une cotisation personnalisée', () {
      final type = TypeCotisation.depuisJson({
        'id': 't-2',
        'libelle': 'Axa assurance',
        'categorie': 'COTISATION PERSONNALISE',
      });

      expect(type.estPersonnalise, isTrue);
      expect(type.estConfigure, isFalse);
    });
  });

  group('Operation', () {
    test('déduit le sens débit depuis le type quand « sens » est absent', () {
      final op = Operation.depuisJson({
        'id': 'o-1',
        'type': 'PRELEVEMENT_CNPS',
        'montant': '10200',
      });

      expect(op.estCredit, isFalse);
      expect(op.montant, 10200);
    });

    test('respecte le sens explicite', () {
      final op = Operation.depuisJson({
        'id': 'o-2',
        'sens': 'CREDIT',
        'type': 'PRELEVEMENT',
        'montant': 5000,
      });

      expect(op.estCredit, isTrue);
    });
  });

  group('Paiement', () {
    test('calcule le net quand le serveur ne le fournit pas', () {
      final paiement = Paiement.depuisJson({
        'id': 'p-1',
        'montant_brut': 3500,
        'montant_preleve': 500,
        'prelevements': [
          {'libelle': 'CNPS', 'montant': 300},
          {'libelle': 'CMU', 'montant': 200},
        ],
      });

      expect(paiement.montantNet, 3000);
      expect(paiement.prelevements, hasLength(2));
    });
  });

  group('InfosPlateforme', () {
    test('parse la réponse réelle de l\'API', () {
      final infos = InfosPlateforme.depuisJson({
        'nom_plateforme': 'Ebeb finance',
        'slogan': 'Financer demain, aujourd\'hui',
        'logo_principal_url': 'https://ebebfinance.com/storage/logo.jpg',
      });

      expect(infos.nomPlateforme, 'Ebeb finance');
      expect(infos.logoPrincipalUrl, startsWith('https://'));
    });
  });

  group('Formatters.telephoneApi', () {
    test('normalise les saisies locales vers E.164', () {
      expect(Formatters.telephoneApi('07 09 41 55 35'), '+2250709415535');
      expect(Formatters.telephoneApi('0709415535'), '+2250709415535');
      expect(Formatters.telephoneApi('+2250709415535'), '+2250709415535');
      expect(Formatters.telephoneApi('002250709415535'), '+2250709415535');
      expect(Formatters.telephoneApi('2250709415535'), '+2250709415535');
    });
  });
}
