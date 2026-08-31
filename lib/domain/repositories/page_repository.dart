import '../entities/page_contenu.dart';

/// Contrat de lecture des pages de contenu CMS.
abstract class PageRepository {
  /// Contenu publié pour un type de page (`CGU`, `POLITIQUE_CONFIDENTIALITE`,
  /// ...), `null` si aucune page de ce type n'est actuellement publiée.
  Future<PageContenu?> parType(String type);
}
