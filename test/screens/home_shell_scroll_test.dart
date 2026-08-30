import 'package:concept_nhv/application/favorites/clear_favorite_auth_use_case.dart';
import 'package:concept_nhv/application/favorites/initialize_favorites_use_case.dart';
import 'package:concept_nhv/application/favorites/save_api_key_use_case.dart';
import 'package:concept_nhv/application/favorites/sync_remote_favorites_use_case.dart';
import 'package:concept_nhv/application/favorites/toggle_favorite_use_case.dart';
import 'package:concept_nhv/application/feed/load_collection_summaries_use_case.dart';
import 'package:concept_nhv/application/feed/search_comics_use_case.dart';
import 'package:concept_nhv/application/home/home_shell_controller.dart';
import 'package:concept_nhv/application/library/comic_card_action_coordinator.dart';
import 'package:concept_nhv/application/library/remove_comic_from_collection_use_case.dart';
import 'package:concept_nhv/application/library/save_comic_to_collection_use_case.dart';
import 'package:concept_nhv/application/reader/reader_launcher.dart';
import 'package:concept_nhv/application/tags/load_comic_meta_use_case.dart';
import 'package:concept_nhv/models/comic.dart';
import 'package:concept_nhv/models/comic_search_response.dart';
import 'package:concept_nhv/screens/home_shell.dart';
import 'package:concept_nhv/services/download_asset_store.dart';
import 'package:concept_nhv/services/local_tag_catalog_service.dart';
import 'package:concept_nhv/services/nhentai_cdn_config_service.dart';
import 'package:concept_nhv/services/search_query_builder.dart';
import 'package:concept_nhv/services/tag_display_service.dart';
import 'package:concept_nhv/services/tag_search_query_builder.dart';
import 'package:concept_nhv/state/blocked_tags_model.dart';
import 'package:concept_nhv/state/comic_feed_model.dart';
import 'package:concept_nhv/state/download_manager_model.dart';
import 'package:concept_nhv/state/favorite_sync_model.dart';
import 'package:concept_nhv/state/home_ui_model.dart';
import 'package:concept_nhv/state/tag_catalog_browser_model.dart';
import 'package:concept_nhv/storage/download_settings_store.dart';
import 'package:concept_nhv/storage/nhentai_api_key_store.dart';
import 'package:concept_nhv/storage/options_store.dart';
import 'package:concept_nhv/storage/search_history_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../test_support/fakes/fake_blocked_tags_repository.dart';
import '../test_support/fakes/fake_image_compression_service.dart';
import '../test_support/fakes/fake_nhentai_auth_service.dart';
import '../test_support/fakes/fake_nhentai_gateway.dart';
import '../test_support/fakes/fake_remote_asset_fetcher.dart';
import '../test_support/fakes/fake_remote_favorite_gateway.dart';
import '../test_support/fakes/memory_secure_store.dart';
import '../test_support/fixtures/sample_comic.dart';
import '../test_support/storage/sqlite_test_harness.dart';

