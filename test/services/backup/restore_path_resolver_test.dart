import 'package:concept_nhv/services/backup/restore_path_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

/// The real absolute shape, taken from an audited backup: nested container
/// UUIDs and a space in "Application Support".
const String _legacyAbsolute =
    '/var/mobile/Containers/Data/Application/759C3FF1-EC53-4BA1-AED2-7DEDB9FE8AFE'
    '/Documents/Data/Application/D2A8841B-46DE-46B8-BAF0-0D898FBE2E9E'
    '/Library/Application Support/downloads/287290/cover.webp';

void main() {
  group('normaliseRestorePath', () {
    test('leaves an already-relative path alone', () {
      expect(
        normaliseRestorePath('177013/pages/1.webp'),
        '177013/pages/1.webp',
      );
    });

    test(
      'reduces a legacy absolute container path to its mirror-relative form — '
      'without this, 41% of a real library restores silently as nothing',
      () {
        expect(normaliseRestorePath(_legacyAbsolute), '287290/cover.webp');
      },
    );

    test('uses the LAST downloads segment, not the first', () {
      // A comic id could itself be a folder called "downloads"; anchoring on the
      // first match would then cut the path in the wrong place.
      expect(
        normaliseRestorePath('/a/downloads/b/downloads/177013/cover.webp'),
        '177013/cover.webp',
      );
    });

    test('normalises Windows separators', () {
      expect(normaliseRestorePath(r'177013\pages\1.webp'), '177013/pages/1.webp');
    });

    test('rejects empty, null and unmappable absolute paths', () {
      expect(normaliseRestorePath(null), isNull);
      expect(normaliseRestorePath(''), isNull);
      expect(normaliseRestorePath('   '), isNull);
      // Absolute but with no downloads segment: cannot be placed in the mirror.
      expect(normaliseRestorePath('/var/mobile/elsewhere/cover.webp'), isNull);
    });
  });

  group('computeRestoreDownloadList', () {
    test('pulls relative and legacy absolute references alike', () {
      final list = computeRestoreDownloadList(
        databasePaths: <String?>[_legacyAbsolute, '177013/pages/1.webp'],
        remoteInventory: const <String, int>{
          '287290/cover.webp': 100,
          '177013/pages/1.webp': 200,
        },
      );

      expect(list, <String>['177013/pages/1.webp', '287290/cover.webp']);
    });

    test(
      'ignores mirror files the database does not reference, so comics deleted '
      'on the phone are not resurrected as invisible orphans',
      () {
        final list = computeRestoreDownloadList(
          databasePaths: <String?>['177013/cover.webp'],
          remoteInventory: const <String, int>{
            '177013/cover.webp': 100,
            '999999/cover.webp': 50,
          },
        );

        expect(list, <String>['177013/cover.webp']);
      },
    );

    test('skips references the mirror does not actually hold', () {
      final list = computeRestoreDownloadList(
        databasePaths: <String?>['177013/cover.webp', 'missing/cover.webp'],
        remoteInventory: const <String, int>{'177013/cover.webp': 100},
      );

      expect(list, <String>['177013/cover.webp']);
    });

    test('resumes: skips files already present locally at the right size', () {
      final list = computeRestoreDownloadList(
        databasePaths: <String?>['a/1.webp', 'a/2.webp'],
        remoteInventory: const <String, int>{'a/1.webp': 10, 'a/2.webp': 20},
        localFiles: const <String, int>{'a/1.webp': 10},
      );

      expect(list, <String>['a/2.webp']);
    });

    test('re-pulls a local file whose size does not match the mirror', () {
      final list = computeRestoreDownloadList(
        databasePaths: <String?>['a/1.webp'],
        remoteInventory: const <String, int>{'a/1.webp': 10},
        localFiles: const <String, int>{'a/1.webp': 4},
      );

      expect(list, <String>['a/1.webp']);
    });

    test('de-duplicates when two rows normalise to the same file', () {
      // The cover is recorded both on DownloadedComic and, historically, as a
      // page row; both must not queue the same download twice.
      final list = computeRestoreDownloadList(
        databasePaths: <String?>[_legacyAbsolute, '287290/cover.webp'],
        remoteInventory: const <String, int>{'287290/cover.webp': 100},
      );

      expect(list, <String>['287290/cover.webp']);
    });
  });
}
