import 'package:desktop_backup_server/services/pairing_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildPairingUri', () {
    test('matches the documented example exactly', () {
      // This literal is the contract with the phone app, whose parser test
      // asserts against the same string. The two live in separate packages with
      // no shared dependency, so this pair of literals is the only thing that
      // makes a format change fail loudly on both sides instead of silently on
      // one.
      expect(
        buildPairingUri(
          pin: '965594',
          addresses: <String>['192.168.50.72:6890', '192.168.137.1:6890'],
        ),
        'comicdex://pair?v=1&pin=965594'
            '&a=192.168.50.72%3A6890&a=192.168.137.1%3A6890',
      );
    });

    test('keeps the order it was given', () {
      // The phone tries addresses in order, so this is the desktop's only say
      // in which one is attempted first.
      final uri = Uri.parse(
        buildPairingUri(
          pin: '000000',
          addresses: <String>['10.0.0.1:1', '10.0.0.2:2', '10.0.0.3:3'],
        ),
      );

      expect(uri.queryParametersAll['a'], <String>[
        '10.0.0.1:1',
        '10.0.0.2:2',
        '10.0.0.3:3',
      ]);
    });

    test('survives a round trip through Uri.parse', () {
      final uri = Uri.parse(
        buildPairingUri(pin: '123456', addresses: <String>['host:9']),
      );

      expect(uri.scheme, kPairingUriScheme);
      expect(uri.host, kPairingUriHost);
      expect(uri.queryParameters['v'], '1');
      expect(uri.queryParameters['pin'], '123456');
    });

    test('a single address still produces a list, not a bare value', () {
      final uri = Uri.parse(
        buildPairingUri(pin: '1', addresses: <String>['192.168.0.5:6890']),
      );

      expect(uri.queryParametersAll['a'], <String>['192.168.0.5:6890']);
    });

    test('no addresses is representable rather than malformed', () {
      // The desktop can be running with every interface filtered out. The QR is
      // then useless, but it must still parse — the phone should say "no usable
      // address" rather than "this is not a Comicdex code".
      final uri = Uri.parse(buildPairingUri(pin: '1', addresses: <String>[]));

      expect(uri.queryParametersAll['a'], isNull);
      expect(uri.queryParameters['pin'], '1');
    });
  });
}