/// The home feed and the Downloads tab used to share one `ScrollController`,
/// so they shared one scroll offset outright. These tests drive the real
/// [HomeShell] because the coupling only exists once the three tabs sit behind
/// a single `CustomScrollView` — nothing smaller reproduces it.
void main() {
  group('HomeShell scrolling', () {
    late SqliteTestHarness harness;
    late HomeUiModel homeUiModel;
    late ComicFeedModel feedModel;
    late DownloadManagerModel downloadManagerModel;
    late FavoriteSyncModel favoriteSyncModel;
    late FakeNhentaiGateway gateway;

    setUp(() async {
      harness = SqliteTestHarness();
      await harness.initialize();

      gateway = FakeNhentaiGateway(
        searchResponse: ComicSearchResponse(
          result: <Comic>[
            for (var i = 0; i < 40; i++)
              sampleComic(id: 'comic-$i', mediaId: '$i'),
          ],
          numPages: 3,
          perPage: 25,
        ),
      );
      feedModel = ComicFeedModel(
        searchComicsUseCase: SearchComicsUseCase(
          nhentaiGateway: gateway,
          searchQueryBuilder: const SearchQueryBuilder(),
        ),
        loadCollectionSummariesUseCase: LoadCollectionSummariesUseCase(
          collectionRepository: harness.collectionRepository,
        ),
        blockedTagsRepository: FakeBlockedTagsRepository(),
      );
      await feedModel.loadHomeFeed();

      homeUiModel = HomeUiModel();
      downloadManagerModel = DownloadManagerModel(
        nhentaiGateway: gateway,
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

      final apiKeyStore = NhentaiApiKeyStore(
        secureStore: MemorySecureKeyValueStore(),
      );
      final authService = FakeNhentaiAuthService(apiKeyStore);
      final remoteFavoriteGateway = FakeRemoteFavoriteGateway();
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
    });

    tearDown(() async {
      favoriteSyncModel.dispose();
      downloadManagerModel.dispose();
      feedModel.dispose();
      homeUiModel.dispose();
      await harness.dispose();
    });

    Widget buildShell() {
      final metaGateway = FakeNhentaiGateway();
      return MultiProvider(
        providers: <SingleChildWidget>[
          ChangeNotifierProvider<HomeUiModel>.value(value: homeUiModel),
          ChangeNotifierProvider<ComicFeedModel>.value(value: feedModel),
          ChangeNotifierProvider<DownloadManagerModel>.value(
            value: downloadManagerModel,
          ),
          ChangeNotifierProvider<FavoriteSyncModel>.value(
            value: favoriteSyncModel,
          ),
          ChangeNotifierProvider<BlockedTagsModel>(
            create: (_) => BlockedTagsModel(
              blockedTagsRepository: FakeBlockedTagsRepository(),
            ),
          ),
          ChangeNotifierProvider<TagCatalogBrowserModel>(
            create: (_) => TagCatalogBrowserModel(
              localTagCatalogService: LocalTagCatalogService.fromEntries(
                const [],
              ),
              tagDisplayService: TagDisplayService.fromMap(const {}),
            ),
          ),
          Provider<TagDisplayService>.value(
            value: TagDisplayService.fromMap(const {}),
          ),
          Provider<SearchHistoryRepository>(
            create: (_) =>
                SearchHistoryRepository(localDatabase: harness.localDatabase),
          ),
          Provider<LoadComicMetaUseCase>(
            create: (_) => LoadComicMetaUseCase(nhentaiGateway: metaGateway),
          ),
          Provider<ReaderLauncher>(
            create: (_) =>
                ReaderLauncher(downloadManagerModel: downloadManagerModel),
          ),
          Provider<HomeShellController>(
            create: (_) => HomeShellController(
              searchHistoryRepository: SearchHistoryRepository(
                localDatabase: harness.localDatabase,
              ),
              homeUiModel: homeUiModel,
              feedModel: feedModel,
              tagSearchQueryBuilder: const TagSearchQueryBuilder(),
            ),
          ),
          Provider<ComicCardActionCoordinator>(
            create: (_) => ComicCardActionCoordinator(
              saveComicToCollectionUseCase: SaveComicToCollectionUseCase(
                comicRepository: harness.comicRepository,
                collectionRepository: harness.collectionRepository,
              ),
              removeComicFromCollectionUseCase:
                  RemoveComicFromCollectionUseCase(
                    collectionRepository: harness.collectionRepository,
                  ),
              favoriteSyncModel: favoriteSyncModel,
              feedModel: feedModel,
              downloadManagerModel: downloadManagerModel,
              loadComicMetaUseCase: LoadComicMetaUseCase(
                nhentaiGateway: metaGateway,
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: HomeShell())),
      );
    }

    double offset(WidgetTester tester) {
      return tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .pixels;
    }

    testWidgets('keeps each tab on its own scroll offset', (tester) async {
      await tester.pumpWidget(buildShell());
      await tester.pump();

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pump();
      final homeOffset = offset(tester);
      expect(homeOffset, greaterThan(0), reason: 'the home feed scrolled');

      // Downloads is empty here, which is the case that used to destroy the
      // home offset: one shared position, clamped to the shorter extent and
      // never restored on the way back.
      homeUiModel.setNavigationIndex(1);
      await tester.pump();
      expect(offset(tester), 0, reason: 'Downloads starts at the top');

      homeUiModel.setNavigationIndex(0);
      await tester.pump();
      expect(offset(tester), homeOffset, reason: 'the home feed kept its place');
    });

    testWidgets('the refresh button reloads and returns to the top', (
      tester,
    ) async {
      await tester.pumpWidget(buildShell());
      await tester.pump();

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pump();
      // The app bar floats and snaps, so it is off screen after a downward
      // drag. Nudge back up to bring it in without returning to the top.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 120));
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(offset(tester), greaterThan(0));
      final searchesBefore = gateway.searchedUris.length;

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        gateway.searchedUris.length,
        searchesBefore + 1,
        reason: 'refresh is the one gesture that does refetch',
      );
      expect(
        offset(tester),
        0,
        reason: 'asking for fresh results means landing on them',
      );
    });

    testWidgets('switching tabs does not attach one position twice', (
      tester,
    ) async {
      // Swapping the controller without a per-tab key would leave two
      // controllers pointing at a single ScrollPosition, which throws rather
      // than degrading quietly. Walking the whole cycle is what surfaces it.
      await tester.pumpWidget(buildShell());
      await tester.pump();

      for (final index in <int>[1, 2, 0, 2, 1, 0]) {
        homeUiModel.setNavigationIndex(index);
        await tester.pump();
      }

      expect(tester.takeException(), isNull);
    });
  });
}
