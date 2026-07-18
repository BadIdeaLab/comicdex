import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:concept_nhv/models/comic.dart';
import 'package:concept_nhv/models/comic_card_data.dart';
import 'package:concept_nhv/models/comic_images.dart';
import 'package:concept_nhv/models/comic_page_image.dart';
import 'package:concept_nhv/models/comic_tag.dart';
import 'package:concept_nhv/models/comic_title.dart';
import 'package:concept_nhv/models/download_job_status.dart';
import 'package:concept_nhv/models/downloads_sort_mode.dart';
import 'package:concept_nhv/models/download_page_status.dart';
import 'package:concept_nhv/models/download_request.dart';
import 'package:concept_nhv/services/download_asset_store.dart';
import 'package:concept_nhv/services/nhentai_cdn_config_service.dart';
import 'package:concept_nhv/state/download_manager_model.dart';
import 'package:concept_nhv/storage/download_settings_store.dart';
import 'package:concept_nhv/storage/options_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../test_support/fakes/fake_image_compression_service.dart';
import '../test_support/fakes/fake_nhentai_gateway.dart';
import '../test_support/fakes/fake_remote_asset_fetcher.dart';
import '../test_support/fixtures/sample_comic.dart';
import '../test_support/storage/sqlite_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DownloadManagerModel', () {
    late SqliteTestHarness harness;
    late Directory tempDirectory;

    setUp(() async {
      harness = SqliteTestHarness();
      await harness.initialize();
      tempDirectory = await Directory.systemTemp.createTemp('nhv-download-test');
    });

    tearDown(() async {
      await harness.dispose();
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('downloads pages, stores offline snapshot, and marks job complete', () async {
      final comic = sampleComic(id: '900', mediaId: '321');
      final compressionService = FakeImageCompressionService(
        result: Uint8List.fromList(<int>[1, 2, 3, 4]),
      );
      final manager = DownloadManagerModel(
        nhentaiGateway: FakeNhentaiGateway(detailComic: comic),
        cdnConfigService: _FakeCdnConfigService(),
        downloadQueueRepository: harness.downloadQueueRepository,
        downloadedLibraryRepository: harness.downloadedLibraryRepository,
        downloadSettingsRepository: DownloadSettingsStore(
          optionsStore: OptionsStore(localDatabase: harness.localDatabase),
        ),
        downloadAssetStore: DownloadAssetStore(
          directoryResolver: () async => tempDirectory,
        ),
        imageCompressionService: compressionService,
        remoteAssetFetcher: FakeRemoteAssetFetcher(
          responses: <String, Uint8List>{
            'https://i1.nhentai.net/galleries/321/1.jpg': Uint8List.fromList(<int>[1]),
            'https://i1.nhentai.net/galleries/321/2.jpg': Uint8List.fromList(<int>[2]),
            'https://t1.nhentai.net/galleries/321/cover.jpg': Uint8List.fromList(<int>[3]),
          },
        ),
      );

      await manager.initialize();
      await manager.enqueue(const DownloadRequest(comicId: '900', title: 'Sample'));
      await _waitForJobStatus(
        harness: harness,
        comicId: '900',
        status: 'completed',
      );
      await manager.waitForIdle();

      final job = await harness.downloadQueueRepository.loadJob('900');
      final pages = await harness.downloadQueueRepository.loadPages('900');
      final downloadedRows = await harness.localDatabase
          .customSelect('SELECT comic_id, cover_local_path FROM DownloadedComic')
          .get();

      expect(job?.completedPages, comic.numPages);
      // jpg is a Skia-safe format, so it is kept as-is instead of being
      // transcoded to WebP — the compression service should never be called.
      expect(pages.every((page) => page.storedFormat == 'jpg'), isTrue);
      expect(compressionService.callCount, 0);
      expect(downloadedRows.single.read<String>('comic_id'), '900');
      final firstPageFile = File(
        p.join(tempDirectory.path, pages.first.localPath!),
      );
      expect(await firstPageFile.exists(), isTrue);

      manager.dispose();
    });

    test('transcodes unsafe source formats (e.g. avif) to WebP', () async {
      final comic = _comicWithPageExtension(id: '903', mediaId: '999', typeCode: 'a', extension: 'avif');
      final compressionService = FakeImageCompressionService(
        result: Uint8List.fromList(<int>[1, 2, 3, 4]),
      );
      final manager = DownloadManagerModel(
        nhentaiGateway: FakeNhentaiGateway(detailComic: comic),
        cdnConfigService: _FakeCdnConfigService(),
        downloadQueueRepository: harness.downloadQueueRepository,
        downloadedLibraryRepository: harness.downloadedLibraryRepository,
        downloadSettingsRepository: DownloadSettingsStore(
          optionsStore: OptionsStore(localDatabase: harness.localDatabase),
        ),
        downloadAssetStore: DownloadAssetStore(
          directoryResolver: () async => tempDirectory,
        ),
        imageCompressionService: compressionService,
        remoteAssetFetcher: FakeRemoteAssetFetcher(
          responses: <String, Uint8List>{
            'https://i1.nhentai.net/galleries/999/1.avif': Uint8List.fromList(<int>[1]),
            'https://i1.nhentai.net/galleries/999/2.avif': Uint8List.fromList(<int>[2]),
            'https://t1.nhentai.net/galleries/999/cover.avif': Uint8List.fromList(<int>[3]),
          },
        ),
      );

      await manager.initialize();
      await manager.enqueue(const DownloadRequest(comicId: '903', title: 'Avif'));
      await _waitForJobStatus(
        harness: harness,
        comicId: '903',
        status: 'completed',
      );
      await manager.waitForIdle();

      final pages = await harness.downloadQueueRepository.loadPages('903');
      expect(pages.every((page) => page.storedFormat == 'webp'), isTrue);
      expect(compressionService.callCount, greaterThan(0));

      manager.dispose();
    });

    test('falls back to original page format when WebP compression is unsupported', () async {
      final comic = _comicWithPageExtension(id: '901', mediaId: '654', typeCode: 'a', extension: 'avif');
      final manager = DownloadManagerModel(
        nhentaiGateway: FakeNhentaiGateway(detailComic: comic),
        cdnConfigService: _FakeCdnConfigService(),
        downloadQueueRepository: harness.downloadQueueRepository,
        downloadedLibraryRepository: harness.downloadedLibraryRepository,
        downloadSettingsRepository: DownloadSettingsStore(
          optionsStore: OptionsStore(localDatabase: harness.localDatabase),
        ),
        downloadAssetStore: DownloadAssetStore(
          directoryResolver: () async => tempDirectory,
        ),
        imageCompressionService: FakeImageCompressionService(
          error: UnsupportedError('webp'),
        ),
        remoteAssetFetcher: FakeRemoteAssetFetcher(
          responses: <String, Uint8List>{
            'https://i1.nhentai.net/galleries/654/1.avif': Uint8List.fromList(<int>[1]),
            'https://i1.nhentai.net/galleries/654/2.avif': Uint8List.fromList(<int>[2]),
            'https://t1.nhentai.net/galleries/654/cover.avif': Uint8List.fromList(<int>[3]),
          },
        ),
      );

      await manager.initialize();
      await manager.enqueue(const DownloadRequest(comicId: '901', title: 'Fallback'));
      await _waitForJobStatus(
        harness: harness,
        comicId: '901',
        status: 'completed',
      );
      await manager.waitForIdle();

      final pages = await harness.downloadQueueRepository.loadPages('901');
      expect(pages.every((page) => page.storedFormat == 'avif'), isTrue);
      expect(pages.every((page) => page.localPath!.endsWith('.avif')), isTrue);

      manager.dispose();
    });

    test('ignores duplicate enqueue requests for the same comic while one is already starting', () async {
      final comic = sampleComic(id: '902', mediaId: '777');
      final gateway = FakeNhentaiGateway(detailComic: comic);
      final manager = DownloadManagerModel(
        nhentaiGateway: gateway,
        cdnConfigService: _FakeCdnConfigService(),
        downloadQueueRepository: harness.downloadQueueRepository,
        downloadedLibraryRepository: harness.downloadedLibraryRepository,
        downloadSettingsRepository: DownloadSettingsStore(
          optionsStore: OptionsStore(localDatabase: harness.localDatabase),
        ),
        downloadAssetStore: DownloadAssetStore(
          directoryResolver: () async => tempDirectory,
        ),
        imageCompressionService: FakeImageCompressionService(),
        remoteAssetFetcher: FakeRemoteAssetFetcher(
          responses: <String, Uint8List>{
            'https://i1.nhentai.net/galleries/777/1.jpg': Uint8List.fromList(<int>[1]),
            'https://i1.nhentai.net/galleries/777/2.jpg': Uint8List.fromList(<int>[2]),
            'https://t1.nhentai.net/galleries/777/cover.jpg': Uint8List.fromList(<int>[3]),
          },
        ),
      );

      await manager.initialize();
      await Future.wait(<Future<void>>[
        manager.enqueue(const DownloadRequest(comicId: '902', title: 'Dupe')),
        manager.enqueue(const DownloadRequest(comicId: '902', title: 'Dupe')),
      ]);
      await _waitForJobStatus(
        harness: harness,
        comicId: '902',
        status: 'completed',
      );
      await manager.waitForIdle();

      expect(gateway.loadedComicDetailIds, hasLength(2));
      expect(
        gateway.loadedComicDetailIds.every((comicId) => comicId == '902'),
        isTrue,
      );
      expect(manager.isMutating('902'), isFalse);
      expect(await harness.downloadQueueRepository.loadJobs(), hasLength(1));
      expect(await harness.downloadQueueRepository.loadJob('902'), isNotNull);

      manager.dispose();
    });

    test('pause after resume stays paused when the current page finishes in flight', () async {
      final comic = _threePageComic(id: '903', mediaId: '778');
      final secondPageCompleter = Completer<Uint8List>();
      final manager = DownloadManagerModel(
        nhentaiGateway: FakeNhentaiGateway(detailComic: comic),
        cdnConfigService: _FakeCdnConfigService(),
        downloadQueueRepository: harness.downloadQueueRepository,
        downloadedLibraryRepository: harness.downloadedLibraryRepository,
        downloadSettingsRepository: DownloadSettingsStore(
          optionsStore: OptionsStore(localDatabase: harness.localDatabase),
        ),
        downloadAssetStore: DownloadAssetStore(
          directoryResolver: () async => tempDirectory,
        ),
        imageCompressionService: FakeImageCompressionService(),
        remoteAssetFetcher: FakeRemoteAssetFetcher(
          responses: <String, Uint8List>{
            'https://i1.nhentai.net/galleries/778/1.jpg': Uint8List.fromList(<int>[1]),
            'https://i1.nhentai.net/galleries/778/3.jpg': Uint8List.fromList(<int>[4]),
            'https://t1.nhentai.net/galleries/778/cover.jpg': Uint8List.fromList(<int>[3]),
          },
          deferredResponses: <String, Future<Uint8List> Function()>{
            'https://i1.nhentai.net/galleries/778/2.jpg': () => secondPageCompleter.future,
          },
        ),
      );

      await manager.initialize();
      await manager.enqueue(const DownloadRequest(comicId: '903', title: 'Pause Resume'));
      await _waitForJobStatus(
        harness: harness,
        comicId: '903',
        status: 'downloading',
      );
      await _waitForPageStatus(
        harness: harness,
        comicId: '903',
        pageNumber: 1,
        status: 'completed',
      );
      await _waitForPageStatus(
        harness: harness,
        comicId: '903',
        pageNumber: 2,
        status: 'pending',
      );

      await manager.pause('903');
      expect((await harness.downloadQueueRepository.loadJob('903'))?.status, DownloadJobStatus.paused);
      await manager.waitForIdle();

      await manager.resume('903');
      await _waitForJobStatus(
        harness: harness,
        comicId: '903',
        status: 'downloading',
      );
      await _waitForPageStatus(
        harness: harness,
        comicId: '903',
        pageNumber: 2,
        status: 'downloading',
      );

      await manager.pause('903');
      expect((await harness.downloadQueueRepository.loadJob('903'))?.status, DownloadJobStatus.paused);

      secondPageCompleter.complete(Uint8List.fromList(<int>[2]));
      await manager.waitForIdle();

      final job = await harness.downloadQueueRepository.loadJob('903');
      final pages = await harness.downloadQueueRepository.loadPages('903');

      expect(job, isNotNull);
      expect(job!.status, DownloadJobStatus.paused);
      expect(job.completedPages, 2);
      expect(job.nextPageNumber, 3);
      expect(job.completedAt, isNull);
      expect(pages[1].status, DownloadPageStatus.completed);
      expect(pages, hasLength(comic.numPages));
      expect(pages[2].status, DownloadPageStatus.pending);

      manager.dispose();
    });

    test('initialize pauses interrupted downloading jobs when auto resume is disabled', () async {
      final comic = sampleComic(id: '904', mediaId: '779');
      final downloadSettingsStore = DownloadSettingsStore(
        optionsStore: OptionsStore(localDatabase: harness.localDatabase),
      );
      await downloadSettingsStore.saveAutoResumeEnabled(false);
      await harness.downloadQueueRepository.upsertJobManifest(
        comic: comic,
        title: 'Interrupted',
      );
      await harness.downloadQueueRepository.markJobDownloading('904');
      await harness.downloadQueueRepository.markPageCompleted(
        comicId: '904',
        pageNumber: 1,
        sourceServer: 'i1.nhentai.net',
        localPath: '/tmp/904-1.webp',
        storedFormat: 'webp',
        byteSize: 123,
      );
      final remoteAssetFetcher = FakeRemoteAssetFetcher(
        responses: <String, Uint8List>{
          'https://i1.nhentai.net/galleries/779/1.jpg': Uint8List.fromList(<int>[1]),
          'https://i1.nhentai.net/galleries/779/2.jpg': Uint8List.fromList(<int>[2]),
          'https://t1.nhentai.net/galleries/779/cover.jpg': Uint8List.fromList(<int>[3]),
        },
      );
      final manager = DownloadManagerModel(
        nhentaiGateway: FakeNhentaiGateway(detailComic: comic),
        cdnConfigService: _FakeCdnConfigService(),
        downloadQueueRepository: harness.downloadQueueRepository,
        downloadedLibraryRepository: harness.downloadedLibraryRepository,
        downloadSettingsRepository: downloadSettingsStore,
        downloadAssetStore: DownloadAssetStore(
          directoryResolver: () async => tempDirectory,
        ),
        imageCompressionService: FakeImageCompressionService(),
        remoteAssetFetcher: remoteAssetFetcher,
      );

      await manager.initialize();
      await manager.waitForIdle();

      final job = await harness.downloadQueueRepository.loadJob('904');

      expect(job, isNotNull);
      expect(job!.status, DownloadJobStatus.paused);
      expect(job.completedPages, 1);
      expect(job.nextPageNumber, 2);
      expect(remoteAssetFetcher.requestedUrls, isEmpty);

      manager.dispose();
    });

    test('resumed lifecycle pauses interrupted downloads when auto resume is disabled', () async {
      final comic = sampleComic(id: '905', mediaId: '780');
      final downloadSettingsStore = DownloadSettingsStore(
        optionsStore: OptionsStore(localDatabase: harness.localDatabase),
      );
      final manager = DownloadManagerModel(
        nhentaiGateway: FakeNhentaiGateway(detailComic: comic),
        cdnConfigService: _FakeCdnConfigService(),
        downloadQueueRepository: harness.downloadQueueRepository,
        downloadedLibraryRepository: harness.downloadedLibraryRepository,
        downloadSettingsRepository: downloadSettingsStore,
        downloadAssetStore: DownloadAssetStore(
          directoryResolver: () async => tempDirectory,
        ),
        imageCompressionService: FakeImageCompressionService(),
        remoteAssetFetcher: FakeRemoteAssetFetcher(),
      );

      await manager.initialize();
      await harness.downloadQueueRepository.upsertJobManifest(
        comic: comic,
        title: 'Resume Disabled',
      );
      await harness.downloadQueueRepository.markJobDownloading('905');
      await harness.downloadQueueRepository.markPageCompleted(
        comicId: '905',
        pageNumber: 1,
        sourceServer: 'i1.nhentai.net',
        localPath: '/tmp/905-1.webp',
        storedFormat: 'webp',
        byteSize: 123,
      );
      await downloadSettingsStore.saveAutoResumeEnabled(false);

      manager.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await _waitForJobStatus(
        harness: harness,
        comicId: '905',
        status: 'paused',
      );
      await manager.waitForIdle();

      final job = await harness.downloadQueueRepository.loadJob('905');
      expect(job, isNotNull);
      expect(job!.status, DownloadJobStatus.paused);

      manager.dispose();
    });

    test('disabling auto resume during an active foreground download does not stop the current job', () async {
      final comic = _threePageComic(id: '906', mediaId: '781');
      final secondPageCompleter = Completer<Uint8List>();
      final downloadSettingsStore = DownloadSettingsStore(
        optionsStore: OptionsStore(localDatabase: harness.localDatabase),
      );
      final manager = DownloadManagerModel(
        nhentaiGateway: FakeNhentaiGateway(detailComic: comic),
        cdnConfigService: _FakeCdnConfigService(),
        downloadQueueRepository: harness.downloadQueueRepository,
        downloadedLibraryRepository: harness.downloadedLibraryRepository,
        downloadSettingsRepository: downloadSettingsStore,
        downloadAssetStore: DownloadAssetStore(
          directoryResolver: () async => tempDirectory,
        ),
        imageCompressionService: FakeImageCompressionService(),
        remoteAssetFetcher: FakeRemoteAssetFetcher(
          responses: <String, Uint8List>{
            'https://i1.nhentai.net/galleries/781/1.jpg': Uint8List.fromList(<int>[1]),
            'https://i1.nhentai.net/galleries/781/3.jpg': Uint8List.fromList(<int>[3]),
            'https://t1.nhentai.net/galleries/781/cover.jpg': Uint8List.fromList(<int>[4]),
          },
          deferredResponses: <String, Future<Uint8List> Function()>{
            'https://i1.nhentai.net/galleries/781/2.jpg': () => secondPageCompleter.future,
          },
        ),
      );

      await manager.initialize();
      await manager.enqueue(const DownloadRequest(comicId: '906', title: 'Toggle Auto Resume'));
      await _waitForPageStatus(
        harness: harness,
        comicId: '906',
        pageNumber: 2,
        status: 'downloading',
      );

      await downloadSettingsStore.saveAutoResumeEnabled(false);
      secondPageCompleter.complete(Uint8List.fromList(<int>[2]));

      await _waitForJobStatus(
        harness: harness,
        comicId: '906',
        status: 'completed',
      );
      await manager.waitForIdle();

      final job = await harness.downloadQueueRepository.loadJob('906');
      expect(job, isNotNull);
      expect(job!.status, DownloadJobStatus.completed);

      manager.dispose();
    });

    test('refresh builds a unified list without duplicating completed downloads', () async {
      final comic = sampleComic(id: '907', mediaId: '782');
      final manager = DownloadManagerModel(
        nhentaiGateway: FakeNhentaiGateway(detailComic: comic),
        cdnConfigService: _FakeCdnConfigService(),
        downloadQueueRepository: harness.downloadQueueRepository,
        downloadedLibraryRepository: harness.downloadedLibraryRepository,
        downloadSettingsRepository: DownloadSettingsStore(
          optionsStore: OptionsStore(localDatabase: harness.localDatabase),
        ),
        downloadAssetStore: DownloadAssetStore(
          directoryResolver: () async => tempDirectory,
        ),
        imageCompressionService: FakeImageCompressionService(),
        remoteAssetFetcher: FakeRemoteAssetFetcher(),
      );

      await harness.downloadQueueRepository.upsertJobManifest(
        comic: comic,
        title: 'Completed Comic',
      );
      await harness.downloadQueueRepository.markJobCompleted('907');
      await harness.downloadedLibraryRepository.saveDownloadedComic(
        comic: comic,
        rootDirectoryPath: '/downloads/907',
        coverLocalPath: '/downloads/907/cover.webp',
      );

      await manager.refresh();

      final items = manager.downloadItems
          .where((item) => item.comicId == '907')
          .toList(growable: false);

      expect(items, hasLength(1));
      expect(items.single.status, DownloadJobStatus.completed);
      expect(items.single.tags.single.name, 'sample');
      expect(items.single.coverLocalPath, '/downloads/907/cover.webp');
      expect(items.single.pageCount, comic.numPages);

      manager.dispose();
    });

    test('sorts completed download items by last read while keeping active jobs first', () async {
      final firstComic = sampleComic(id: '908', mediaId: '783');
      final secondComic = sampleComic(id: '909', mediaId: '784');
      final activeComic = sampleComic(id: '910', mediaId: '785');
      final manager = DownloadManagerModel(
        nhentaiGateway: FakeNhentaiGateway(detailComic: activeComic),
        cdnConfigService: _FakeCdnConfigService(),
        downloadQueueRepository: harness.downloadQueueRepository,
        downloadedLibraryRepository: harness.downloadedLibraryRepository,
        downloadSettingsRepository: DownloadSettingsStore(
          optionsStore: OptionsStore(localDatabase: harness.localDatabase),
        ),
        downloadAssetStore: DownloadAssetStore(
          directoryResolver: () async => tempDirectory,
        ),
        imageCompressionService: FakeImageCompressionService(),
        remoteAssetFetcher: FakeRemoteAssetFetcher(),
      );

      await harness.downloadQueueRepository.upsertJobManifest(
        comic: activeComic,
        title: 'Active Comic',
        requestedAt: DateTime(2026, 5, 1, 10),
      );
      await harness.downloadQueueRepository.markJobPaused('910');

      await harness.downloadQueueRepository.upsertJobManifest(
        comic: firstComic,
        title: 'First Completed',
        requestedAt: DateTime(2026, 5, 1, 9),
      );
      await harness.downloadQueueRepository.markJobCompleted(
        '908',
        completedAt: DateTime(2026, 5, 1, 12),
      );
      await harness.downloadedLibraryRepository.saveDownloadedComic(
        comic: firstComic,
        rootDirectoryPath: '/downloads/908',
        coverLocalPath: null,
        downloadedAt: DateTime(2026, 5, 1, 12),
      );

      await harness.downloadQueueRepository.upsertJobManifest(
        comic: secondComic,
        title: 'Second Completed',
        requestedAt: DateTime(2026, 5, 1, 11),
      );
      await harness.downloadQueueRepository.markJobCompleted(
        '909',
        completedAt: DateTime(2026, 5, 1, 13),
      );
      await harness.downloadedLibraryRepository.saveDownloadedComic(
        comic: secondComic,
        rootDirectoryPath: '/downloads/909',
        coverLocalPath: null,
        downloadedAt: DateTime(2026, 5, 1, 13),
      );
      await harness.downloadedLibraryRepository.saveLastReadAt(
        '908',
        DateTime(2026, 5, 2, 8),
      );
      await harness.downloadedLibraryRepository.saveLastReadAt(
        '909',
        DateTime(2026, 5, 1, 18),
      );

      await manager.refresh();
      manager.setDownloadsSortMode(DownloadsSortMode.lastRead);

      final sortedComicIds = manager.sortedDownloadItems
          .map((item) => item.comicId)
          .toList(growable: false);

      expect(
        sortedComicIds,
        <String>[
          '910',
          '908',
          '909',
        ],
      );
      expect(manager.sortedDownloadItems.first.status, DownloadJobStatus.paused);
      expect(manager.sortedDownloadItems[1].comicId, '908');
      expect(manager.sortedDownloadItems[2].comicId, '909');

      manager.dispose();
    });

    test('sorts completed items by direction and favorites while keeping active jobs first', () async {
      final lowFavoriteComic = sampleComic(
        id: '913',
        mediaId: '788',
      ).copyWith(numFavorites: 4);
      final highFavoriteComic = sampleComic(
        id: '914',
        mediaId: '789',
      ).copyWith(numFavorites: 80);
      final unknownFavoriteComic = sampleComic(
        id: '915',
        mediaId: '790',
      ).copyWith(numFavorites: null);
      final activeComic = sampleComic(id: '916', mediaId: '791');
      final manager = DownloadManagerModel(
        nhentaiGateway: FakeNhentaiGateway(detailComic: activeComic),
        cdnConfigService: _FakeCdnConfigService(),
        downloadQueueRepository: harness.downloadQueueRepository,
        downloadedLibraryRepository: harness.downloadedLibraryRepository,
        downloadSettingsRepository: DownloadSettingsStore(
          optionsStore: OptionsStore(localDatabase: harness.localDatabase),
        ),
        downloadAssetStore: DownloadAssetStore(
          directoryResolver: () async => tempDirectory,
        ),
        imageCompressionService: FakeImageCompressionService(),
        remoteAssetFetcher: FakeRemoteAssetFetcher(),
      );

      await harness.downloadQueueRepository.upsertJobManifest(
        comic: activeComic,
        title: 'Active Comic',
        requestedAt: DateTime(2026, 5, 1, 8),
      );
      await harness.downloadQueueRepository.markJobPaused('916');

      for (final entry in <({Comic comic, DateTime downloadedAt})>[
        (comic: lowFavoriteComic, downloadedAt: DateTime(2026, 5, 1, 12)),
        (comic: highFavoriteComic, downloadedAt: DateTime(2026, 5, 1, 13)),
        (comic: unknownFavoriteComic, downloadedAt: DateTime(2026, 5, 1, 14)),
      ]) {
        await harness.downloadQueueRepository.upsertJobManifest(
          comic: entry.comic,
          title: entry.comic.title.pretty ?? entry.comic.id,
          requestedAt: entry.downloadedAt,
        );
        await harness.downloadQueueRepository.markJobCompleted(
          entry.comic.id,
          completedAt: entry.downloadedAt,
        );
        await harness.downloadedLibraryRepository.saveDownloadedComic(
          comic: entry.comic,
          rootDirectoryPath: '/downloads/${entry.comic.id}',
          coverLocalPath: null,
          downloadedAt: entry.downloadedAt,
        );
      }

      await manager.refresh();
      manager.setDownloadsSortMode(DownloadsSortMode.latestDownloaded);
      manager.setDownloadsSortDirection(DownloadsSortDirection.ascending);

      expect(
        manager.sortedDownloadItems.map((item) => item.comicId),
        <String>['916', '913', '914', '915'],
      );

      manager.setDownloadsSortMode(DownloadsSortMode.mostFavorited);
      manager.setDownloadsSortDirection(DownloadsSortDirection.descending);

      expect(
        manager.sortedDownloadItems.map((item) => item.comicId),
        <String>['916', '914', '913', '915'],
      );

      manager.setDownloadsSortDirection(DownloadsSortDirection.ascending);

      expect(
        manager.sortedDownloadItems.map((item) => item.comicId),
        <String>['916', '913', '914', '915'],
      );

      manager.dispose();
    });

    test('sorts completed items by title', () async {
      final comicB = sampleComic(
        id: '920',
        mediaId: '792',
      ).copyWith(title: ComicTitle(pretty: 'Banana Story'));
      final comicA = sampleComic(
        id: '921',
        mediaId: '793',
      ).copyWith(title: ComicTitle(pretty: 'apple tale'));
      final comicC = sampleComic(
        id: '922',
        mediaId: '794',
      ).copyWith(title: ComicTitle(pretty: 'Cherry Log'));
      final manager = DownloadManagerModel(
        nhentaiGateway: FakeNhentaiGateway(detailComic: comicA),
        cdnConfigService: _FakeCdnConfigService(),
        downloadQueueRepository: harness.downloadQueueRepository,
        downloadedLibraryRepository: harness.downloadedLibraryRepository,
        downloadSettingsRepository: DownloadSettingsStore(
          optionsStore: OptionsStore(localDatabase: harness.localDatabase),
        ),
        downloadAssetStore: DownloadAssetStore(
          directoryResolver: () async => tempDirectory,
        ),
        imageCompressionService: FakeImageCompressionService(),
        remoteAssetFetcher: FakeRemoteAssetFetcher(),
      );

      for (final comic in <Comic>[comicB, comicA, comicC]) {
        await harness.downloadQueueRepository.upsertJobManifest(
          comic: comic,
          title: comic.title.pretty!,
        );
        await harness.downloadQueueRepository.markJobCompleted(comic.id);
        await harness.downloadedLibraryRepository.saveDownloadedComic(
          comic: comic,
          rootDirectoryPath: '/downloads/${comic.id}',
          coverLocalPath: null,
        );
      }

      await manager.refresh();
      manager.setDownloadsSortMode(DownloadsSortMode.title);
      manager.setDownloadsSortDirection(DownloadsSortDirection.ascending);

      expect(
        manager.sortedDownloadItems.map((item) => item.comicId),
        <String>['921', '920', '922'],
      );

      manager.setDownloadsSortDirection(DownloadsSortDirection.descending);

      expect(
        manager.sortedDownloadItems.map((item) => item.comicId),
        <String>['922', '920', '921'],
      );

      manager.dispose();
    });

    test('sorts completed items by author, with untagged comics last', () async {
      final comicWithArtist = sampleComic(id: '923', mediaId: '795').copyWith(
        tags: <ComicTag>[ComicTag(type: 'artist', name: 'zeta')],
      );
      final comicWithGroup = sampleComic(id: '924', mediaId: '796').copyWith(
        tags: <ComicTag>[ComicTag(type: 'group', name: 'alpha team')],
      );
      final comicWithoutAuthor = sampleComic(
        id: '925',
        mediaId: '797',
      ).copyWith(tags: const <ComicTag>[]);
      final manager = DownloadManagerModel(
        nhentaiGateway: FakeNhentaiGateway(detailComic: comicWithArtist),
        cdnConfigService: _FakeCdnConfigService(),
        downloadQueueRepository: harness.downloadQueueRepository,
        downloadedLibraryRepository: harness.downloadedLibraryRepository,
        downloadSettingsRepository: DownloadSettingsStore(
          optionsStore: OptionsStore(localDatabase: harness.localDatabase),
        ),
        downloadAssetStore: DownloadAssetStore(
          directoryResolver: () async => tempDirectory,
        ),
        imageCompressionService: FakeImageCompressionService(),
        remoteAssetFetcher: FakeRemoteAssetFetcher(),
      );

      for (final comic in <Comic>[
        comicWithArtist,
        comicWithGroup,
        comicWithoutAuthor,
      ]) {
        await harness.downloadQueueRepository.upsertJobManifest(
          comic: comic,
          title: comic.title.pretty!,
        );
        await harness.downloadQueueRepository.markJobCompleted(comic.id);
        await harness.downloadedLibraryRepository.saveDownloadedComic(
          comic: comic,
          rootDirectoryPath: '/downloads/${comic.id}',
          coverLocalPath: null,
        );
      }

      await manager.refresh();
      manager.setDownloadsSortMode(DownloadsSortMode.author);
      manager.setDownloadsSortDirection(DownloadsSortDirection.ascending);

      expect(
        manager.sortedDownloadItems.map((item) => item.comicId),
        // "alpha team" (group) < "zeta" (artist), untagged always last.
        <String>['924', '923', '925'],
      );

      manager.dispose();
    });

    test('refresh picks up online reader last read updates for completed sorting', () async {
      final olderDownload = sampleComic(id: '911', mediaId: '786');
      final latestRead = sampleComic(id: '912', mediaId: '787');
      final manager = DownloadManagerModel(
        nhentaiGateway: FakeNhentaiGateway(detailComic: latestRead),
        cdnConfigService: _FakeCdnConfigService(),
        downloadQueueRepository: harness.downloadQueueRepository,
        downloadedLibraryRepository: harness.downloadedLibraryRepository,
        downloadSettingsRepository: DownloadSettingsStore(
          optionsStore: OptionsStore(localDatabase: harness.localDatabase),
        ),
        downloadAssetStore: DownloadAssetStore(
          directoryResolver: () async => tempDirectory,
        ),
        imageCompressionService: FakeImageCompressionService(),
        remoteAssetFetcher: FakeRemoteAssetFetcher(),
      );

      await harness.downloadQueueRepository.upsertJobManifest(
        comic: olderDownload,
        title: 'Older Download',
        requestedAt: DateTime(2026, 5, 1, 9),
      );
      await harness.downloadQueueRepository.markJobCompleted(
        '911',
        completedAt: DateTime(2026, 5, 1, 12),
      );
      await harness.downloadedLibraryRepository.saveDownloadedComic(
        comic: olderDownload,
        rootDirectoryPath: '/downloads/911',
        coverLocalPath: null,
        downloadedAt: DateTime(2026, 5, 1, 12),
      );

      await harness.downloadQueueRepository.upsertJobManifest(
        comic: latestRead,
        title: 'Latest Read',
        requestedAt: DateTime(2026, 5, 1, 10),
      );
      await harness.downloadQueueRepository.markJobCompleted(
        '912',
        completedAt: DateTime(2026, 5, 1, 13),
      );
      await harness.downloadedLibraryRepository.saveDownloadedComic(
        comic: latestRead,
        rootDirectoryPath: '/downloads/912',
        coverLocalPath: null,
        downloadedAt: DateTime(2026, 5, 1, 13),
      );

      await manager.refresh();
      manager.setDownloadsSortMode(DownloadsSortMode.lastRead);

      await harness.downloadedLibraryRepository.saveLastReadAt(
        '911',
        DateTime(2026, 5, 2, 8),
      );
      await manager.refresh();

      final sortedComicIds = manager.sortedDownloadItems
          .map((item) => item.comicId)
          .toList(growable: false);

      expect(sortedComicIds, <String>['911', '912']);

      manager.dispose();
    });

    test(
      'repairCompleted re-downloads a missing cover without touching intact pages',
      () async {
        final comic = sampleComic(id: '930', mediaId: '441');
        final manager = DownloadManagerModel(
          nhentaiGateway: FakeNhentaiGateway(detailComic: comic),
          cdnConfigService: _FakeCdnConfigService(),
          downloadQueueRepository: harness.downloadQueueRepository,
          downloadedLibraryRepository: harness.downloadedLibraryRepository,
          downloadSettingsRepository: DownloadSettingsStore(
            optionsStore: OptionsStore(localDatabase: harness.localDatabase),
          ),
          downloadAssetStore: DownloadAssetStore(
            directoryResolver: () async => tempDirectory,
          ),
          imageCompressionService: FakeImageCompressionService(
            result: Uint8List.fromList(<int>[1, 2, 3, 4]),
          ),
          remoteAssetFetcher: FakeRemoteAssetFetcher(
            responses: <String, Uint8List>{
              'https://i1.nhentai.net/galleries/441/1.jpg': Uint8List.fromList(
                <int>[1],
              ),
              'https://i1.nhentai.net/galleries/441/2.jpg': Uint8List.fromList(
                <int>[2],
              ),
              'https://t1.nhentai.net/galleries/441/cover.jpg':
                  Uint8List.fromList(<int>[3]),
            },
          ),
        );

        await manager.initialize();
        await manager.enqueue(
          const DownloadRequest(comicId: '930', title: 'Sample'),
        );
        await _waitForJobStatus(
          harness: harness,
          comicId: '930',
          status: 'completed',
        );
        await manager.waitForIdle();

        final coverPathBeforeBreak =
            await harness.downloadedLibraryRepository.loadCoverLocalPath('930');
        expect(coverPathBeforeBreak, isNotNull);

        // Simulate the real-world scenario reported by the user: the cover
        // never got saved (coverLocalPath is null) even though pages
        // downloaded fine, so the UI silently falls back to a network thumb.
        await harness.downloadedLibraryRepository.updateCoverLocalPath(
          '930',
          null,
        );

        final repaired = await manager.repairCompleted('930');
        expect(repaired, isTrue);

        final coverPathAfterRepair =
            await harness.downloadedLibraryRepository.loadCoverLocalPath('930');
        expect(coverPathAfterRepair, isNotNull);
        expect(
          await File(p.join(tempDirectory.path, coverPathAfterRepair!)).exists(),
          isTrue,
        );

        // Repairing again should now be a no-op: pages and cover are intact.
        final repairedAgain = await manager.repairCompleted('930');
        expect(repairedAgain, isFalse);

        manager.dispose();
      },
    );

    test(
      'repairing a missing page does not re-download or overwrite an already-valid cover',
      () async {
        final comic = sampleComic(id: '935', mediaId: '447');
        final fetcher = FakeRemoteAssetFetcher(
          responses: <String, Uint8List>{
            'https://i1.nhentai.net/galleries/447/1.jpg': Uint8List.fromList(
              <int>[1],
            ),
            'https://i1.nhentai.net/galleries/447/2.jpg': Uint8List.fromList(
              <int>[2],
            ),
            'https://t1.nhentai.net/galleries/447/cover.jpg': Uint8List.fromList(
              <int>[3],
            ),
          },
        );
        final manager = DownloadManagerModel(
          nhentaiGateway: FakeNhentaiGateway(detailComic: comic),
          cdnConfigService: _FakeCdnConfigService(),
          downloadQueueRepository: harness.downloadQueueRepository,
          downloadedLibraryRepository: harness.downloadedLibraryRepository,
          downloadSettingsRepository: DownloadSettingsStore(
            optionsStore: OptionsStore(localDatabase: harness.localDatabase),
          ),
          downloadAssetStore: DownloadAssetStore(
            directoryResolver: () async => tempDirectory,
          ),
          imageCompressionService: FakeImageCompressionService(
            result: Uint8List.fromList(<int>[1, 2, 3, 4]),
          ),
          remoteAssetFetcher: fetcher,
        );

        await manager.initialize();
        await manager.enqueue(
          const DownloadRequest(comicId: '935', title: 'Sample'),
        );
        await _waitForJobStatus(
          harness: harness,
          comicId: '935',
          status: 'completed',
        );
        await manager.waitForIdle();

        final coverUrl = 'https://t1.nhentai.net/galleries/447/cover.jpg';
        expect(
          fetcher.requestedUrls.where((url) => url == coverUrl).length,
          1,
        );
        final coverPathBeforeRepair =
            await harness.downloadedLibraryRepository.loadCoverLocalPath('935');
        expect(coverPathBeforeRepair, isNotNull);

        // Break only page 1 on disk, leaving the cover untouched.
        final pages = await harness.downloadQueueRepository.loadPages('935');
        final page1 = pages.firstWhere((page) => page.pageNumber == 1);
        await File(p.join(tempDirectory.path, page1.localPath!)).delete();

        final repaired = await manager.repairCompleted('935');
        expect(repaired, isTrue);

        await _waitForPageStatus(
          harness: harness,
          comicId: '935',
          pageNumber: 1,
          status: 'completed',
        );
        await manager.waitForIdle();

        // The cover must not have been re-fetched: a failed re-fetch would
        // have silently overwritten the already-valid coverLocalPath.
        expect(
          fetcher.requestedUrls.where((url) => url == coverUrl).length,
          1,
        );
        final coverPathAfterRepair =
            await harness.downloadedLibraryRepository.loadCoverLocalPath('935');
        expect(coverPathAfterRepair, coverPathBeforeRepair);
        expect(
          await File(p.join(tempDirectory.path, coverPathAfterRepair!)).exists(),
          isTrue,
        );

        manager.dispose();
      },
    );

    test(
      'repairCompleted throws (does not falsely report success) when the cover '
      'is the only problem and re-downloading it fails',
      () async {
        final comic = sampleComic(id: '936', mediaId: '448');
        final gateway = _SelectiveFailureGateway(<String, Comic>{'936': comic});
        final manager = DownloadManagerModel(
          nhentaiGateway: gateway,
          cdnConfigService: _FakeCdnConfigService(),
          downloadQueueRepository: harness.downloadQueueRepository,
          downloadedLibraryRepository: harness.downloadedLibraryRepository,
          downloadSettingsRepository: DownloadSettingsStore(
            optionsStore: OptionsStore(localDatabase: harness.localDatabase),
          ),
          downloadAssetStore: DownloadAssetStore(
            directoryResolver: () async => tempDirectory,
          ),
          imageCompressionService: FakeImageCompressionService(
            result: Uint8List.fromList(<int>[1, 2, 3, 4]),
          ),
          remoteAssetFetcher: FakeRemoteAssetFetcher(
            responses: <String, Uint8List>{
              'https://i1.nhentai.net/galleries/448/1.jpg': Uint8List.fromList(
                <int>[1],
              ),
              'https://i1.nhentai.net/galleries/448/2.jpg': Uint8List.fromList(
                <int>[2],
              ),
              'https://t1.nhentai.net/galleries/448/cover.jpg':
                  Uint8List.fromList(<int>[3]),
            },
          ),
        );

        await manager.initialize();
        await manager.enqueue(
          const DownloadRequest(comicId: '936', title: 'Sample'),
        );
        await _waitForJobStatus(
          harness: harness,
          comicId: '936',
          status: 'completed',
        );
        await manager.waitForIdle();

        // Break the cover, then make the API fail for any further attempts
        // to repair this comic — pages stay intact the whole time.
        await harness.downloadedLibraryRepository.updateCoverLocalPath(
          '936',
          null,
        );
        gateway.throwingComicIds.add('936');

        await expectLater(
          () => manager.repairCompleted('936'),
          throwsA(anything),
        );

        final coverPathAfterFailedRepair =
            await harness.downloadedLibraryRepository.loadCoverLocalPath('936');
        expect(coverPathAfterFailedRepair, isNull);

        manager.dispose();
      },
    );

    test(
      'repairAllCompleted counts a cover-only repair failure as failed, not repaired',
      () async {
        final healthyComic = sampleComic(id: '937', mediaId: '449');
        final brokenComic = sampleComic(id: '938', mediaId: '450');
        final gateway = _SelectiveFailureGateway(<String, Comic>{
          '937': healthyComic,
          '938': brokenComic,
        });
        final manager = DownloadManagerModel(
          nhentaiGateway: gateway,
          cdnConfigService: _FakeCdnConfigService(),
          downloadQueueRepository: harness.downloadQueueRepository,
          downloadedLibraryRepository: harness.downloadedLibraryRepository,
          downloadSettingsRepository: DownloadSettingsStore(
            optionsStore: OptionsStore(localDatabase: harness.localDatabase),
          ),
          downloadAssetStore: DownloadAssetStore(
            directoryResolver: () async => tempDirectory,
          ),
          imageCompressionService: FakeImageCompressionService(
            result: Uint8List.fromList(<int>[1, 2, 3, 4]),
          ),
          remoteAssetFetcher: FakeRemoteAssetFetcher(
            responses: <String, Uint8List>{
              'https://i1.nhentai.net/galleries/449/1.jpg': Uint8List.fromList(
                <int>[1],
              ),
              'https://i1.nhentai.net/galleries/449/2.jpg': Uint8List.fromList(
                <int>[2],
              ),
              'https://t1.nhentai.net/galleries/449/cover.jpg':
                  Uint8List.fromList(<int>[3]),
              'https://i1.nhentai.net/galleries/450/1.jpg': Uint8List.fromList(
                <int>[4],
              ),
              'https://i1.nhentai.net/galleries/450/2.jpg': Uint8List.fromList(
                <int>[5],
              ),
              'https://t1.nhentai.net/galleries/450/cover.jpg':
                  Uint8List.fromList(<int>[6]),
            },
          ),
        );

        await manager.initialize();
        await manager.enqueue(
          const DownloadRequest(comicId: '937', title: 'Healthy'),
        );
        await _waitForJobStatus(
          harness: harness,
          comicId: '937',
          status: 'completed',
        );
        await manager.waitForIdle();
        await manager.enqueue(
          const DownloadRequest(comicId: '938', title: 'Broken'),
        );
        await _waitForJobStatus(
          harness: harness,
          comicId: '938',
          status: 'completed',
        );
        await manager.waitForIdle();

        // Break only comic 938's cover, and make repairing it fail.
        await harness.downloadedLibraryRepository.updateCoverLocalPath(
          '938',
          null,
        );
        gateway.throwingComicIds.add('938');
        await manager.refresh();

        final result = await manager.repairAllCompleted();

        expect(result.totalCount, 2);
        expect(result.repairedCount, 0);
        expect(result.failedCount, 1);

        manager.dispose();
      },
    );

    test(
      'repairAllCompleted stops early after 3 consecutive failures, leaving '
      'the rest unscanned',
      () async {
        // Download order matters here: loadJobs() sorts by updatedAt desc,
        // so the comic downloaded *first* ends up *last* in the scan order.
        // Download '942' first so it's the one left unscanned once the
        // other three (downloaded after, so scanned first) fail in a row.
        final comics = <String, Comic>{
          '942': sampleComic(id: '942', mediaId: '454'),
          '939': sampleComic(id: '939', mediaId: '451'),
          '940': sampleComic(id: '940', mediaId: '452'),
          '941': sampleComic(id: '941', mediaId: '453'),
        };
        final gateway = _SelectiveFailureGateway(comics);
        final fetcher = FakeRemoteAssetFetcher(
          responses: <String, Uint8List>{
            for (final entry in comics.entries) ...{
              'https://i1.nhentai.net/galleries/${entry.value.mediaId}/1.jpg':
                  Uint8List.fromList(<int>[1]),
              'https://i1.nhentai.net/galleries/${entry.value.mediaId}/2.jpg':
                  Uint8List.fromList(<int>[2]),
              'https://t1.nhentai.net/galleries/${entry.value.mediaId}/cover.jpg':
                  Uint8List.fromList(<int>[3]),
            },
          },
        );
        final manager = DownloadManagerModel(
          nhentaiGateway: gateway,
          cdnConfigService: _FakeCdnConfigService(),
          downloadQueueRepository: harness.downloadQueueRepository,
          downloadedLibraryRepository: harness.downloadedLibraryRepository,
          downloadSettingsRepository: DownloadSettingsStore(
            optionsStore: OptionsStore(localDatabase: harness.localDatabase),
          ),
          downloadAssetStore: DownloadAssetStore(
            directoryResolver: () async => tempDirectory,
          ),
          imageCompressionService: FakeImageCompressionService(
            result: Uint8List.fromList(<int>[1, 2, 3, 4]),
          ),
          remoteAssetFetcher: fetcher,
        );

        await manager.initialize();
        for (final comicId in <String>['942', '939', '940', '941']) {
          await manager.enqueue(DownloadRequest(comicId: comicId, title: comicId));
          await _waitForJobStatus(
            harness: harness,
            comicId: comicId,
            status: 'completed',
          );
          await manager.waitForIdle();
        }

        // Break every cover, but only make 939/940/941 fail on repair —
        // 942 would succeed if the scan ever reached it.
        for (final comicId in comics.keys) {
          await harness.downloadedLibraryRepository.updateCoverLocalPath(
            comicId,
            null,
          );
        }
        gateway.throwingComicIds.addAll(<String>['939', '940', '941']);
        await manager.refresh();

        final result = await manager.repairAllCompleted();

        expect(result.stoppedEarly, isTrue);
        expect(result.failedCount, 3);
        expect(result.repairedCount, 0);
        expect(result.totalCount, 4);

        // '942' was never reached, so its cover is still broken.
        final coverPath942 =
            await harness.downloadedLibraryRepository.loadCoverLocalPath('942');
        expect(coverPath942, isNull);

        manager.dispose();
      },
    );

    test(
      'repairAllCompleted scans every completed download and repairs only the broken cover',
      () async {
        final intactComic = sampleComic(id: '931', mediaId: '442');
        final brokenComic = sampleComic(id: '932', mediaId: '443');
        final gateway = _MultiComicNhentaiGateway(<String, Comic>{
          '931': intactComic,
          '932': brokenComic,
        });
        final manager = DownloadManagerModel(
          nhentaiGateway: gateway,
          cdnConfigService: _FakeCdnConfigService(),
          downloadQueueRepository: harness.downloadQueueRepository,
          downloadedLibraryRepository: harness.downloadedLibraryRepository,
          downloadSettingsRepository: DownloadSettingsStore(
            optionsStore: OptionsStore(localDatabase: harness.localDatabase),
          ),
          downloadAssetStore: DownloadAssetStore(
            directoryResolver: () async => tempDirectory,
          ),
          imageCompressionService: FakeImageCompressionService(
            result: Uint8List.fromList(<int>[1, 2, 3, 4]),
          ),
          remoteAssetFetcher: FakeRemoteAssetFetcher(
            responses: <String, Uint8List>{
              'https://i1.nhentai.net/galleries/442/1.jpg': Uint8List.fromList(
                <int>[1],
              ),
              'https://i1.nhentai.net/galleries/442/2.jpg': Uint8List.fromList(
                <int>[2],
              ),
              'https://t1.nhentai.net/galleries/442/cover.jpg':
                  Uint8List.fromList(<int>[3]),
              'https://i1.nhentai.net/galleries/443/1.jpg': Uint8List.fromList(
                <int>[4],
              ),
              'https://i1.nhentai.net/galleries/443/2.jpg': Uint8List.fromList(
                <int>[5],
              ),
              'https://t1.nhentai.net/galleries/443/cover.jpg':
                  Uint8List.fromList(<int>[6]),
            },
          ),
        );

        await manager.initialize();
        await manager.enqueue(
          const DownloadRequest(comicId: '931', title: 'Intact'),
        );
        await _waitForJobStatus(
          harness: harness,
          comicId: '931',
          status: 'completed',
        );
        await manager.waitForIdle();
        await manager.enqueue(
          const DownloadRequest(comicId: '932', title: 'Broken'),
        );
        await _waitForJobStatus(
          harness: harness,
          comicId: '932',
          status: 'completed',
        );
        await manager.waitForIdle();

        // Break only comic 932's cover.
        await harness.downloadedLibraryRepository.updateCoverLocalPath(
          '932',
          null,
        );
        await manager.refresh();

        final result = await manager.repairAllCompleted();

        expect(result.totalCount, 2);
        expect(result.repairedCount, 1);

        final repairedCoverPath =
            await harness.downloadedLibraryRepository.loadCoverLocalPath('932');
        expect(repairedCoverPath, isNotNull);

        manager.dispose();
      },
    );

    test(
      'repairAllCompleted isolates a failing comic and still processes the rest, reporting progress',
      () async {
        final okComic = sampleComic(id: '933', mediaId: '444');
        final throwingComic = sampleComic(id: '934', mediaId: '445');
        final gateway = _MultiComicNhentaiGateway(<String, Comic>{
          '933': okComic,
          '934': throwingComic,
        });
        final manager = _ThrowingForOneComicManager(
          throwingComicId: '934',
          nhentaiGateway: gateway,
          cdnConfigService: _FakeCdnConfigService(),
          downloadQueueRepository: harness.downloadQueueRepository,
          downloadedLibraryRepository: harness.downloadedLibraryRepository,
          downloadSettingsRepository: DownloadSettingsStore(
            optionsStore: OptionsStore(localDatabase: harness.localDatabase),
          ),
          downloadAssetStore: DownloadAssetStore(
            directoryResolver: () async => tempDirectory,
          ),
          imageCompressionService: FakeImageCompressionService(
            result: Uint8List.fromList(<int>[1, 2, 3, 4]),
          ),
          remoteAssetFetcher: FakeRemoteAssetFetcher(
            responses: <String, Uint8List>{
              'https://i1.nhentai.net/galleries/444/1.jpg': Uint8List.fromList(
                <int>[1],
              ),
              'https://i1.nhentai.net/galleries/444/2.jpg': Uint8List.fromList(
                <int>[2],
              ),
              'https://t1.nhentai.net/galleries/444/cover.jpg':
                  Uint8List.fromList(<int>[3]),
              'https://i1.nhentai.net/galleries/445/1.jpg': Uint8List.fromList(
                <int>[4],
              ),
              'https://i1.nhentai.net/galleries/445/2.jpg': Uint8List.fromList(
                <int>[5],
              ),
              'https://t1.nhentai.net/galleries/445/cover.jpg':
                  Uint8List.fromList(<int>[6]),
            },
          ),
        );

        await manager.initialize();
        await manager.enqueue(
          const DownloadRequest(comicId: '933', title: 'Ok'),
        );
        await _waitForJobStatus(
          harness: harness,
          comicId: '933',
          status: 'completed',
        );
        await manager.waitForIdle();
        await manager.enqueue(
          const DownloadRequest(comicId: '934', title: 'Throws'),
        );
        await _waitForJobStatus(
          harness: harness,
          comicId: '934',
          status: 'completed',
        );
        await manager.waitForIdle();

        // Break both covers so each item attempts a repair.
        await harness.downloadedLibraryRepository.updateCoverLocalPath(
          '933',
          null,
        );
        await harness.downloadedLibraryRepository.updateCoverLocalPath(
          '934',
          null,
        );
        await manager.refresh();

        final progressUpdates = <(int, int)>[];
        final result = await manager.repairAllCompleted(
          onProgress: (processed, total) =>
              progressUpdates.add((processed, total)),
        );

        expect(result.totalCount, 2);
        expect(result.repairedCount, 1);
        expect(result.failedCount, 1);
        expect(progressUpdates, <(int, int)>[(1, 2), (2, 2)]);

        manager.dispose();
      },
    );

    test(
      'enqueueMany skips comics already in the download queue',
      () async {
        final gateway = FakeNhentaiGateway();
        final manager = DownloadManagerModel(
          nhentaiGateway: gateway,
          cdnConfigService: _FakeCdnConfigService(),
          downloadQueueRepository: harness.downloadQueueRepository,
          downloadedLibraryRepository: harness.downloadedLibraryRepository,
          downloadSettingsRepository: DownloadSettingsStore(
            optionsStore: OptionsStore(localDatabase: harness.localDatabase),
          ),
          downloadAssetStore: DownloadAssetStore(
            directoryResolver: () async => tempDirectory,
          ),
          imageCompressionService: FakeImageCompressionService(
            result: Uint8List.fromList(<int>[1, 2, 3, 4]),
          ),
          remoteAssetFetcher: FakeRemoteAssetFetcher(),
        );

        await manager.initialize();
        await manager.enqueue(
          const DownloadRequest(comicId: '960', title: 'Already queued'),
        );
        await manager.refresh();

        final alreadyQueued = ComicCardData.fromComic(
          sampleComic(id: '960', mediaId: '460'),
        );
        final fresh = ComicCardData.fromComic(
          sampleComic(id: '961', mediaId: '461'),
        );

        final result = await manager.enqueueMany(
          <ComicCardData>[alreadyQueued, fresh],
        );

        expect(result.totalCount, 2);
        expect(result.skippedCount, 1);
        expect(result.queuedCount, 1);
        expect(result.failedCount, 0);

        await manager.waitForIdle();
        manager.dispose();
      },
    );

    test(
      'enqueueMany skips the loadComicDetail round trip when the favorite '
      'already has a complete cached page manifest',
      () async {
        final gateway = _DelayedNhentaiGateway(
          delay: const Duration(milliseconds: 300),
        );
        final manager = DownloadManagerModel(
          nhentaiGateway: gateway,
          cdnConfigService: _FakeCdnConfigService(),
          downloadQueueRepository: harness.downloadQueueRepository,
          downloadedLibraryRepository: harness.downloadedLibraryRepository,
          downloadSettingsRepository: DownloadSettingsStore(
            optionsStore: OptionsStore(localDatabase: harness.localDatabase),
          ),
          downloadAssetStore: DownloadAssetStore(
            directoryResolver: () async => tempDirectory,
          ),
          imageCompressionService: FakeImageCompressionService(
            result: Uint8List.fromList(<int>[1, 2, 3, 4]),
          ),
          remoteAssetFetcher: FakeRemoteAssetFetcher(),
        );

        await manager.initialize();

        // Built via ComicCardData.fromComic, so serializedImages already
        // carries the full 2-page manifest from sampleComic() — as if this
        // comic had been opened in the reader before being favorited.
        final completeComic = ComicCardData.fromComic(
          sampleComic(id: '962', mediaId: '462'),
        );

        final stopwatch = Stopwatch()..start();
        final result = await manager.enqueueMany(<ComicCardData>[completeComic]);
        stopwatch.stop();

        expect(result.queuedCount, 1);
        expect(result.skippedCount, 0);
        expect(result.failedCount, 0);
        expect(
          stopwatch.elapsed,
          lessThan(const Duration(milliseconds: 200)),
          reason:
              'A complete local page manifest should skip loadComicDetail '
              'entirely, so this should resolve well under the fake '
              'gateway\'s 300ms delay.',
        );

        final job = await harness.downloadQueueRepository.loadJob('962');
        expect(job, isNotNull);
        expect(job!.totalPages, 2);

        await manager.waitForIdle();
        manager.dispose();
      },
    );

    test(
      'enqueueMany calls loadComicDetail when the favorite has no cached '
      'page manifest (e.g. synced from the remote favorites list)',
      () async {
        final gateway = FakeNhentaiGateway();
        final manager = DownloadManagerModel(
          nhentaiGateway: gateway,
          cdnConfigService: _FakeCdnConfigService(),
          downloadQueueRepository: harness.downloadQueueRepository,
          downloadedLibraryRepository: harness.downloadedLibraryRepository,
          downloadSettingsRepository: DownloadSettingsStore(
            optionsStore: OptionsStore(localDatabase: harness.localDatabase),
          ),
          downloadAssetStore: DownloadAssetStore(
            directoryResolver: () async => tempDirectory,
          ),
          imageCompressionService: FakeImageCompressionService(
            result: Uint8List.fromList(<int>[1, 2, 3, 4]),
          ),
          remoteAssetFetcher: FakeRemoteAssetFetcher(),
        );

        await manager.initialize();

        final thumbnailOnlyComic = _thumbnailOnlyCard(id: '963', mediaId: '463');
        final result = await manager.enqueueMany(<ComicCardData>[thumbnailOnlyComic]);

        expect(result.queuedCount, 1);
        expect(gateway.loadedComicDetailIds, contains('963'));

        await manager.waitForIdle();
        manager.dispose();
      },
    );

    test(
      'enqueueMany stops early after 3 consecutive failures, leaving the '
      'rest unprocessed',
      () async {
        final comics = <String, Comic>{
          '970': sampleComic(id: '970', mediaId: '470'),
          '971': sampleComic(id: '971', mediaId: '471'),
          '972': sampleComic(id: '972', mediaId: '472'),
          '973': sampleComic(id: '973', mediaId: '473'),
        };
        final gateway = _SelectiveFailureGateway(comics);
        gateway.throwingComicIds.addAll(<String>['970', '971', '972']);

        final manager = DownloadManagerModel(
          nhentaiGateway: gateway,
          cdnConfigService: _FakeCdnConfigService(),
          downloadQueueRepository: harness.downloadQueueRepository,
          downloadedLibraryRepository: harness.downloadedLibraryRepository,
          downloadSettingsRepository: DownloadSettingsStore(
            optionsStore: OptionsStore(localDatabase: harness.localDatabase),
          ),
          downloadAssetStore: DownloadAssetStore(
            directoryResolver: () async => tempDirectory,
          ),
          imageCompressionService: FakeImageCompressionService(
            result: Uint8List.fromList(<int>[1, 2, 3, 4]),
          ),
          remoteAssetFetcher: FakeRemoteAssetFetcher(),
        );

        await manager.initialize();

        final progressUpdates = <(int, int)>[];
        final result = await manager.enqueueMany(
          <ComicCardData>[
            for (final entry in comics.entries)
              _thumbnailOnlyCard(id: entry.key, mediaId: entry.value.mediaId),
          ],
          onProgress: (processed, total) =>
              progressUpdates.add((processed, total)),
        );

        expect(result.totalCount, 4);
        expect(result.failedCount, 3);
        expect(result.queuedCount, 0);
        expect(result.stoppedEarly, isTrue);
        expect(progressUpdates, <(int, int)>[(1, 4), (2, 4), (3, 4)]);
        expect(gateway.loadedComicDetailIds, isNot(contains('973')));

        manager.dispose();
      },
    );

    test(
      'enqueueMany retries after a 429 using the Retry-After header, then '
      'succeeds',
      () async {
        final gateway = _RateLimitedOnceGateway(<String, Comic>{
          '980': sampleComic(id: '980', mediaId: '480'),
        });
        final manager = DownloadManagerModel(
          nhentaiGateway: gateway,
          cdnConfigService: _FakeCdnConfigService(),
          downloadQueueRepository: harness.downloadQueueRepository,
          downloadedLibraryRepository: harness.downloadedLibraryRepository,
          downloadSettingsRepository: DownloadSettingsStore(
            optionsStore: OptionsStore(localDatabase: harness.localDatabase),
          ),
          downloadAssetStore: DownloadAssetStore(
            directoryResolver: () async => tempDirectory,
          ),
          imageCompressionService: FakeImageCompressionService(
            result: Uint8List.fromList(<int>[1, 2, 3, 4]),
          ),
          remoteAssetFetcher: FakeRemoteAssetFetcher(),
        );

        await manager.initialize();

        final comic = _thumbnailOnlyCard(id: '980', mediaId: '480');
        final result = await manager.enqueueMany(<ComicCardData>[comic]);

        expect(result.queuedCount, 1);
        expect(result.failedCount, 0);
        // The first call hits the simulated 429; the retry after the
        // Retry-After delay succeeds.
        expect(
          gateway.loadedComicDetailIds.where((id) => id == '980').length,
          2,
        );

        await manager.waitForIdle();
        manager.dispose();
      },
    );
  });
}

