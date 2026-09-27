import 'package:concept_nhv/application/favorites/clear_favorite_auth_use_case.dart';
import 'package:concept_nhv/application/favorites/initialize_favorites_use_case.dart';
import 'package:concept_nhv/application/favorites/save_api_key_use_case.dart';
import 'package:concept_nhv/application/favorites/sync_remote_favorites_use_case.dart';
import 'package:concept_nhv/application/favorites/toggle_favorite_use_case.dart';
import 'package:concept_nhv/application/feed/search_comics_use_case.dart';
import 'package:concept_nhv/application/reader/load_comic_detail_use_case.dart';
import 'package:concept_nhv/application/reader/load_offline_comic_use_case.dart';
import 'package:concept_nhv/application/reader/open_comic_use_case.dart';
import 'package:concept_nhv/application/reader/reader_settings_repository.dart';
import 'package:concept_nhv/application/tags/find_similar_comics_online_use_case.dart';
import 'package:concept_nhv/application/tags/find_similar_comics_use_case.dart';
import 'package:concept_nhv/models/collection_type.dart';
import 'package:concept_nhv/models/comic.dart';
import 'package:concept_nhv/models/local_tag_catalog_entry.dart';
import 'package:concept_nhv/models/stored_comic.dart';
import 'package:concept_nhv/screens/comic_reader_screen.dart';
import 'package:concept_nhv/services/comic_page_source_resolver.dart';
import 'package:concept_nhv/services/download_asset_store.dart';
import 'package:concept_nhv/services/local_tag_catalog_service.dart';
import 'package:concept_nhv/services/search_query_builder.dart';
import 'package:concept_nhv/services/tag_display_service.dart';
import 'package:concept_nhv/state/favorite_sync_model.dart';
import 'package:concept_nhv/state/reader_settings_model.dart';
import 'package:concept_nhv/storage/comic_repository.dart';
import 'package:concept_nhv/storage/comic_tag_repository.dart';
import 'package:concept_nhv/storage/download_queue_repository.dart';
import 'package:concept_nhv/storage/downloaded_library_repository.dart';
import 'package:concept_nhv/storage/nhentai_api_key_store.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../fakes/fake_blocked_tags_repository.dart';
import '../fakes/fake_nhentai_auth_service.dart';
import '../fakes/fake_nhentai_gateway.dart';
import '../fakes/fake_reader_settings_repository.dart';
import '../fakes/fake_remote_favorite_gateway.dart';
import '../fakes/memory_secure_store.dart';
import '../storage/sqlite_test_harness.dart';
import 'localized_test_app.dart';

/// Assembles everything [ComicReaderScreen] reads from its context.
///
/// The reader needs a dozen providers, which is why it had no tests at all
/// while it accumulated two of this project's worse bugs: a navigation call
/// that locked every comic in the app shut, and a guard against recording the
/// trailing page as reading progress that nothing verified.
///
/// Deliberately has no logic of its own, and the use cases it provides are
/// the real ones. A stub that simply returned "here are two similar comics"
/// would make the tests shorter and would stop testing the thing that broke.
class ReaderTestHarness {
  late SqliteTestHarness storage;
  late FakeReaderSettingsRepository readerSettings;
  late FavoriteSyncModel favorites;
  late FakeNhentaiAuthService auth;

  Future<void> initialize() async {
    storage = SqliteTestHarness();
    await storage.initialize();
    readerSettings = FakeReaderSettingsRepository();

    auth = FakeNhentaiAuthService(
      NhentaiApiKeyStore(secureStore: MemorySecureKeyValueStore()),
    );
    // Favourites are server-backed: without a key the toggle correctly
    // refuses, and a test of the button would only prove that it fails.
    await auth.saveAndValidateApiKey('test-key');
    final remoteFavorites = FakeRemoteFavoriteGateway();

    favorites = FavoriteSyncModel(
      initializeFavoritesUseCase: InitializeFavoritesUseCase(
        collectionRepository: storage.collectionRepository,
        authService: auth,
      ),
      saveApiKeyUseCase: SaveApiKeyUseCase(authService: auth),
      clearFavoriteAuthUseCase: ClearFavoriteAuthUseCase(authService: auth),
      syncRemoteFavoritesUseCase: SyncRemoteFavoritesUseCase(
        collectionRepository: storage.collectionRepository,
        comicTagRepository: storage.comicTagRepository,
        remoteFavoriteGateway: remoteFavorites,
      ),
      toggleFavoriteUseCase: ToggleFavoriteUseCase(
        collectionRepository: storage.collectionRepository,
        comicTagRepository: storage.comicTagRepository,
        remoteFavoriteGateway: remoteFavorites,
        authService: auth,
      ),
    );
  }

