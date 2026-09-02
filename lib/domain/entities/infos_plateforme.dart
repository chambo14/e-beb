import '../../core/utils/json_utils.dart';

/// Informations publiques de la plateforme
/// (`/administration/public/infos-plateforme`).
class InfosPlateforme {
  final String nomPlateforme;
  final String? slogan;
  final String? logoPrincipalUrl;
  final String? logoFaviconUrl;
  final String? iconeApplicationUrl;

  /// Coordonnées de contact — affichées par l'écran « Support », modifiables
  /// depuis le panel d'administration sans mise à jour de l'application.
  final String? emailContact;
  final String? telephoneContact;
  final String? whatsapp;
  final String? siteWeb;

  const InfosPlateforme({
    required this.nomPlateforme,
    this.slogan,
    this.logoPrincipalUrl,
    this.logoFaviconUrl,
    this.iconeApplicationUrl,
    this.emailContact,
    this.telephoneContact,
    this.whatsapp,
    this.siteWeb,
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
      emailContact: Json.texte(json, ['email_contact']),
      telephoneContact: Json.texte(json, ['telephone_contact']),
      whatsapp: Json.texte(json, ['whatsapp']),
      siteWeb: Json.texte(json, ['site_web']),
    );
  }
}
