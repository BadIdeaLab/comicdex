import 'package:flutter_test/flutter_test.dart';

import '../test_support/fixtures/sample_comic.dart';
import '../test_support/storage/sqlite_test_harness.dart';

void main() {
  group('DownloadedLibraryRepository', () {
    late SqliteTestHarness harness;

    setUp(() async {
      harness = SqliteTestHarness();
      await harness.initialize();
    });

    tearDown(() async {
      await harness.dispose();
    });

    test('also records the tag ids in ComicTagId', () async {
      await harness.downloadedLibraryRepository.saveDownloadedComic(
        comic: sampleComic(id: '800', mediaId: '500'),
        rootDirectoryPath: '/downloads/800',
        coverLocalPath: null,
      );

      expect(await harness.comicTagRepository.loadTagIds('800'), <int>{1});
    });

    test('loads downloaded comics with parsed tags and metadata', () async {
      final comic = sampleComic(id: '800', mediaId: '500');
      final timestamp = DateTime(2026, 5, 2, 10, 30);
      await harness.downloadedLibraryRepository.saveDownloadedComic(
        comic: comic,
        rootDirectoryPath: '/downloads/800',
        coverLocalPath: '/downloads/800/cover.webp',
        downloadedAt: timestamp,
      );
      await harness.downloadedLibraryRepository.saveLastReadAt(
        '800',
        DateTime(2026, 5, 3, 11, 0),
      );

      final downloadedComics =
          await harness.downloadedLibraryRepository.loadDownloadedComics();

      expect(downloadedComics, hasLength(1));
      expect(downloadedComics.single.comicId, '800');
      expect(downloadedComics.single.title, 'Sample Comic');
      expect(downloadedComics.single.pageCount, comic.numPages);
      expect(downloadedComics.single.coverLocalPath, '/downloads/800/cover.webp');
      expect(downloadedComics.single.rootDirectoryPath, '/downloads/800');
      expect(downloadedComics.single.downloadedAt, timestamp);
      expect(downloadedComics.single.lastReadAt, DateTime(2026, 5, 3, 11, 0));
      expect(downloadedComics.single.numFavorites, comic.numFavorites);
      expect(downloadedComics.single.tags.single.name, 'sample');
      expect(downloadedComics.single.tags.single.type, 'tag');
    });

    test('saving again keeps when it was downloaded and last read', () async {
      // Repairing missing pages re-runs the download job, which saves this
      // row a second time. With insertOrReplace that rebuilt the row: the
      // comic jumped to the top of "Latest Downloaded" and its reading
      // history was silently dropped.
      final comic = sampleComic(id: '800', mediaId: '500');
      final downloadedAt = DateTime(2026, 5, 2, 10, 30);
      final lastReadAt = DateTime(2026, 5, 3, 11, 0);
      await harness.downloadedLibraryRepository.saveDownloadedComic(
        comic: comic,
        rootDirectoryPath: '/downloads/800',
        coverLocalPath: '/downloads/800/cover.webp',
        downloadedAt: downloadedAt,
      );
      await harness.downloadedLibraryRepository.saveLastReadAt(
        '800',
        lastReadAt,
      );

      await harness.downloadedLibraryRepository.saveDownloadedComic(
        comic: comic,
        rootDirectoryPath: '/downloads/800',
        coverLocalPath: '/downloads/800/cover.webp',
      );

      final stored =
          (await harness.downloadedLibraryRepository.loadDownloadedComics())
              .single;
      expect(stored.downloadedAt, downloadedAt);
      expect(stored.lastReadAt, lastReadAt);
    });

    test('saving again still refreshes the metadata', () async {
      // The timestamps are pinned, but a repair exists precisely to correct
      // what is stored — so everything else must still be written.
      await harness.downloadedLibraryRepository.saveDownloadedComic(
        comic: sampleComic(id: '800', mediaId: '500'),
        rootDirectoryPath: '/downloads/800',
        coverLocalPath: null,
        downloadedAt: DateTime(2026, 5, 2, 10, 30),
      );

      await harness.downloadedLibraryRepository.saveDownloadedComic(
        comic: sampleComic(id: '800', mediaId: '500').copyWith(numPages: 42),
        rootDirectoryPath: '/downloads/800',
        coverLocalPath: '/downloads/800/cover.webp',
      );

      final stored =
          (await harness.downloadedLibraryRepository.loadDownloadedComics())
              .single;
      expect(stored.coverLocalPath, '/downloads/800/cover.webp');
      expect(stored.pageCount, 42);
    });
  });
}
