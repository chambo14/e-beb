import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/page_contenu.dart';
import 'repository_providers.dart';
import 'session_provider.dart';

/// Contenu publié d'une page CMS par type (`CGU`,
/// `POLITIQUE_CONFIDENTIALITE`, ...) — `null` si aucune page de ce type
/// n'est actuellement publiée.
///
/// `autoDispose` à dessein : sans lui, un premier passage sur l'écran avant
/// publication met `null` en cache pour toute la durée de vie de l'app — la
/// page publiée ensuite depuis le back-office n'apparaîtrait jamais sans
/// redémarrage. Avec `autoDispose`, le cache est vidé dès qu'on quitte
/// l'écran : chaque visite reflète l'état de publication réel du moment.
final pageContenuProvider =
    FutureProvider.autoDispose.family<PageContenu?, String>((ref, type) async {
  final session = ref.watch(sessionProvider);
  if (!session.estAuthentifie) return null;
  return ref.watch(pageRepositoryProvider).parType(type);
});
