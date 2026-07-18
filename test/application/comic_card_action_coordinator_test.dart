import 'package:concept_nhv/application/favorites/clear_favorite_auth_use_case.dart';
import 'package:concept_nhv/application/favorites/initialize_favorites_use_case.dart';
import 'package:concept_nhv/application/favorites/save_api_key_use_case.dart';
import 'package:concept_nhv/application/favorites/sync_remote_favorites_use_case.dart';
import 'package:concept_nhv/application/favorites/toggle_favorite_use_case.dart';
import 'package:concept_nhv/application/feed/load_collection_summaries_use_case.dart';
import 'package:concept_nhv/application/feed/search_comics_use_case.dart';
import 'package:concept_nhv/application/library/comic_card_action_coordinator.dart';
import 'package:concept_nhv/application/library/remove_comic_from_collection_use_case.dart';
import 'package:concept_nhv/application/library/save_comic_to_collection_use_case.dart';
import 'package:concept_nhv/application/reader/load_comic_detail_use_case.dart';
import 'package:concept_nhv/application/reader/load_offline_comic_use_case.dart';
import 'package:concept_nhv/application/reader/open_comic_use_case.dart';
import 'package:concept_nhv/application/tags/load_comic_meta_use_case.dart';
import 'package:concept_nhv/models/collection_type.dart';
import 'package:concept_nhv/models/comic_card_data.dart';
import 'package:concept_nhv/models/download_job_snapshot.dart';
import 'package:concept_nhv/models/download_request.dart';
import 'package:concept_nhv/services/download_asset_store.dart';
import 'package:concept_nhv/services/nhentai_cdn_config_service.dart';
import 'package:concept_nhv/services/search_query_builder.dart';
import 'package:concept_nhv/state/comic_feed_model.dart';
import 'package:concept_nhv/state/comic_reader_model.dart';
import 'package:concept_nhv/state/download_manager_model.dart';
import 'package:concept_nhv/state/favorite_sync_model.dart';
import 'package:concept_nhv/storage/download_settings_store.dart';
import 'package:concept_nhv/storage/options_store.dart';
import 'package:concept_nhv/storage/reader_progress_store.dart';
import '../test_support/fakes/fake_reader_settings_repository.dart';
import '../test_support/fakes/fake_image_compression_service.dart';
import 'package:concept_nhv/storage/nhentai_api_key_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_support/fakes/fake_blocked_tags_repository.dart';
import '../test_support/fakes/fake_nhentai_auth_service.dart';
import '../test_support/fakes/fake_nhentai_gateway.dart';
import '../test_support/fakes/fake_remote_asset_fetcher.dart';
import '../test_support/fakes/fake_remote_favorite_gateway.dart';
import '../test_support/fakes/memory_secure_store.dart';
import '../test_support/fixtures/sample_comic.dart';
import '../test_support/storage/sqlite_test_harness.dart';