/// Returns a different [Comic] per comicId, unlike [FakeNhentaiGateway] which
/// always returns the same fixed `detailComic` regardless of the requested id.
class _MultiComicNhentaiGateway extends FakeNhentaiGateway {
  _MultiComicNhentaiGateway(this._comics);

  final Map<String, Comic> _comics;

  @override
  Future<({Comic comic, Map<String, String>? headers})> loadComicDetail(
    String comicId,
  ) async {
    loadedComicDetailIds.add(comicId);
    return (comic: _comics[comicId] ?? sampleComic(id: comicId), headers: null);
  }
}

/// Delays every `loadComicDetail` response by [delay] before succeeding —
/// used to prove `enqueueMany` never awaits the gateway at all for a
/// favorite whose cached page manifest is already complete (see
/// .codex/phases/P57-favorites-multiselect-download-throttle.md).
class _DelayedNhentaiGateway extends FakeNhentaiGateway {
  _DelayedNhentaiGateway({required this.delay});

  final Duration delay;

  @override
  Future<({Comic comic, Map<String, String>? headers})> loadComicDetail(
    String comicId,
  ) async {
    await Future<void>.delayed(delay);
    return super.loadComicDetail(comicId);
  }
}

/// Throws a 429 with a `Retry-After` header the first time each comicId is
/// requested, then succeeds on the following attempt.
class _RateLimitedOnceGateway extends FakeNhentaiGateway {
  _RateLimitedOnceGateway(this._comics);

