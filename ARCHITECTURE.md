# Architecture — Ebeb Finance

Application Flutter en **Clean Architecture en couches**, état géré avec
**Riverpod** (les notifiers jouent le rôle de ViewModels du MVVM).

## Découpage

```
lib/
├── core/                     Socle technique, sans logique métier
│   ├── config/               URL de base, identifiants moyens de paiement
│   ├── network/              Dio, endpoints, enveloppe, erreurs normalisées
│   ├── storage/              Jeton Sanctum chiffré (flutter_secure_storage)
│   ├── providers/            ApiClient + TokenStorage exposés à Riverpod
│   ├── utils/                Parsing JSON tolérant, formatage FCFA/dates/tél.
│   └── constants/            Couleurs de marque
│
├── domain/                   Métier pur — aucune dépendance à Dio ni Flutter
│   ├── entities/             Utilisateur, Solde, Recapitulatif, Operation…
│   └── repositories/         Contrats (interfaces) uniquement
│
├── data/                     Implémentations
│   ├── datasources/          Appels HTTP bruts, un par groupe de la collection
│   └── repositories/         Contrats du domaine → entités
│
├── presentation/
│   └── providers/            Providers & notifiers Riverpod (ViewModels)
│
└── features/                 Vues (écrans)
    ├── auth/  onboarding/  account_setup/  home/  notifications/
```

**Règle de dépendance** : `features` → `presentation` → `domain` ← `data` → `core`.
Un écran n'importe jamais Dio ni une implémentation de repository.

## Flux d'une requête

1. L'écran appelle une méthode du notifier (`ref.read(xController.notifier)`).
2. Le notifier appelle le **contrat** du domaine, obtenu via
   `repository_providers.dart`.
3. L'implémentation délègue au datasource, qui passe par `ApiClient`.
4. `ApiClient` injecte `Authorization: Bearer …`, déballe
   `{success, data, message}` et transforme toute erreur en `ApiException`
   typée (`validation`, `nonAuthentifie`, `reseau`…).
5. Le repository mappe le JSON en entités via les helpers `Json.*`.
6. Le notifier expose un `AsyncValue` : l'écran affiche chargement, données
   ou message d'erreur.

## Points structurants

**Session.** `sessionProvider` est la source de vérité. Le splash appelle
`restaurer()` : si un jeton persiste et que `/details` répond, on entre
directement dans l'application. Toute réponse `401` déclenche
`onNonAuthentifie` sur `ApiClient`, qui purge la session ; `HomeScreen`
écoute ce changement et renvoie vers la connexion.

**Parsing tolérant.** Le back-end renvoie selon les routes des nombres en
chaînes (`"242000"`), des booléens en entiers (`1`) et des noms de champs
variables. Les entités passent par `core/utils/json_utils.dart`, qui accepte
plusieurs clés par champ et ne lève jamais sur un champ manquant.

**Method spoofing.** Laravel n'accepte pas de corps `multipart` sur PATCH/PUT :
`ApiClient.postForm(..., methodeSpoofee: 'patch')` envoie un POST avec
`_method=patch`, comme dans la collection Postman.

## Configuration

```bash
# URL de base (défaut : https://ebebfinance.com/api)
flutter run --dart-define=EBEB_API_BASE_URL=https://staging.ebebfinance.com/api

# Couper les logs HTTP
flutter run --dart-define=EBEB_HTTP_LOGS=false
```

## Cible web : le port compte

Le back-end n'autorise le CORS que pour une liste d'origines précise.
`http://localhost:3000` **en fait partie**, `http://localhost:5959` non — et le
navigateur ne dit pas pourquoi : Dio ne voit qu'un échec de transport, d'où un
message d'erreur trompeur (« vérifiez votre connexion »). Sur le web,
`ApiClient` requalifie donc ces échecs en message CORS explicite.

```bash
flutter run -d web-server --web-port 3000 --web-hostname localhost
```

C'est ce que fait `.claude/launch.json`. Changer ce port casse tous les appels
API. Pour vérifier quelles origines sont autorisées :

```bash
curl -s -D - -o /dev/null -X OPTIONS \
  -H "Origin: http://localhost:3000" \
  -H "Access-Control-Request-Method: POST" \
  https://ebebfinance.com/api/auth/connexion | grep -i access-control-allow
```

## Tests

```bash
flutter test                          # tout
flutter test --exclude-tags reseau    # sans appels à l'API de production
```

- `test/mapping_test.dart` — mapping JSON → entités (hors ligne).
- `test/api_integration_test.dart` — appels réels à l'API, sans effet de bord :
  route publique, `401`, `422`. Aucune inscription, aucun SMS envoyé.

## Points ouverts côté back-end

**`moyen_paiement_id` non listable.** `POST /espace-utilisateur/comptes-mobile-money`
exige un UUID de moyen de paiement, mais aucune route ne les liste. Voir
`lib/core/config/moyens_paiement.dart` : renseigner les UUID, ou brancher un
provider dès qu'une route publique existe. Tant que la table est vide, l'étape
de configuration du compte principal est présentée comme « bientôt disponible »
au lieu d'envoyer une requête vouée à échouer.

**Formes de réponse non figées.** Les routes authentifiées n'ont pas pu être
exécutées (elles exigent un OTP reçu par SMS). Les entités `Recapitulatif`,
`Solde`, `Operation`, `Paiement` et `NotificationApp` acceptent donc plusieurs
noms de clés. À confronter à une vraie réponse : si un champ reste à zéro,
ajouter sa clé réelle dans la liste passée à `Json.*` — un seul endroit à
toucher par champ.
