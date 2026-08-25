import 'package:concept_nhv/services/backup/pairing_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parsePairingUri', () {
    test('reads the documented example exactly', () {
      // This literal is the contract with the desktop server, whose builder
      // test asserts against the same string. The two live in separate packages
      // with no shared dependency, so this pair of literals is the only thing
      // that makes a format change fail loudly on both sides rather than
      // silently on one.
      const raw = 'comicdex://pair?v=1&pin=965594'
          '&a=192.168.50.72%3A6890&a=192.168.137.1%3A6890';

      final payload = parsePairingUri(raw);

      expect(payload.pin, '965594');
      expect(payload.addresses, <String>[
        '192.168.50.72:6890',
        '192.168.137.1:6890',
      ]);
    });

    test('keeps address order — the phone tries them in turn', () {
      final payload = parsePairingUri(
        'comicdex://pair?v=1&pin=1&a=10.0.0.1%3A1&a=10.0.0.2%3A2&a=10.0.0.3%3A3',
      );

      expect(payload.addresses, <String>[
        '10.0.0.1:1',
        '10.0.0.2:2',
        '10.0.0.3:3',
      ]);
    });

    group('rejects', () {
      void expectFailure(String raw, PairingScanFailure failure) {
        expect(
          () => parsePairingUri(raw),
          throwsA(
            isA<PairingScanException>().having(
              (e) => e.failure,
              'failure',
              failure,
            ),
          ),
        );
      }

      test('someone else\'s QR code', () {
        // The overwhelmingly likely mis-scan: a URL on a poster, a WiFi code.
        expectFailure(
          'https://example.com/',
          PairingScanFailure.notAPairingCode,
        );
        expectFailure('WIFI:S:home;T:WPA;P:secret;;', PairingScanFailure.notAPairingCode);
        expectFailure('not a uri at all', PairingScanFailure.notAPairingCode);
      });

      test('our scheme but the wrong action', () {
        expectFailure(
          'comicdex://open?v=1&pin=1&a=h%3A1',
          PairingScanFailure.notAPairingCode,
        );
      });

      test('a version newer than this build, so the user can be told to update', () {
        expectFailure(
          'comicdex://pair?v=2&pin=1&a=h%3A1',
          PairingScanFailure.unsupportedVersion,
        );
      });

      test('a missing version — every real code has carried one', () {
        expectFailure(
          'comicdex://pair?pin=1&a=h%3A1',
          PairingScanFailure.notAPairingCode,
        );
      });

      test('a missing or empty pin', () {
        expectFailure(
          'comicdex://pair?v=1&a=h%3A1',
          PairingScanFailure.notAPairingCode,
        );
        expectFailure(
          'comicdex://pair?v=1&pin=&a=h%3A1',
          PairingScanFailure.notAPairingCode,
        );
      });

      test('a genuine code that names no address', () {
        // Separate from "not ours" on purpose: the code is real, the desktop
        // just had no usable interface. Telling the user to scan something else
        // would send them hunting for a problem that is not on their phone.
        expectFailure(
          'comicdex://pair?v=1&pin=965594',
          PairingScanFailure.noAddresses,
        );
        expectFailure(
          'comicdex://pair?v=1&pin=965594&a=&a=%20',
          PairingScanFailure.noAddresses,
        );
      });
    });

    test('an older version is still readable', () {
      // Forward compatibility only runs one way: this build must keep reading
      // anything it once produced.
      final payload = parsePairingUri('comicdex://pair?v=1&pin=42&a=h%3A1');

      expect(payload.pin, '42');
    });

    test('tolerates surrounding whitespace from a sloppy decode', () {
      final payload = parsePairingUri('  comicdex://pair?v=1&pin=7&a=h%3A1  ');

      expect(payload.pin, '7');
    });
  });

  group('parseFirstPairingCode', () {
    // Shared by the camera and the photo library, so both must behave the same
    // way when a frame or a screenshot holds more than one code.
    test('picks ours out of a batch holding several codes', () {
      final payload = parseFirstPairingCode(<String>[
        'https://example.com/',
        'WIFI:S:home;T:WPA;P:secret;;',
        'comicdex://pair?v=1&pin=965594&a=192.168.50.72%3A6890',
      ]);

      expect(payload.pin, '965594');
    });

    test('an empty batch is "no code found", not "not ours"', () {
      expect(
        () => parseFirstPairingCode(const <String>[]),
        throwsA(
          isA<PairingScanException>().having(
            (e) => e.failure,
            'failure',
            PairingScanFailure.noCodeFound,
          ),
        ),
      );
    });

    test('keeps the specific reason rather than letting it decay', () {
      // "Update the app" and "scan the right thing" send the user to different
      // places, so the reason has to survive the loop over codes.
      expect(
        () => parseFirstPairingCode(const <String>[
          'comicdex://pair?v=99&pin=1&a=h%3A1',
          'https://example.com/',
        ]),
        throwsA(
          isA<PairingScanException>().having(
            (e) => e.failure,
            'failure',
            PairingScanFailure.unsupportedVersion,
          ),
        ),
      );
    });
  });
}