  final Map<String, Comic> _comics;
  final Set<String> _rateLimitedOnceIds = <String>{};

  @override
  Future<({Comic comic, Map<String, String>? headers})> loadComicDetail(
    String comicId,
  ) async {
    loadedComicDetailIds.add(comicId);
    if (_rateLimitedOnceIds.add(comicId)) {
      throw DioException(
        requestOptions: RequestOptions(path: '/'),
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/'),
          statusCode: 429,
          headers: Headers.fromMap(<String, List<String>>{
            'retry-after': <String>['1'],
          }),
        ),
      );
    }
    return (comic: _comics[comicId] ?? sampleComic(id: comicId), headers: null);
  }
}

/// Throws for [throwingComicId] when `repairCompleted` is called, to exercise
/// the per-item error isolation in `repairAllCompleted`.
class _ThrowingForOneComicManager extends DownloadManagerModel {
  _ThrowingForOneComicManager({
    required this.throwingComicId,
    required super.nhentaiGateway,
    required super.cdnConfigService,
    required super.downloadQueueRepository,
    required super.downloadedLibraryRepository,
    required super.downloadSettingsRepository,
    required super.downloadAssetStore,
    required super.imageCompressionService,
    required super.remoteAssetFetcher,
  });

  final String throwingComicId;

