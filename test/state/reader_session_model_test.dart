import 'dart:io';

import 'package:concept_nhv/application/reader/load_comic_detail_use_case.dart';
import 'package:concept_nhv/application/reader/load_offline_comic_use_case.dart';
import 'package:concept_nhv/application/reader/open_comic_use_case.dart';
import 'package:concept_nhv/application/library/load_collection_comics_use_case.dart';
import 'package:concept_nhv/models/collection_type.dart';
import 'package:concept_nhv/models/comic_card_data.dart';
import 'package:concept_nhv/models/comic.dart';
import 'package:concept_nhv/models/stored_comic.dart';
import 'package:concept_nhv/services/download_asset_store.dart';
import 'package:concept_nhv/state/reader_session_model.dart';
import 'package:concept_nhv/storage/options_store.dart';
import 'package:concept_nhv/storage/reader_progress_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../test_support/fakes/fake_nhentai_gateway.dart';
import '../test_support/fakes/fake_reader_settings_repository.dart';
import '../test_support/fixtures/sample_comic.dart';
import '../test_support/storage/sqlite_test_harness.dart';

void main() {
  late SqliteTestHarness harness;
  late Directory tempDirectory;
  late FakeNhentaiGateway gateway;
  late ReaderSessionModel model;

  /// Records a completed download for [comicId], the way the app does.
  Future<void> seedCompletedDownload(String comicId) async {
    final comic = sampleComic(id: comicId, mediaId: '5$comicId');
    await harness.downloadedLibraryRepository.saveDownloadedComic(
      comic: comic,
      rootDirectoryPath: comicId,
      coverLocalPath: p.join(comicId, 'cover.webp'),
      downloadedAt: DateTime(2026, 5, 1),
    );
    await harness.downloadQueueRepository.upsertJobManifest(
      comic: comic,
      title: 'Sample Comic',
    );
    await harness.downloadQueueRepository.markJobDownloading(comicId);
    await harness.downloadQueueRepository.markPageCompleted(
      comicId: comicId,
      pageNumber: 1,
      sourceServer: 'i1.nhentai.net',
      localPath: p.join(comicId, 'pages', '1.jpg'),
      storedFormat: 'jpg',
      byteSize: 100,
    );
  }

  setUp(() async {
    harness = SqliteTestHarness();
    await harness.initialize();
    tempDirectory = await Directory.systemTemp.createTemp(
      'reader_session_model_test',
    );
    gateway = FakeNhentaiGateway(detailComic: sampleComic(id: '77'));

    model = ReaderSessionModel(
      loadComicDetailUseCase: LoadComicDetailUseCase(nhentaiGateway: gateway),
      loadOfflineComicUseCase: LoadOfflineComicUseCase(
        downloadQueueRepository: harness.downloadQueueRepository,
        downloadedLibraryRepository: harness.downloadedLibraryRepository,
        downloadAssetStore: DownloadAssetStore(
          directoryResolver: () async => tempDirectory,
        ),
      ),
      openComicUseCase: OpenComicUseCase(
        comicRepository: harness.comicRepository,
        collectionRepository: harness.collectionRepository,
      ),
      readerProgressRepository: ReaderProgressStore(
        optionsStore: OptionsStore(localDatabase: harness.localDatabase),
      ),
      readerSettingsRepository: FakeReaderSettingsRepository(),
      downloadedLibraryRepository: harness.downloadedLibraryRepository,
    );
  });

  tearDown(() async {
    model.dispose();
    await harness.dispose();
    await tempDirectory.delete(recursive: true);
  });

  group('local first', () {
    test('a downloaded comic opens without touching the network', () async {
      await seedCompletedDownload('803');

      await model.open(comicId: '803');

      expect(model.loadState, ReaderLoadState.ready);
      expect(model.currentComic?.id, '803');
      expect(
        gateway.loadedComicDetailIds,
        isEmpty,
        reason: 'a comic already on the device must cost no request',
      );
    });

    test('a comic that is not downloaded still falls through to the API', () async {
      await model.open(comicId: '77');

      expect(model.loadState, ReaderLoadState.ready);
      expect(gateway.loadedComicDetailIds, <String>['77']);
    });

    test('a downloaded comic opens with no connection at all', () async {
      await seedCompletedDownload('803');
      final offlineModel = ReaderSessionModel(
        loadComicDetailUseCase: LoadComicDetailUseCase(
          nhentaiGateway: _ThrowingGateway(),
        ),
        loadOfflineComicUseCase: model.loadOfflineComicUseCase,
        openComicUseCase: model.openComicUseCase,
        readerProgressRepository: model.readerProgressRepository,
        readerSettingsRepository: model.readerSettingsRepository,
        downloadedLibraryRepository: model.downloadedLibraryRepository,
      );
      addTearDown(offlineModel.dispose);

      await offlineModel.open(comicId: '803');

      expect(offlineModel.loadState, ReaderLoadState.ready);
    });

    test('opening locally does not strip the cover off the stored comic', () async {
      // The hazard: a comic rebuilt from a download has no cover and no
      // thumbnail. Storing it over the API version would leave the Favorites
      // and History cards with no image, permanently.
      await seedCompletedDownload('803');
      final fromApi = sampleComic(id: '803', mediaId: '5803');
      await harness.comicRepository.upsertComic(StoredComic.fromComic(fromApi));

      await model.open(comicId: '803');

      final history = await LoadCollectionComicsUseCase(
        collectionRepository: harness.collectionRepository,
      ).execute(CollectionType.history);
      final card = history.firstWhere((c) => c.id == '803');

      expect(
        card.thumbnailUrl,
        ComicCardData.fromComic(fromApi).thumbnailUrl,
        reason: 'the card must keep the thumbnail the API gave it',
      );
    });

    test('a never-seen comic is still stored, so History can show it', () async {
      // The other half of the same rule: skipping the write entirely would
      // leave History pointing at an id with no comic behind it.
      await seedCompletedDownload('803');

      await model.open(comicId: '803');

      final history = await LoadCollectionComicsUseCase(
        collectionRepository: harness.collectionRepository,
      ).execute(CollectionType.history);

      expect(history.map((c) => c.id), contains('803'));
    });

    test('offline mode refuses rather than falling through to the API', () async {
      // The Downloads tab promises an on-device library; quietly pulling a
      // whole comic over a metered connection from there would be a surprise.
      await model.open(comicId: '77', offline: true);

      expect(model.failure, ReaderLoadFailure.notDownloaded);
      expect(gateway.loadedComicDetailIds, isEmpty);
    });
  });

  test('loadComicDetail stores comic and history entry through use cases', () async {
    await model.loadComicDetail('77');

    final historyIds = await harness.collectionRepository.loadCollectedComicIds(
      CollectionType.history,
    );

    expect(model.currentComic?.id, '77');
    expect(historyIds, <String>{'77'});
  });

  test('numFavorites reflects loaded comic favorites count', () async {
    expect(model.numFavorites, isNull);

    await model.loadComicDetail('77');

    expect(model.numFavorites, sampleComic(id: '77').numFavorites);
  });

  group('open', () {
    test('reaches ready and exposes the comic', () async {
      await model.open(comicId: '77', offline: false);

      expect(model.loadState, ReaderLoadState.ready);
      expect(model.isReady, isTrue);
      expect(model.currentComic?.id, '77');
      expect(model.failure, isNull);
    });

    test('reports a failed load instead of throwing', () async {
      // The screen has nowhere to hand an exception; an unhandled one would
      // leave it spinning forever with no way out.
      final failing = ReaderSessionModel(
        loadComicDetailUseCase: LoadComicDetailUseCase(
          nhentaiGateway: _ThrowingGateway(),
        ),
        loadOfflineComicUseCase: model.loadOfflineComicUseCase,
        openComicUseCase: model.openComicUseCase,
        readerProgressRepository: model.readerProgressRepository,
        readerSettingsRepository: model.readerSettingsRepository,
        downloadedLibraryRepository: model.downloadedLibraryRepository,
      );
      addTearDown(failing.dispose);

      await failing.open(comicId: '77', offline: false);

      expect(failing.loadState, ReaderLoadState.failed);
      expect(failing.failure, ReaderLoadFailure.loadFailed);
      expect(failing.currentComic, isNull);
    });

    test('reports notDownloaded when opened offline without a download', () async {
      await model.open(comicId: '9999', offline: true);

      expect(model.loadState, ReaderLoadState.failed);
      expect(
        model.failure,
        ReaderLoadFailure.notDownloaded,
        reason: 'a missing download must not look like a network error',
      );
    });

    test('a retry after a failure can still succeed', () async {
      await model.open(comicId: '9999', offline: true);
      expect(model.loadState, ReaderLoadState.failed);

      await model.open(comicId: '77', offline: false);

      expect(model.loadState, ReaderLoadState.ready);
      expect(model.failure, isNull);
    });
  });

  test('loadLastSeenOffset returns stored progress', () async {
    await model.readerProgressRepository.saveLastSeenOffset('88', 123.5);

    final offset = await model.loadLastSeenOffset('88');

    expect(offset, 123.5);
  });
}

/// Fails every detail request, standing in for no network or an unknown id.
class _ThrowingGateway extends FakeNhentaiGateway {
  @override
  Future<Comic> loadComicDetail(String comicId) async {
    throw Exception('simulated failure');
  }
}
