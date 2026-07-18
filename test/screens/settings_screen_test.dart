import 'package:concept_nhv/application/downloads/download_settings_repository.dart';
import 'package:concept_nhv/application/favorites/clear_favorite_auth_use_case.dart';
import 'package:concept_nhv/application/favorites/initialize_favorites_use_case.dart';
import 'package:concept_nhv/application/favorites/save_api_key_use_case.dart';
import 'package:concept_nhv/application/favorites/sync_remote_favorites_use_case.dart';
import 'package:concept_nhv/application/favorites/toggle_favorite_use_case.dart';
import 'package:concept_nhv/application/feed/load_collection_summaries_use_case.dart';
import 'package:concept_nhv/application/feed/search_comics_use_case.dart';
import 'package:concept_nhv/application/reader/load_comic_detail_use_case.dart';
import 'package:concept_nhv/application/reader/load_offline_comic_use_case.dart';
import 'package:concept_nhv/application/reader/open_comic_use_case.dart';
import 'package:concept_nhv/screens/settings_screen.dart';
import 'package:concept_nhv/services/download_asset_store.dart';
import 'package:concept_nhv/services/library_import_service.dart';
import 'package:concept_nhv/services/search_query_builder.dart';
import 'package:concept_nhv/state/blocked_tags_model.dart';
import 'package:concept_nhv/state/comic_feed_model.dart';
import 'package:concept_nhv/state/comic_reader_model.dart';
import 'package:concept_nhv/state/favorite_sync_model.dart';
import 'package:concept_nhv/storage/download_settings_store.dart';
import 'package:concept_nhv/storage/nhentai_api_key_store.dart';
import 'package:concept_nhv/storage/options_store.dart';
import 'package:concept_nhv/storage/reader_progress_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../test_support/fakes/fake_blocked_tags_repository.dart';
import '../test_support/fakes/fake_nhentai_auth_service.dart';
import '../test_support/fakes/fake_nhentai_gateway.dart';
import '../test_support/fakes/fake_reader_settings_repository.dart';
import '../test_support/fakes/fake_remote_favorite_gateway.dart';
import '../test_support/fakes/memory_secure_store.dart';
import '../test_support/fixtures/sample_comic.dart';
import '../test_support/storage/sqlite_test_harness.dart';