  @override
  Future<bool> repairCompleted(String comicId) async {
    if (comicId == throwingComicId) {
      throw Exception('simulated repair failure');
    }
    return super.repairCompleted(comicId);
  }
}

/// Like [_MultiComicNhentaiGateway], but `loadComicDetail` throws for any
/// comicId added to [throwingComicIds] — used to simulate a repair attempt
/// failing for a specific, already-downloaded comic without affecting its
/// (earlier) successful initial download.
class _SelectiveFailureGateway extends FakeNhentaiGateway {
  _SelectiveFailureGateway(this._comics);

  final Map<String, Comic> _comics;
  final Set<String> throwingComicIds = <String>{};

  @override
  Future<({Comic comic, Map<String, String>? headers})> loadComicDetail(
    String comicId,
  ) async {
    loadedComicDetailIds.add(comicId);
    if (throwingComicIds.contains(comicId)) {
      throw Exception('simulated API failure for $comicId');
    }
    return (comic: _comics[comicId] ?? sampleComic(id: comicId), headers: null);
  }
}

Comic _comicWithPageExtension({
  required String id,
  required String mediaId,
  required String typeCode,
  required String extension,
}) {
  final base = sampleComic(id: id, mediaId: mediaId);
  return base.copyWith(
    images: base.images.copyWith(
      pages: <ComicPageImage>[
        ComicPageImage(t: typeCode, w: 1200, h: 1800, path: 'galleries/$mediaId/1.$extension'),
        ComicPageImage(t: typeCode, w: 1200, h: 1800, path: 'galleries/$mediaId/2.$extension'),
      ],
      cover: ComicPageImage(t: typeCode, w: 350, h: 500, path: 'galleries/$mediaId/cover.$extension'),
    ),
  );
}

