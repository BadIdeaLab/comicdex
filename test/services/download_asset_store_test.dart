import 'dart:io';
import 'dart:typed_data';

import 'package:concept_nhv/services/download_asset_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('DownloadAssetStore', () {
    late Directory tempDirectory;
    late DownloadAssetStore store;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'download_asset_store_test',
      );
      store = DownloadAssetStore(directoryResolver: () async => tempDirectory);
    });

    tearDown(() async {
      await tempDirectory.delete(recursive: true);
    });

    test('savePage returns a path relative to the downloads root', () async {
      final relativePath = await store.savePage(
        comicId: '42',
        pageNumber: 3,
        bytes: Uint8List.fromList(<int>[1, 2, 3]),
        extension: 'jpg',
      );

      expect(relativePath, p.join('42', 'pages', '3.jpg'));
      expect(p.isAbsolute(relativePath), isFalse);
      final file = File(p.join(tempDirectory.path, relativePath));
      expect(await file.exists(), isTrue);
    });

    test('saveCover returns a path relative to the downloads root', () async {
      final relativePath = await store.saveCover(
        comicId: '42',
        bytes: Uint8List.fromList(<int>[1, 2, 3]),
        extension: 'webp',
      );

      expect(relativePath, p.join('42', 'cover.webp'));
      expect(p.isAbsolute(relativePath), isFalse);
    });

    test('resolveAbsolutePath joins a relative path against the current root', () async {
      final resolved = await store.resolveAbsolutePath(
        p.join('42', 'pages', '3.jpg'),
      );

      expect(resolved, p.join(tempDirectory.path, '42', 'pages', '3.jpg'));
    });

    test('resolveAbsolutePath re-roots a legacy absolute path', () async {
      // This used to assert the path came back untouched, which is what made
      // a restore look like a corrupt library: the files land under this
      // device's downloads root, while rows written before P51 still name the
      // container they came from. The bytes were there all along.
      const legacyPath = '/old-container-uuid/downloads/42/cover.webp';

      final resolved = await store.resolveAbsolutePath(legacyPath);

      expect(resolved, p.join(tempDirectory.path, '42', 'cover.webp'));
    });

    test('resolveAbsolutePath leaves an unmappable path alone', () async {
      // No downloads segment to cut at, so re-rooting would be a guess.
      const strayPath = '/somewhere/else/42/cover.webp';

      expect(await store.resolveAbsolutePath(strayPath), strayPath);
    });

    test('resolveAbsolutePath is unchanged for a container that has not moved',
        () async {
      // The same file named absolutely and relatively must resolve alike,
      // otherwise this fix would move the goalposts for every existing row.
      final relative = p.join('42', 'pages', '3.jpg');
      final absolute =
          '/some-container/downloads/42/pages/3.jpg';

      expect(
        await store.resolveAbsolutePath(absolute),
        await store.resolveAbsolutePath(relative),
      );
    });

    test('verifyPages finds a page recorded with a legacy absolute path',
        () async {
      // The restore symptom end to end: the file is present, the row points
      // at another device, and repair used to call the page missing and
      // re-download the library the mirror had just handed over.
      await store.savePage(
        comicId: '42',
        pageNumber: 1,
        bytes: Uint8List.fromList(<int>[1, 2, 3]),
        extension: 'jpg',
      );

      final missing = await store.verifyPages(<int, String?>{
        1: '/old-container-uuid/downloads/42/pages/1.jpg',
      });

      expect(missing, isEmpty);
    });

    test('verifyPages resolves relative paths before checking the filesystem', () async {
      final relativePath = await store.savePage(
        comicId: '42',
        pageNumber: 1,
        bytes: Uint8List.fromList(<int>[1, 2, 3]),
        extension: 'jpg',
      );

      final missing = await store.verifyPages(<int, String?>{
        1: relativePath,
        2: p.join('42', 'pages', 'missing.jpg'),
      });

      expect(missing, <int>[2]);
    });

    test('coverExists resolves a relative path before checking the filesystem', () async {
      final relativePath = await store.saveCover(
        comicId: '42',
        bytes: Uint8List.fromList(<int>[1, 2, 3]),
        extension: 'webp',
      );

      expect(await store.coverExists(relativePath), isTrue);
      expect(await store.coverExists(p.join('42', 'missing.webp')), isFalse);
      expect(await store.coverExists(null), isFalse);
    });
  });
}
