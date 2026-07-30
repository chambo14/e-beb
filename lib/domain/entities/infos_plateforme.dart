import '../../core/utils/json_utils.dart';

/// Informations publiques de la plateforme
/// (`/administration/public/infos-plateforme`).
class InfosPlateforme {
  final String nomPlateforme;
  final String? slogan;
  final String? logoPrincipalUrl;
  final String? logoFaviconUrl;
  final String? iconeApplicationUrl;

  const InfosPlateforme({
    required this.nomPlateforme,
    this.slogan,
    this.logoPrincipalUrl,
    this.logoFaviconUrl,
    this.iconeApplicationUrl,
  });

  static const defaut = InfosPlateforme(
    nomPlateforme: 'Ebeb Finance',
    slogan: 'Financer demain, aujourd\'hui',
  );

  factory InfosPlateforme.depuisJson(Map<String, dynamic> json) {
    return InfosPlateforme(
      nomPlateforme: Json.texteOu(json, [
        'nom_plateforme',
        'nom',
      ], defaut.nomPlateforme),
      slogan: Json.texte(json, ['slogan']),
      logoPrincipalUrl: Json.texte(json, ['logo_principal_url', 'logo_url']),
      logoFaviconUrl: Json.texte(json, ['logo_favicon_url']),
      iconeApplicationUrl: Json.texte(json, ['icone_application_url']),
    );
  }
}
