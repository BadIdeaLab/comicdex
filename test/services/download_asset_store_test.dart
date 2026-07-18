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

    test('resolveAbsolutePath returns legacy absolute paths unchanged', () async {
      const legacyPath = '/old-container-uuid/downloads/42/cover.webp';

      final resolved = await store.resolveAbsolutePath(legacyPath);

      expect(resolved, legacyPath);
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
