import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_parser/http_parser.dart';

/// Vérifie l'encodage multipart réellement produit pour l'inscription.
///
/// Sans `contentType` explicite, Dio étiquette les fichiers en
/// `application/octet-stream`, là où Postman envoie `image/jpeg`. Ce test fige
/// le comportement attendu et affiche le corps brut pour inspection.
void main() {
  test('les fichiers sont étiquetés image/jpeg, pas octet-stream', () async {
    // Entête JPEG minimal — le contenu importe peu ici.
    final octets = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]);

    final formData = FormData.fromMap({'nom': 'JOHN', 'prenom': 'DAN'});
    formData.files.add(
      MapEntry(
        'url_recto',
        MultipartFile.fromBytes(
          octets,
          filename: 'recto.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      ),
    );

    final corps = utf8.decode(
      await formData.readAsBytes(),
      allowMalformed: true,
    );

    // Affiché par `flutter test -r expanded` pour comparaison avec Postman.
    // ignore: avoid_print
    print('\n--- corps multipart ---\n$corps\n--- fin ---\n');

    expect(corps, contains('content-type: image/jpeg'));
    expect(corps, isNot(contains('octet-stream')));
    expect(corps, contains('filename="recto.jpg"'));
    // Les champs texte ne portent pas de content-type, comme dans Postman.
    expect(corps, contains('name="nom"'));
  });
}
