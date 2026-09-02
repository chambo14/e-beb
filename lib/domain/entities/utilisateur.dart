import '../../core/utils/json_utils.dart';

/// Utilisateur de l'espace personnel (route `/espace-utilisateur/details`).
///
/// Tous les champs hors identité sont optionnels : le back-end ne renvoie pas
/// le même sous-ensemble selon l'avancement du dossier KYC.
class Utilisateur {
  final String id;
  final String nom;
  final String prenom;
  final String telephone;
  final String? email;

  // Identité
  final String? sexe;
  final DateTime? dateNaissance;
  final String? lieuNaissance;
  final String? situationFamiliale;
  final int? nombreEnfants;

  // Sécurité sociale
  final String? numeroCnps;
  final String? numeroCmu;

  /// Identifiant public du dossier, renvoyé par l'API sous `reference`
  /// (ex. `EBEB-PCKD5QPWJM`).
  final String? matricule;

  /// Niveau de carte attribué à l'inscription (`BASIC`, …).
  final String? typeCarte;

  // Adresse
  final String? ville;
  final String? quartier;
  final String? village;
  final String? adressePostale;
  final String? pays;

  // Activité professionnelle
  final String? profession;
  final String? metier;
  final String? categorieProfessionnelle;
  final double? montantRevenu;
  final DateTime? dateDebutActivite;
  final String? villeActivite;
  final String? quartierActivite;
  final String? communeSousPrefectureActivite;

  // Pièce d'identité
  final String? typeDocument;
  final String? numeroDocument;
  final DateTime? documentEtablieLe;
  final DateTime? documentExpireLe;
  final String? urlRecto;
  final String? urlVerso;
  final String? urlSelfie;

  // Cotisations souscrites
  final double? montantCotisationRegimeBase;
  final double? montantCotisationRegimeComplementaire;
  final double? montantCotisationMensuelle;
  final double? montantCotisationTrimestrielle;

  // État du compte
  final String? statut;
  final bool codePinDefini;

  const Utilisateur({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.telephone,
    this.email,
    this.sexe,
    this.dateNaissance,
    this.lieuNaissance,
    this.situationFamiliale,
    this.nombreEnfants,
    this.numeroCnps,
    this.numeroCmu,
    this.matricule,
    this.typeCarte,
    this.ville,
    this.quartier,
    this.village,
    this.adressePostale,
    this.pays,
    this.profession,
    this.metier,
    this.categorieProfessionnelle,
    this.montantRevenu,
    this.dateDebutActivite,
    this.villeActivite,
    this.quartierActivite,
    this.communeSousPrefectureActivite,
    this.typeDocument,
    this.numeroDocument,
    this.documentEtablieLe,
    this.documentExpireLe,
    this.urlRecto,
    this.urlVerso,
    this.urlSelfie,
    this.montantCotisationRegimeBase,
    this.montantCotisationRegimeComplementaire,
    this.montantCotisationMensuelle,
    this.montantCotisationTrimestrielle,
    this.statut,
    this.codePinDefini = false,
  });

  String get nomComplet => '$prenom $nom'.trim();

  /// `true` une fois le dossier KYC validé par un administrateur.
  bool get estActif => statut?.toUpperCase() == 'ACTIF';

  /// `true` tant que les documents sont soumis mais pas encore vérifiés —
  /// distinct d'un compte suspendu ou rejeté, qui a son propre traitement.
  bool get enAttenteVerification => statut?.toUpperCase() == 'EN_ATTENTE';

  String get initiales {
    final p = prenom.isNotEmpty ? prenom[0] : '';
    final n = nom.isNotEmpty ? nom[0] : '';
    final resultat = '$p$n'.toUpperCase();
    return resultat.isEmpty ? '?' : resultat;
  }

