import 'package:concept_nhv/application/reader/load_comic_detail_use_case.dart';
import 'package:concept_nhv/application/reader/load_offline_comic_use_case.dart';
import 'package:concept_nhv/application/reader/open_comic_use_case.dart';
import 'package:concept_nhv/models/collection_type.dart';
import 'package:concept_nhv/services/download_asset_store.dart';
import 'package:concept_nhv/state/comic_reader_model.dart';
import 'package:concept_nhv/storage/options_store.dart';
import 'package:concept_nhv/storage/reader_progress_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_support/fakes/fake_nhentai_gateway.dart';
import '../test_support/fakes/fake_reader_settings_repository.dart';
import '../test_support/fixtures/sample_comic.dart';
import '../test_support/storage/sqlite_test_harness.dart';

void main() {
  late SqliteTestHarness harness;
  late ComicReaderModel model;

  setUp(() async {
    harness = SqliteTestHarness();
    await harness.initialize();

    model = ComicReaderModel(
      loadComicDetailUseCase: LoadComicDetailUseCase(
        nhentaiGateway: FakeNhentaiGateway(detailComic: sampleComic(id: '77')),
      ),
      loadOfflineComicUseCase: LoadOfflineComicUseCase(
        downloadQueueRepository: harness.downloadQueueRepository,
        downloadedLibraryRepository: harness.downloadedLibraryRepository,
        downloadAssetStore: DownloadAssetStore(
          directoryResolver: () async => throw UnimplementedError(),
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

  test('numFavorites is null after comic is cleared', () async {
    await model.loadComicDetail('77');
    expect(model.numFavorites, isNotNull);

    model.clearComic();

    expect(model.numFavorites, isNull);
  });

  test('loadLastSeenOffset returns stored progress', () async {
    await model.readerProgressRepository.saveLastSeenOffset('88', 123.5);

    final offset = await model.loadLastSeenOffset('88');

    expect(offset, 123.5);
  });
}