  Future<void> dispose() async {
    favorites.dispose();
    await storage.dispose();
  }

  /// Puts a comic in the library with [tagIds], so the real similarity lookup
  /// has something to find.
  Future<void> keep(String comicId, List<int> tagIds) async {
    await storage.comicRepository.upsertComic(
      StoredComic(
        id: comicId,
        mediaId: 'm$comicId',
        title: 'Comic $comicId',
        serializedImages: '',
        pages: 20,
      ),
    );
    await storage.comicTagRepository.replaceTagIds(comicId, tagIds);
    await storage.collectionRepository.addComicToCollection(
      collectionType: CollectionType.favorite,
      comicId: comicId,
    );
  }

  /// The reader for [comic], mounted under everything it needs.
  Widget buildApp({
    required Comic comic,
    bool offline = false,
    List<LocalTagCatalogEntry> catalog = const <LocalTagCatalogEntry>[],
  }) {
    final gateway = FakeNhentaiGateway(detailComic: comic);
    final catalogService = LocalTagCatalogService.fromEntries(catalog);

    final providers = <SingleChildWidget>[
      Provider<LoadComicDetailUseCase>.value(
        value: LoadComicDetailUseCase(nhentaiGateway: gateway),
      ),
      Provider<LoadOfflineComicUseCase>.value(
        value: LoadOfflineComicUseCase(
          downloadQueueRepository: storage.downloadQueueRepository,
          downloadedLibraryRepository: storage.downloadedLibraryRepository,
          downloadAssetStore: DownloadAssetStore(
            directoryResolver: () async => throw UnimplementedError(),
          ),
        ),
      ),
      Provider<OpenComicUseCase>.value(
        value: OpenComicUseCase(
          comicRepository: storage.comicRepository,
          collectionRepository: storage.collectionRepository,
          comicTagRepository: storage.comicTagRepository,
        ),
      ),
      Provider<ReaderSettingsRepository>.value(value: readerSettings),
      Provider<DownloadedLibraryRepository>.value(
        value: storage.downloadedLibraryRepository,
      ),
      Provider<DownloadQueueRepository>.value(
        value: storage.downloadQueueRepository,
      ),
      Provider<ComicRepository>.value(value: storage.comicRepository),
      Provider<ComicTagRepository>.value(value: storage.comicTagRepository),
      Provider<ComicPageSourceResolver>.value(
        value: const ComicPageSourceResolver(),
      ),
      Provider<TagDisplayService>.value(
        value: TagDisplayService.fromMap(const <String, String>{}),
      ),
      ChangeNotifierProvider<LocalTagCatalogService>.value(
        value: catalogService,
      ),
      Provider<FindSimilarComicsUseCase>.value(
        value: FindSimilarComicsUseCase(
          comicTagRepository: storage.comicTagRepository,
          comicRepository: storage.comicRepository,
          localTagCatalogService: catalogService,
        ),
      ),
      Provider<FindSimilarComicsOnlineUseCase>.value(
        value: FindSimilarComicsOnlineUseCase(
          searchComicsUseCase: SearchComicsUseCase(
            nhentaiGateway: gateway,
            searchQueryBuilder: const SearchQueryBuilder(),
          ),
          comicTagRepository: storage.comicTagRepository,
          localTagCatalogService: catalogService,
          blockedTagsRepository: FakeBlockedTagsRepository(),
        ),
      ),
      ChangeNotifierProvider<ReaderSettingsModel>(
        create: (_) =>
            ReaderSettingsModel(readerSettingsRepository: readerSettings),
      ),
      ChangeNotifierProvider<FavoriteSyncModel>.value(value: favorites),
    ];

    final router = GoRouter(
      initialLocation: '/third?id=${comic.id}',
      routes: <RouteBase>[
        GoRoute(
          name: 'third',
          path: '/third',
          builder: (context, state) => ComicReaderScreen(
            comicId: state.uri.queryParameters['id'] ?? comic.id,
            offline: offline,
          ),
        ),
      ],
    );

    return MultiProvider(
      providers: providers,
      child: localizedTestRouterApp(routerConfig: router),
    );
  }
}
