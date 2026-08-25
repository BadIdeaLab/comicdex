/// The pairing QR's contents.
///
/// ## Wire format
///
/// ```
/// comicdex://pair?v=1&pin=965594&a=192.168.50.72:6890&a=192.168.137.1:6890
/// ```
///
/// This string is a contract with the phone app, which only ever *parses* it
/// (see `lib/services/backup/pairing_payload.dart` there). The two halves live
/// in separate packages with no shared dependency, so the guard against drift
/// is that both sides' tests assert against the **same literal example** —
/// change the format on one side and the other side's test fails.
///
/// ## Why a URI rather than JSON
///
/// The `comicdex://pair` prefix makes "is this even our QR?" a single string
/// comparison, which is what lets the phone tell "you scanned something else"
/// apart from "you scanned a broken pairing code". Repeated `a` parameters
/// express several addresses without inventing a separator that could collide
/// with an address.
///
/// ## Why the version is not optional
///
/// The desktop server and the phone app ship as separate binaries, so a phone
/// older than the desktop is the normal state, not an edge case. Without [v] a
/// phone reading a future format either fails with "invalid QR" — misleading,
/// because it *is* ours — or, worse, parses part of it and pairs against a
/// mangled address. This project already has one failure mode whose symptoms
/// are indistinguishable from a different cause (a mistyped address looks
/// exactly like a blocked firewall); a second one is not worth the bytes saved.
library;

/// Format version. Bump only for changes a previous phone could misread.
const int kPairingPayloadVersion = 1;

const String kPairingUriScheme = 'comicdex';
const String kPairingUriHost = 'pair';

/// Builds the string to encode into the pairing QR.
///
/// [addresses] are `host:port` strings, in the order the phone should try
/// them. All of them are included on purpose: the desktop cannot reliably tell
/// which of its interfaces a phone can reach — a VPN endpoint and a Hyper-V
/// switch look much like a real LAN card, while the mobile-hotspot adapter is
/// "virtual" yet is exactly where a phone connects — so the phone tries each in
/// turn instead of anyone guessing.
String buildPairingUri({
  required String pin,
  required List<String> addresses,
}) {
  final buffer = StringBuffer('$kPairingUriScheme://$kPairingUriHost?v=$kPairingPayloadVersion');
  buffer.write('&pin=${Uri.encodeQueryComponent(pin)}');
  for (final address in addresses) {
    buffer.write('&a=${Uri.encodeQueryComponent(address)}');
  }
  return buffer.toString();
}
