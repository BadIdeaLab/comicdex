import 'package:concept_nhv/services/backup/backup_diff.dart';
import 'package:concept_nhv/services/backup/backup_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeUploadList', () {
    LocalBackupFile file(String path, int size) {
      return LocalBackupFile(
        relativePath: path,
        absolutePath: '/downloads/$path',
        sizeBytes: size,
      );
    }

    test('uploads everything when the server has nothing', () {
      final pending = computeUploadList(
        localFiles: <LocalBackupFile>[
          file('177013/cover.webp', 100),
          file('177013/pages/1.webp', 200),
        ],
        remoteInventory: const <String, int>{},
      );

      expect(pending.map((f) => f.relativePath), <String>[
        '177013/cover.webp',
        '177013/pages/1.webp',
      ]);
    });

    test('skips files the server already holds at the same size', () {
      final pending = computeUploadList(
        localFiles: <LocalBackupFile>[
          file('177013/cover.webp', 100),
          file('177013/pages/1.webp', 200),
        ],
        remoteInventory: const <String, int>{'177013/cover.webp': 100},
      );

      expect(pending.map((f) => f.relativePath), <String>[
        '177013/pages/1.webp',
      ]);
    });

    test('re-uploads when the size differs', () {
      // Covers both a re-downloaded page and a previously stored truncated file.
      final pending = computeUploadList(
        localFiles: <LocalBackupFile>[file('177013/cover.webp', 100)],
        remoteInventory: const <String, int>{'177013/cover.webp': 40},
      );

      expect(pending, hasLength(1));
    });

    test('nothing to do when everything matches — the resumed/second run', () {
      final pending = computeUploadList(
        localFiles: <LocalBackupFile>[
          file('177013/cover.webp', 100),
          file('177013/pages/1.webp', 200),
        ],
        remoteInventory: const <String, int>{
          '177013/cover.webp': 100,
          '177013/pages/1.webp': 200,
        },
      );

      expect(pending, isEmpty);
    });

    test('extra files on the server do not affect what is uploaded', () {
      // The mirror deliberately keeps comics deleted from the phone; that must
      // not make the diff think there is work to do.
      final pending = computeUploadList(
        localFiles: <LocalBackupFile>[file('177013/cover.webp', 100)],
        remoteInventory: const <String, int>{
          '177013/cover.webp': 100,
          '999999/cover.webp': 50,
        },
      );

      expect(pending, isEmpty);
    });
  });
}
