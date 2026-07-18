import 'dart:io';

import 'package:concept_nhv/application/reader/load_offline_comic_use_case.dart';
import 'package:concept_nhv/services/download_asset_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../test_support/fixtures/sample_comic.dart';
import '../test_support/storage/sqlite_test_harness.dart';

void main() {
  group('LoadOfflineComicUseCase', () {
    late SqliteTestHarness harness;
    late Directory tempDirectory;
    late LoadOfflineComicUseCase useCase;

    setUp(() async {
      harness = SqliteTestHarness();
      await harness.initialize();
      tempDirectory = await Directory.systemTemp.createTemp(
        'load_offline_comic_use_case_test',
      );
      useCase = LoadOfflineComicUseCase(
        downloadQueueRepository: harness.downloadQueueRepository,
        downloadedLibraryRepository: harness.downloadedLibraryRepository,
        downloadAssetStore: DownloadAssetStore(
          directoryResolver: () async => tempDirectory,
        ),
      );
    });

    tearDown(() async {
      await harness.dispose();
      await tempDirectory.delete(recursive: true);
    });

    test('returns null when no completed download exists for the comic', () async {
      final result = await useCase.execute('9999');

      expect(result, isNull);
    });

    test('reconstructs Comic resolving relative local paths to absolute', () async {
      final comic = sampleComic(id: '803', mediaId: '503');

      await harness.downloadedLibraryRepository.saveDownloadedComic(
        comic: comic,
        rootDirectoryPath: '803',
        coverLocalPath: p.join('803', 'cover.webp'),
        downloadedAt: DateTime(2026, 5, 1),
      );

      await harness.downloadQueueRepository.upsertJobManifest(
        comic: comic,
        title: 'Sample Comic',
      );
      await harness.downloadQueueRepository.markJobDownloading('803');
      await harness.downloadQueueRepository.markPageCompleted(
        comicId: '803',
        pageNumber: 1,
        sourceServer: 'i1.nhentai.net',
        localPath: p.join('803', 'pages', '1.jpg'),
        storedFormat: 'jpg',
        byteSize: 100,
      );

      final result = await useCase.execute('803');

      expect(result, isNotNull);
      expect(
        result!.images.pages[0].path,
        p.join(tempDirectory.path, '803', 'pages', '1.jpg'),
      );
    });

    test(
      'keeps legacy absolute local paths unchanged (pre-P51 downloads)',
      () async {
      final comic = sampleComic(id: '800', mediaId: '500');

      // Save the completed library record.
      await harness.downloadedLibraryRepository.saveDownloadedComic(
        comic: comic,
        rootDirectoryPath: '/downloads/800',
        coverLocalPath: '/downloads/800/cover.webp',
        downloadedAt: DateTime(2026, 5, 1),
      );

      // Set up download job pages.
      await harness.downloadQueueRepository.upsertJobManifest(
        comic: comic,
        title: 'Sample Comic',
      );
      await harness.downloadQueueRepository.markJobDownloading('800');
      await harness.downloadQueueRepository.markPageCompleted(
        comicId: '800',
        pageNumber: 1,
        sourceServer: 'i1.nhentai.net',
        localPath: '/downloads/800/pages/1.jpg',
        storedFormat: 'jpg',
        byteSize: 100,
      );
      await harness.downloadQueueRepository.markPageCompleted(
        comicId: '800',
        pageNumber: 2,
        sourceServer: 'i1.nhentai.net',
        localPath: '/downloads/800/pages/2.jpg',
        storedFormat: 'jpg',
        byteSize: 120,
      );

      final result = await useCase.execute('800');

      expect(result, isNotNull);
      expect(result!.id, '800');
      expect(result.mediaId, '500');
      expect(result.numPages, comic.numPages);
      expect(result.images.pages, hasLength(2));
      expect(result.images.pages[0].path, '/downloads/800/pages/1.jpg');
      expect(result.images.pages[1].path, '/downloads/800/pages/2.jpg');
    });

    test('falls back to remotePath for pages without a local path', () async {
      final comic = sampleComic(id: '801', mediaId: '501');

      await harness.downloadedLibraryRepository.saveDownloadedComic(
        comic: comic,
        rootDirectoryPath: '/downloads/801',
        coverLocalPath: '/downloads/801/cover.webp',
        downloadedAt: DateTime(2026, 5, 1),
      );

      await harness.downloadQueueRepository.upsertJobManifest(
        comic: comic,
        title: 'Sample Comic',
      );
      await harness.downloadQueueRepository.markJobDownloading('801');
      // Only page 1 completed with a local path; page 2 stays pending (no localPath).
      await harness.downloadQueueRepository.markPageCompleted(
        comicId: '801',
        pageNumber: 1,
        sourceServer: 'i1.nhentai.net',
        localPath: '/downloads/801/pages/1.jpg',
        storedFormat: 'jpg',
        byteSize: 100,
      );

      final result = await useCase.execute('801');

      expect(result, isNotNull);
      expect(result!.images.pages[0].path, '/downloads/801/pages/1.jpg');
      // Page 2 was not completed — falls back to the remote path stored at manifest time.
      expect(result.images.pages[1].path, isNotNull);
      expect(result.images.pages[1].path, isNot(startsWith('/')));
    });

    test('preserves comic tags from the saved snapshot', () async {
      final comic = sampleComic(id: '802', mediaId: '502');

      await harness.downloadedLibraryRepository.saveDownloadedComic(
        comic: comic,
        rootDirectoryPath: '/downloads/802',
        coverLocalPath: '/downloads/802/cover.webp',
        downloadedAt: DateTime(2026, 5, 1),
      );
      await harness.downloadQueueRepository.upsertJobManifest(
        comic: comic,
        title: 'Sample Comic',
      );

      final result = await useCase.execute('802');

      expect(result, isNotNull);
      expect(result!.tags, hasLength(comic.tags.length));
      expect(result.tags.first.name, comic.tags.first.name);
    });
  });
}
