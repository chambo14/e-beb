import 'dart:convert';

/// Génère la donnée encodée dans le QR code d'une carte réseau.
///
/// Format clair : JSON avec les infos essentielles de la transaction.
/// Encodé en base64 pour simuler un payload opaque (comme le ferait
/// une vraie passerelle de paiement).
///
/// Exemple de payload décodé :
/// {
///   "app": "EBEB_SALARY",
///   "v": "1",
///   "network": "WAVE",
///   "phone": "0700000001",
///   "cnps": "123456789",
///   "ref": "EBEB-WAVE-123456789-20260509",
///   "ts": 1746748800
/// }
String buildQrPayload({
  required String network,
  required String phone,
  required String cnpsNumero,
}) {
  final date = DateTime.now();
  final dateTag =
      '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';

  final payload = {
    'app': 'EBEB_SALARY',
    'v': '1',
    'network': network.toUpperCase(),
    'phone': phone.replaceAll(' ', ''),
    'cnps': cnpsNumero,
    'ref': 'EBEB-${network.toUpperCase()}-$cnpsNumero-$dateTag',
    'ts': date.millisecondsSinceEpoch ~/ 1000,
  };

  return base64Url.encode(utf8.encode(jsonEncode(payload)));
}
