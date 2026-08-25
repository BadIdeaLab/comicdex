import 'package:desktop_backup_server/services/pairing_payload.dart';
import 'package:flutter_test/flutter_test.dart';

/// What [ServerModel.pairingUri] must produce, expressed against the builder.
///
/// The getter itself needs a live server socket and a real backup folder to
/// construct, so these cover the shape it assembles rather than the model —
/// specifically that the port is joined onto every address, which is the part
/// with somewhere to go wrong.
void main() {
  group('pairing URI assembly', () {
    test('joins the port onto every address', () {
      const port = 6890;
      const hosts = <String>['192.168.50.72', '192.168.137.1', '172.24.233.60'];

      final uri = Uri.parse(
        buildPairingUri(
          pin: '965594',
          addresses: <String>[for (final host in hosts) '$host:$port'],
        ),
      );

      expect(uri.queryParametersAll['a'], <String>[
        '192.168.50.72:6890',
        '192.168.137.1:6890',
        '172.24.233.60:6890',
      ]);
    });

    test('offers every interface, including ones that look unreachable', () {
      // Deliberate: this machine cannot tell which interface a given phone can
      // reach. A VPN endpoint and a Hyper-V switch look much like a real LAN
      // card, while the mobile-hotspot adapter is "virtual" yet is exactly
      // where a phone connects. Filtering here would drop a working address.
      final uri = Uri.parse(
        buildPairingUri(
          pin: '1',
          addresses: <String>[
            '192.168.50.72:6890', // physical
            '192.168.137.1:6890', // mobile hotspot, virtual but reachable
            '192.168.176.1:6890', // Hyper-V, unreachable
            '172.24.233.60:6890', // VPN endpoint, unreachable
          ],
        ),
      );

      expect(uri.queryParametersAll['a'], hasLength(4));
    });
  });
}
