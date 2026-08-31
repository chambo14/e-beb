import '../../core/utils/json_utils.dart';

/// Solde du compte utilisateur (`/espace-utilisateur/solde`).
class Solde {
  final double disponible;
  final double totalRecu;
  final double totalPreleve;
  final double epargne;
  final String devise;
  final DateTime? misAJourLe;

  const Solde({
    required this.disponible,
    this.totalRecu = 0,
    this.totalPreleve = 0,
    this.epargne = 0,
    this.devise = 'FCFA',
    this.misAJourLe,
  });

  static const vide = Solde(disponible: 0);

  factory Solde.depuisJson(Map<String, dynamic> json) {
    final racine = Json.objet(json, ['solde', 'compte']) ?? json;
    return Solde(
      // Le back-end (`RecapitulatifService::soldesGlobaux`) renvoie
      // `solde_principal` — les autres clés sont conservées en repli pour
      // tolérer une évolution future du contrat.
      disponible: Json.decimalOu(racine, [
        'solde_principal',
        'solde_disponible',
        'disponible',
        'solde',
        'montant',
      ]),
      totalRecu: Json.decimalOu(racine, [
        'total_recu',
        'total_encaisse',
        'montant_recu',
      ]),
      totalPreleve: Json.decimalOu(racine, [
        'total_preleve',
        'total_deduit',
        'montant_preleve',
      ]),
      epargne: Json.decimalOu(racine, ['solde_epargne', 'epargne']),
      devise: Json.texteOu(racine, ['devise', 'currency'], 'FCFA'),
      misAJourLe: Json.date(racine, ['updated_at', 'mis_a_jour_le']),
    );
  }
}
