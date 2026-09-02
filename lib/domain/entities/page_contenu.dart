import '../../core/utils/json_utils.dart';

/// Page de contenu CMS publiée (`/espace-utilisateur/pages/{type}`) —
/// Conditions générales, Avis de confidentialité, etc. `contenu` est du HTML
/// brut produit par l'éditeur riche du panel d'administration.
class PageContenu {
  final String id;
  final String titre;
  final String contenu;
  final String? typePage;
  final DateTime? publieLe;

  const PageContenu({
    required this.id,
    required this.titre,
    required this.contenu,
    this.typePage,
    this.publieLe,
  });

  factory PageContenu.depuisJson(Map<String, dynamic> json) {
    return PageContenu(
      id: Json.texteOu(json, ['id', 'uuid']),
      titre: Json.texteOu(json, ['titre'], '—'),
      contenu: Json.texteOu(json, ['contenu']),
      typePage: Json.texte(json, ['type_page']),
      publieLe: Json.date(json, ['publie_le']),
    );
  }
}