  /// L'API imbrique parfois l'utilisateur sous `utilisateur` ou `user`.
  factory Utilisateur.depuisJson(Map<String, dynamic> json) {
    final racine =
        Json.objet(json, ['utilisateur', 'user', 'profil']) ?? json;

    // `UserResource` imbrique les montants déclarés sous `declarationRevenu`
    // (jamais à la racine) — sans ce sous-objet, ces montants restaient
    // toujours nuls malgré des données bien présentes en base.
    final declaration =
        Json.objet(racine, ['declarationRevenu', 'declaration_revenu']) ??
            const {};

    // Idem pour les documents KYC : `documentKYCs` est une *liste* (un
    // utilisateur peut soumettre plusieurs pièces), avec des clés propres
    // (`photo_selfie`, `document_recto`, `document_verso`) — jamais des
    // champs `url_*` à la racine. On retient le document le plus récent.
    final documentsKyc = Json.objets(racine, ['documentKYCs', 'document_kyc']);
    final documentKyc =
        documentsKyc.isEmpty ? const <String, dynamic>{} : documentsKyc.first;

    return Utilisateur(
      id: Json.texteOu(racine, ['id', 'uuid', 'utilisateur_id']),
      nom: Json.texteOu(racine, ['nom', 'last_name']),
      prenom: Json.texteOu(racine, ['prenom', 'prenoms', 'first_name']),
      telephone: Json.texteOu(racine, ['telephone', 'phone', 'numero']),
      email: Json.texte(racine, ['email']),
      sexe: Json.texte(racine, ['sexe', 'genre']),
      dateNaissance: Json.date(racine, ['date_naissance']),
      lieuNaissance: Json.texte(racine, ['lieu_naissance']),
      situationFamiliale: Json.texte(racine, ['situation_familiale']),
      nombreEnfants: Json.entier(racine, ['nombre_enfants']),
      numeroCnps: Json.texte(racine, ['numero_cnps', 'cnps']),
      numeroCmu: Json.texte(racine, ['numero_cmu', 'cmu']),
      matricule: Json.texte(racine, [
        'reference',
        'matricule',
        'numero_matricule',
      ]),
      typeCarte: Json.texte(racine, ['type_carte', 'type_card']),
      ville: Json.texte(racine, ['ville']),
      quartier: Json.texte(racine, ['quartier']),
      village: Json.texte(racine, ['village']),
      adressePostale: Json.texte(racine, ['adresse_postale']),
      pays: Json.texte(racine, ['pays']),
      profession: Json.texte(racine, ['profession']),
      metier: Json.texte(racine, ['metier']),
      categorieProfessionnelle: Json.texte(racine, [
        'categorie_professionnelle',
      ]),
      montantRevenu: Json.decimal(declaration, ['montant_revenu']) ??
          Json.decimal(racine, ['montant_revenu', 'revenu']),
      dateDebutActivite: Json.date(racine, ['date_debut_activite']),
      villeActivite: Json.texte(racine, ['ville_activite']),
      quartierActivite: Json.texte(racine, ['quartier_activite']),
      communeSousPrefectureActivite: Json.texte(racine, [
        'commune_sous_prefecture_activite',
      ]),
      typeDocument: Json.texte(documentKyc, ['type_document']) ??
          Json.texte(racine, ['type_document']),
      numeroDocument: Json.texte(documentKyc, ['numero_document']) ??
          Json.texte(racine, ['numero_document']),
      documentEtablieLe: Json.date(documentKyc, ['document_etablie_le']) ??
          Json.date(racine, ['document_etablie_le']),
      documentExpireLe: Json.date(documentKyc, ['document_expire_le']) ??
          Json.date(racine, ['document_expire_le']),
      urlRecto: Json.texte(documentKyc, ['document_recto', 'url_recto']) ??
          Json.texte(racine, ['url_recto']),
      urlVerso: Json.texte(documentKyc, ['document_verso', 'url_verso']) ??
          Json.texte(racine, ['url_verso']),
      urlSelfie: Json.texte(documentKyc, ['photo_selfie', 'url_selfie']) ??
          Json.texte(racine, ['url_selfie']),
      montantCotisationRegimeBase:
          Json.decimal(declaration, ['montant_cotisation_regime_base']) ??
              Json.decimal(racine, ['montant_cotisation_regime_base']),
      montantCotisationRegimeComplementaire: Json.decimal(
            declaration,
            ['montant_cotisation_regime_complementaire'],
          ) ??
          Json.decimal(racine, ['montant_cotisation_regime_complementaire']),
      montantCotisationMensuelle:
          Json.decimal(declaration, ['montant_cotisation_mensuelle']) ??
              Json.decimal(racine, ['montant_cotisation_mensuelle']),
      montantCotisationTrimestrielle: Json.decimal(
            declaration,
            ['montant_cotisation_trimestrielle'],
          ) ??
          Json.decimal(racine, ['montant_cotisation_trimestrielle']),
      statut: Json.texte(racine, ['statut', 'status', 'etat']),
      codePinDefini: Json.booleen(racine, [
        'code_pin_defini',
        'a_code_pin',
        'has_pin',
      ]),
    );
  }
}
