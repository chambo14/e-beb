import '../../core/utils/json_utils.dart';

/// Notification de l'espace utilisateur
/// (`/espace-utilisateur/notifications`).
class NotificationApp {
  final String id;
  final String titre;
  final String message;
  final String? type;
  final bool estLue;
  final DateTime date;

  const NotificationApp({
    required this.id,
    required this.titre,
    required this.message,
    required this.date,
    this.type,
    this.estLue = false,
  });

  factory NotificationApp.depuisJson(Map<String, dynamic> json) {
    // Laravel encapsule souvent le contenu dans `data`.
    final contenu = Json.objet(json, ['data', 'contenu']) ?? json;

    return NotificationApp(
      id: Json.texteOu(json, ['id', 'uuid']),
      titre: Json.texteOu(contenu, [
        'titre',
        'title',
        'sujet',
      ], 'Notification'),
      message: Json.texteOu(contenu, ['message', 'corps', 'body', 'contenu']),
      type: Json.texte(contenu, ['type', 'categorie']),
      // Clés réelles renvoyées par `NotificationResource` : `est_lu` (jamais
      // `est_lue`) et `lu_le` (jamais `lue_le`) — sans cette correspondance
      // exacte, toute notification restait indéfiniment marquée non lue.
      estLue:
          Json.booleen(json, ['est_lu', 'est_lue', 'lue', 'is_read']) ||
          Json.premier(json, ['lu_le', 'read_at', 'lue_le']) != null,
      date:
          Json.date(json, ['created_at', 'date', 'envoye_le']) ??
          DateTime.now(),
    );
  }

  NotificationApp marquerLue() => NotificationApp(
    id: id,
    titre: titre,
    message: message,
    date: date,
    type: type,
    estLue: true,
  );
}
