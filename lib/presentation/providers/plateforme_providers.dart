import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/infos_plateforme.dart';
import 'repository_providers.dart';

/// Informations publiques (nom, slogan, logos). Route non authentifiée :
/// disponible dès le splash.
final infosPlateformeProvider = FutureProvider<InfosPlateforme>((ref) async {
  return ref.watch(plateformeRepositoryProvider).infos();
});