void main() {
  group('ComicCardActionCoordinator', () {
    late SqliteTestHarness harness;
    late FavoriteSyncModel favoriteSyncModel;
    late FakeRemoteFavoriteGateway remoteFavoriteGateway;
    late FakeNhentaiAuthService authService;
    late ComicFeedModel feedModel;
    late ComicReaderModel readerModel;
    late _FakeDownloadManagerModel downloadManagerModel;
    late ComicCardActionCoordinator coordinator;

    setUp(() async {
      harness = SqliteTestHarness();
      await harness.initialize();
      final apiKeyStore = NhentaiApiKeyStore(
        secureStore: MemorySecureKeyValueStore(),
      );
      authService = FakeNhentaiAuthService(apiKeyStore);
      remoteFavoriteGateway = FakeRemoteFavoriteGateway();
      favoriteSyncModel = FavoriteSyncModel(
        initializeFavoritesUseCase: InitializeFavoritesUseCase(
          collectionRepository: harness.collectionRepository,
          authService: authService,
        ),
        saveApiKeyUseCase: SaveApiKeyUseCase(authService: authService),
        clearFavoriteAuthUseCase: ClearFavoriteAuthUseCase(
          authService: authService,
        ),
        syncRemoteFavoritesUseCase: SyncRemoteFavoritesUseCase(
          collectionRepository: harness.collectionRepository,
          remoteFavoriteGateway: remoteFavoriteGateway,
        ),
        toggleFavoriteUseCase: ToggleFavoriteUseCase(
          collectionRepository: harness.collectionRepository,
          remoteFavoriteGateway: remoteFavoriteGateway,
          authService: authService,
        ),
      );
      feedModel = ComicFeedModel(
        searchComicsUseCase: SearchComicsUseCase(
          nhentaiGateway: FakeNhentaiGateway(),
          searchQueryBuilder: const SearchQueryBuilder(),
        ),
        loadCollectionSummariesUseCase: LoadCollectionSummariesUseCase(
          collectionRepository: harness.collectionRepository,
        ),
        blockedTagsRepository: FakeBlockedTagsRepository(),
      );
      readerModel = ComicReaderModel(
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
      downloadManagerModel = _FakeDownloadManagerModel(harness: harness);
      coordinator = ComicCardActionCoordinator(
        saveComicToCollectionUseCase: SaveComicToCollectionUseCase(
          comicRepository: harness.comicRepository,
          collectionRepository: harness.collectionRepository,
        ),
        removeComicFromCollectionUseCase: RemoveComicFromCollectionUseCase(
          collectionRepository: harness.collectionRepository,
        ),
        favoriteSyncModel: favoriteSyncModel,
        feedModel: feedModel,
        readerModel: readerModel,
        downloadManagerModel: downloadManagerModel,
        loadComicMetaUseCase: LoadComicMetaUseCase(
          nhentaiGateway: FakeNhentaiGateway(),
        ),
      );
    });

    tearDown(() async {
      readerModel.dispose();
      favoriteSyncModel.dispose();
      feedModel.dispose();
      await harness.dispose();
    });

    test('saveToCollection stores membership and returns feedback message', () async {
      final comic = ComicCardData.fromComic(sampleComic(id: '55'));

      final result = await coordinator.saveToCollection(
        comic: comic,
        targetCollection: CollectionType.next,
      );

      expect(result.success, isTrue);
      expect(result.message, 'Added comic to Next');
      expect(feedModel.collectionSummariesFuture, isNotNull);
      expect(
        await harness.collectionRepository.loadCollectedComicIds(
          CollectionType.next,
        ),
        <String>{'55'},
      );
    });

    test('toggleFavorite returns collection refresh signal for favorite collection cards', () async {
      authService.isValid = true;
      final comic = ComicCardData.fromComic(sampleComic(id: '77'));

      final result = await coordinator.toggleFavorite(
        comic: comic,
        collectionType: CollectionType.favorite,
      );

      expect(result.success, isTrue);
      expect(result.shouldRefreshCollection, isTrue);
      expect(result.message, 'Added comic to Website Favorite');
      expect(feedModel.collectionSummariesFuture, isNotNull);
    });

    test('enqueueDownload starts a new download job and returns feedback', () async {
      final comic = ComicCardData.fromComic(sampleComic(id: '88'));

      final result = await coordinator.enqueueDownload(comic);

      expect(result.success, isTrue);
      expect(result.message, 'Added to Downloads');
      expect(result.triggerHaptic, isTrue);
      expect(downloadManagerModel.enqueuedRequests, hasLength(1));
      expect(downloadManagerModel.enqueuedRequests.single.comicId, '88');
      expect(
        downloadManagerModel.enqueuedRequests.single.title,
        'Sample Comic',
      );
    });
  });
}

class _FakeDownloadManagerModel extends DownloadManagerModel {
  _FakeDownloadManagerModel({required SqliteTestHarness harness})
      : super(
          nhentaiGateway: FakeNhentaiGateway(),
          cdnConfigService: NhentaiCdnConfigService(),
          downloadQueueRepository: harness.downloadQueueRepository,
          downloadedLibraryRepository: harness.downloadedLibraryRepository,
          downloadSettingsRepository: DownloadSettingsStore(
            optionsStore: OptionsStore(localDatabase: harness.localDatabase),
          ),
          downloadAssetStore: DownloadAssetStore(
            directoryResolver: () async => throw UnimplementedError(),
          ),
          imageCompressionService: FakeImageCompressionService(),
          remoteAssetFetcher: FakeRemoteAssetFetcher(),
        );

  final List<DownloadRequest> enqueuedRequests = <DownloadRequest>[];

  @override
  Future<void> enqueue(DownloadRequest request) async {
    enqueuedRequests.add(request);
  }

  @override
  DownloadJobSnapshot? jobForComic(String comicId) => null;

  @override
  bool isMutating(String comicId) => false;
}
