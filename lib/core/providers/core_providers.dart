import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../storage/token_storage.dart';

/// Stockage chiffré du jeton — instance unique pour toute l'application.
final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

/// Client HTTP unique.
///
/// La réaction au 401 (`onNonAuthentifie`) est câblée par le contrôleur de
/// session, afin que le noyau réseau ne dépende pas de la couche métier.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(tokenStorage: ref.watch(tokenStorageProvider));
});