/// A favorite whose cached data only carries the thumbnail — matching what
/// `RemoteFavoriteGateway`'s `_mapListComic` produces when favorites are
/// synced in bulk from the remote list, which never includes the per-page
/// manifest. `enqueueMany` must call `loadComicDetail` for cards like this.
ComicCardData _thumbnailOnlyCard({
  required String id,
  required String mediaId,
  int pages = 2,
}) {
  return ComicCardData(
    id: id,
    mediaId: mediaId,
    title: 'Card $id',
    pages: pages,
    serializedImages: jsonEncode(
      ComicImages(
        thumbnail: ComicPageImage(
          t: 'j',
          w: 350,
          h: 500,
          path: 'galleries/$mediaId/thumb.jpg',
        ),
      ).toJson(),
    ),
    thumbnailUrl: 'https://t1.nhentai.net/galleries/$mediaId/thumb.jpg',
    thumbnailWidth: 350,
    thumbnailHeight: 500,
  );
}

class _FakeCdnConfigService extends NhentaiCdnConfigService {
  @override
  List<String> get imageHosts => const <String>['i1.nhentai.net'];

  @override
  Future<Never> load() async {
    throw StateError('No remote config call in tests');
  }
}

Future<void> _waitForJobStatus({
  required SqliteTestHarness harness,
  required String comicId,
  required String status,
}) async {
  for (int attempt = 0; attempt < 100; attempt++) {
    final job = await harness.downloadQueueRepository.loadJob(comicId);
    if (job != null && job.status.storageValue == status) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  fail('Timed out waiting for job $comicId to reach status $status');
}

Future<void> _waitForPageStatus({
  required SqliteTestHarness harness,
  required String comicId,
  required int pageNumber,
  required String status,
}) async {
  for (int attempt = 0; attempt < 100; attempt++) {
    final page = (await harness.downloadQueueRepository.loadPages(comicId))
        .firstWhere((candidate) => candidate.pageNumber == pageNumber);
    if (page.status.storageValue == status) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  fail(
    'Timed out waiting for job $comicId page $pageNumber to reach status $status',
  );
}

Comic _threePageComic({required String id, required String mediaId}) {
  return Comic(
    id: id,
    mediaId: mediaId,
    title: sampleComic(id: id, mediaId: mediaId).title,
    images: ComicImages(
      pages: <ComicPageImage>[
        ComicPageImage(
          t: 'j',
          w: 1200,
          h: 1800,
          path: 'galleries/$mediaId/1.jpg',
        ),
        ComicPageImage(
          t: 'j',
          w: 1200,
          h: 1800,
          path: 'galleries/$mediaId/2.jpg',
        ),
        ComicPageImage(
          t: 'j',
          w: 1200,
          h: 1800,
          path: 'galleries/$mediaId/3.jpg',
        ),
      ],
      cover: ComicPageImage(
        t: 'j',
        w: 350,
        h: 500,
        path: 'galleries/$mediaId/cover.jpg',
      ),
      thumbnail: ComicPageImage(
        t: 'w',
        w: 350,
        h: 500,
        path: 'galleries/$mediaId/thumb.webp',
      ),
    ),
    scanlator: null,
    uploadDate: 0,
    tags: sampleComic(id: id, mediaId: mediaId).tags,
    numPages: 3,
    numFavorites: 1,
  );
}
