import 'package:concept_nhv/services/backup/pairing_code_reader.dart';
import 'package:concept_nhv/services/backup/pairing_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PairingCodeReader.readFromGallery', () {
    const validCode = 'comicdex://pair?v=1&pin=965594&a=192.168.50.72%3A6890';

    PairingCodeReader reader({
      String? pickedPath = '/tmp/shot.png',
      List<String> codes = const <String>[validCode],
    }) {
      return PairingCodeReader(
        pickImagePath: () async => pickedPath,
        readCodesFromImage: (_) async => codes,
      );
    }

    test('reads the pairing code out of a picked image', () async {
      final payload = await reader().readFromGallery();

      expect(payload?.pin, '965594');
      expect(payload?.addresses, <String>['192.168.50.72:6890']);
    });

    test('returns null when the picker was cancelled', () async {
      // Backing out is not a failure and must not raise an error at the user.
      final payload = await reader(pickedPath: null).readFromGallery();

      expect(payload, isNull);
    });

    test('reports an image with no code at all', () async {
      await expectLater(
        reader(codes: const <String>[]).readFromGallery(),
        throwsA(
          isA<PairingScanException>().having(
            (e) => e.failure,
            'failure',
            PairingScanFailure.noCodeFound,
          ),
        ),
      );
    });

    test('picks ours out of an image holding several codes', () async {
      // A screenshot of a whole desktop, or a photo of a noticeboard, can carry
      // more than one code. Taking the first *pairing* code rather than the
      // first code stops an unrelated QR from masking ours.
      final payload = await reader(
        codes: const <String>[
          'https://example.com/',
          'WIFI:S:home;T:WPA;P:secret;;',
          validCode,
        ],
      ).readFromGallery();

      expect(payload?.pin, '965594');
    });

    test('reports the first real reason when nothing in the image is ours', () async {
      await expectLater(
        reader(
          codes: const <String>['https://example.com/', 'also-not-ours'],
        ).readFromGallery(),
        throwsA(
          isA<PairingScanException>().having(
            (e) => e.failure,
            'failure',
            PairingScanFailure.notAPairingCode,
          ),
        ),
      );
    });

    test('a newer-version code keeps its own reason rather than becoming generic', () async {
      // "Update the app" and "scan the right thing" send the user to different
      // places, so the specific reason has to survive the loop over codes.
      await expectLater(
        reader(
          codes: const <String>['comicdex://pair?v=99&pin=1&a=h%3A1'],
        ).readFromGallery(),
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