void main() {
  group('SettingsScreen', () {
    late SqliteTestHarness harness;
    late DownloadSettingsStore downloadSettingsStore;
    late FavoriteSyncModel favoriteSyncModel;
    late ComicFeedModel comicFeedModel;
    late ComicReaderModel comicReaderModel;

    setUp(() async {
      harness = SqliteTestHarness();
      await harness.initialize();
      downloadSettingsStore = DownloadSettingsStore(
        optionsStore: OptionsStore(localDatabase: harness.localDatabase),
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

      comicFeedModel = ComicFeedModel(
        searchComicsUseCase: SearchComicsUseCase(
          nhentaiGateway: FakeNhentaiGateway(),
          searchQueryBuilder: const SearchQueryBuilder(),
        ),
        loadCollectionSummariesUseCase: LoadCollectionSummariesUseCase(
          collectionRepository: harness.collectionRepository,
        ),
        blockedTagsRepository: FakeBlockedTagsRepository(),
      );

      comicReaderModel = ComicReaderModel(
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
      comicReaderModel.dispose();
      comicFeedModel.dispose();
      favoriteSyncModel.dispose();
      await harness.dispose();
    });

    testWidgets('shows the downloads settings section with default values', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildSettingsScreen(
          downloadSettingsRepository: downloadSettingsStore,
          favoriteSyncModel: favoriteSyncModel,
          comicFeedModel: comicFeedModel,
          comicReaderModel: comicReaderModel,
          libraryImportService: LibraryImportService(
            comicRepository: harness.comicRepository,
            collectionRepository: harness.collectionRepository,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Downloads'), 300);
      await tester.pumpAndSettle();

      expect(find.text('Downloads'), findsOneWidget);
      expect(find.text('Auto Resume Downloads'), findsOneWidget);
      expect(find.text('Page Download Interval'), findsOneWidget);
      expect(
        find.text(
          'Resume interrupted downloads when the app returns to foreground or restarts',
        ),
        findsOneWidget,
      );
      expect(
        find.text('0.5 s\nApplies to new downloads or after resume'),
        findsOneWidget,
      );
      expect(
        await downloadSettingsStore.loadAutoResumeEnabled(),
        DownloadSettingsRepository.defaultAutoResumeEnabled,
      );
      expect(
        await downloadSettingsStore.loadPageIntervalMs(),
        DownloadSettingsRepository.defaultPageIntervalMs,
      );
    });

    testWidgets('toggles auto resume downloads and persists the setting', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildSettingsScreen(
          downloadSettingsRepository: downloadSettingsStore,
          favoriteSyncModel: favoriteSyncModel,
          comicFeedModel: comicFeedModel,
          comicReaderModel: comicReaderModel,
          libraryImportService: LibraryImportService(
            comicRepository: harness.comicRepository,
            collectionRepository: harness.collectionRepository,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Auto Resume Downloads'), 300);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(await downloadSettingsStore.loadAutoResumeEnabled(), isFalse);
    });

    testWidgets('applies preset interval values and rejects invalid manual input', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildSettingsScreen(
          downloadSettingsRepository: downloadSettingsStore,
          favoriteSyncModel: favoriteSyncModel,
          comicFeedModel: comicFeedModel,
          comicReaderModel: comicReaderModel,
          libraryImportService: LibraryImportService(
            comicRepository: harness.comicRepository,
            collectionRepository: harness.collectionRepository,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Page Download Interval'), 300);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Page Download Interval'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('1 s'));
      await tester.pumpAndSettle();

      expect(await downloadSettingsStore.loadPageIntervalMs(), 1000);

      await tester.tap(find.text('Page Download Interval'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '0.5s');
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(find.text('Only plain numeric seconds are supported'), findsOneWidget);
      expect(await downloadSettingsStore.loadPageIntervalMs(), 1000);

      await tester.enterText(find.byType(TextField), '5');
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(await downloadSettingsStore.loadPageIntervalMs(), 3000);
    });

    testWidgets(
      'clear API key asks for confirmation before clearing',
      (tester) async {
        await tester.pumpWidget(
          _buildSettingsScreen(
            downloadSettingsRepository: downloadSettingsStore,
            favoriteSyncModel: favoriteSyncModel,
            comicFeedModel: comicFeedModel,
            comicReaderModel: comicReaderModel,
            libraryImportService: LibraryImportService(
              comicRepository: harness.comicRepository,
              collectionRepository: harness.collectionRepository,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.text('Clear API Key'), 300);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Clear API Key'));
        await tester.pumpAndSettle();

        // Cancelling the confirmation dialog does not clear the key.
        expect(find.text('Clear API key?'), findsOneWidget);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.text('API key cleared'), findsNothing);

        // Confirming clears the key and shows the snackbar.
        await tester.tap(find.text('Clear API Key'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Clear'));
        await tester.pumpAndSettle();

        expect(find.text('API key cleared'), findsOneWidget);
      },
    );
  });
}

Widget _buildSettingsScreen({
  required DownloadSettingsRepository downloadSettingsRepository,
  required FavoriteSyncModel favoriteSyncModel,
  required ComicFeedModel comicFeedModel,
  required ComicReaderModel comicReaderModel,
  required LibraryImportService libraryImportService,
}) {
  return MultiProvider(
    providers: [
      Provider<DownloadSettingsRepository>.value(
        value: downloadSettingsRepository,
      ),
      ChangeNotifierProvider<FavoriteSyncModel>.value(value: favoriteSyncModel),
      ChangeNotifierProvider<ComicFeedModel>.value(value: comicFeedModel),
      ChangeNotifierProvider<ComicReaderModel>.value(value: comicReaderModel),
      Provider<LibraryImportService>.value(value: libraryImportService),
      ChangeNotifierProvider<BlockedTagsModel>(
        create: (_) => BlockedTagsModel(
          blockedTagsRepository: FakeBlockedTagsRepository(),
        ),
      ),
    ],
    child: const MaterialApp(home: SettingsScreen()),
  );
}
