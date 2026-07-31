import 'dart:typed_data';

import '../../core/utils/formatters.dart';

/// Pièce jointe transmise à l'inscription.
///
/// On transporte les octets plutôt qu'un chemin : sur le web il n'y a pas de
/// système de fichiers, et `MultipartFile.fromFile` y est indisponible.
class FichierJoint {
  final String nom;
  final Uint8List octets;

  const FichierJoint({required this.nom, required this.octets});
}

/// Payload complet de `POST /auth/inscription` (multipart).
///
/// Champs obligatoires et optionnels calqués sur les règles de validation du
/// back-end (vérifiées le 28/07/2026) : `sexe`, `numero_cnps`, `numero_cmu`,
/// `lieu_naissance`, `profession`, `village` et `adresse_postale` sont
/// facultatifs ; `email` est requis.
///
/// Les trois pièces jointes (`url_recto`, `url_verso`, `url_selfie`) sont des
/// chemins de fichiers locaux — images uniquement, la conversion en
/// `MultipartFile` est faite par la couche data.
class DemandeInscription {
  // Identité
  final String nom;
  final String prenom;
  final String telephone;
  final String email;
  final DateTime dateNaissance;
  final String situationFamiliale;
  final String? sexe;
  final String? lieuNaissance;

  // Sécurité sociale
  final String? numeroCnps;
  final String? numeroCmu;

  // Adresse
  final String ville;
  final String quartier;
  final String? village;
  final String? adressePostale;

  // Activité
  final String metier;
  final String? profession;
  final String categorieProfessionnelle;
  final double montantRevenu;
  final DateTime dateDebutActivite;
  final String villeActivite;
  final String quartierActivite;
  final String communeSousPrefectureActivite;

  // Pièce d'identité
  final String typeDocument;
  final String numeroDocument;
  final DateTime documentEtablieLe;
  final DateTime documentExpireLe;
  final FichierJoint recto;
  final FichierJoint verso;
  final FichierJoint selfie;

  // Cotisations souscrites
  final double montantCotisationRegimeBase;
  final double montantCotisationRegimeComplementaire;
  final double montantCotisationMensuelle;
  final double montantCotisationTrimestrielle;

  const DemandeInscription({
    required this.nom,
    required this.prenom,
    required this.telephone,
    required this.email,
    required this.dateNaissance,
    required this.situationFamiliale,
    required this.ville,
    required this.quartier,
    required this.metier,
    required this.categorieProfessionnelle,
    required this.montantRevenu,
    required this.dateDebutActivite,
    required this.villeActivite,
    required this.quartierActivite,
    required this.communeSousPrefectureActivite,
    required this.typeDocument,
    required this.numeroDocument,
    required this.documentEtablieLe,
    required this.documentExpireLe,
    required this.recto,
    required this.verso,
    required this.selfie,
    required this.montantCotisationRegimeBase,
    required this.montantCotisationRegimeComplementaire,
    required this.montantCotisationMensuelle,
    required this.montantCotisationTrimestrielle,
    this.sexe,
    this.lieuNaissance,
    this.numeroCnps,
    this.numeroCmu,
    this.profession,
    this.village,
    this.adressePostale,
  });

  /// Champs texte du multipart. Les fichiers sont ajoutés séparément.
  Map<String, dynamic> versChamps() => {
    'nom': nom,
    'prenom': prenom,
    'telephone': telephone,
    'sexe': sexe,
    'date_naissance': Formatters.dateApi(dateNaissance),
    'lieu_naissance': lieuNaissance,
    'situation_familiale': situationFamiliale,
    'email': email,
    'numero_cnps': numeroCnps,
    'numero_cmu': numeroCmu,
    'ville': ville,
    'quartier': quartier,
    'village': village,
    'adresse_postale': adressePostale,
    'profession': profession,
    'metier': metier,
    'categorie_professionnelle': categorieProfessionnelle,
    'montant_revenu': montantRevenu.round().toString(),
    'date_debut_activite': Formatters.dateApi(dateDebutActivite),
    'ville_activite': villeActivite,
    'quartier_activite': quartierActivite,
    'commune_sous_prefecture_activite': communeSousPrefectureActivite,
    'type_document': typeDocument,
    'numero_document': numeroDocument,
    'document_etablie_le': Formatters.dateApi(documentEtablieLe),
    'document_expire_le': Formatters.dateApi(documentExpireLe),
    'montant_cotisation_regime_base': montantCotisationRegimeBase
        .round()
        .toString(),
    'montant_cotisation_regime_complementaire':
        montantCotisationRegimeComplementaire.round().toString(),
    'montant_cotisation_mensuelle': montantCotisationMensuelle
        .round()
        .toString(),
    'montant_cotisation_trimestrielle': montantCotisationTrimestrielle
        .round()
        .toString(),
  };
}

/// Payload de `PATCH /espace-utilisateur/profil` — tous les champs sont
/// facultatifs, seuls les non-nuls sont envoyés.
class MiseAJourProfil {
  final String? email;
  final String? ville;
  final String? quartier;
  final String? situationFamiliale;
  final int? nombreEnfants;

  const MiseAJourProfil({
    this.email,
    this.ville,
    this.quartier,
    this.situationFamiliale,
    this.nombreEnfants,
  });

  bool get estVide =>
      email == null &&
      ville == null &&
      quartier == null &&
      situationFamiliale == null &&
      nombreEnfants == null;

  Map<String, dynamic> versChamps() => {
    'email': email,
    'ville': ville,
    'quartier': quartier,
    'situation_familiale': situationFamiliale,
    'nombre_enfants': nombreEnfants?.toString(),
  };
}
