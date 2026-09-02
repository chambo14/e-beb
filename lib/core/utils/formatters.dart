import 'package:intl/intl.dart';

import '../config/app_config.dart';

/// Formatage partagé : montants en FCFA, dates, numéros de téléphone.
class Formatters {
  const Formatters._();

  static final NumberFormat _montant = NumberFormat.decimalPattern('fr');
  static final DateFormat _jourMoisAn = DateFormat('dd/MM/yyyy', 'fr');
  static final DateFormat _jourMoisAnHeure = DateFormat(
    'dd/MM/yyyy à HH:mm',
    'fr',
  );
  static final DateFormat _apiDate = DateFormat('yyyy-MM-dd');

  /// `125000` → `125 000 FCFA`.
  static String montant(num valeur, {bool avecDevise = true}) {
    final texte = _montant.format(valeur.round()).replaceAll(',', ' ');
    return avecDevise ? '$texte FCFA' : texte;
  }

  static String dateCourte(DateTime date) => _jourMoisAn.format(date);

  static String dateHeure(DateTime date) => _jourMoisAnHeure.format(date);

  /// Format attendu par l'API pour les champs date (`2000-04-12`).
  static String dateApi(DateTime date) => _apiDate.format(date);

  /// Normalise un numéro saisi vers le format E.164 attendu par l'API.
  ///
  /// `07 09 41 55 35` → `+2250709415535`, un numéro déjà préfixé est conservé.
  static String telephoneApi(String saisie) {
    var chiffres = saisie.replaceAll(RegExp(r'[^\d+]'), '');
    if (chiffres.startsWith('+')) return chiffres;
    if (chiffres.startsWith('00')) return '+${chiffres.substring(2)}';
    if (chiffres.startsWith('225')) return '+$chiffres';
    return '${AppConfig.defaultCountryCode}$chiffres';
  }

  /// `+2250709415535` → `07 09 41 55 35` (affichage).
  static String telephoneAffichage(String telephone) {
    var chiffres = telephone.replaceAll(RegExp(r'[^\d]'), '');
    if (chiffres.startsWith('225')) chiffres = chiffres.substring(3);
    final buffer = StringBuffer();
    for (var i = 0; i < chiffres.length; i++) {
      if (i > 0 && i.isEven) buffer.write(' ');
      buffer.write(chiffres[i]);
    }
    return buffer.toString();
  }
}
