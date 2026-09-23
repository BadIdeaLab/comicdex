import 'package:concept_nhv/application/favorites/clear_favorite_auth_use_case.dart';
import 'package:concept_nhv/application/favorites/initialize_favorites_use_case.dart';
import 'package:concept_nhv/application/favorites/save_api_key_use_case.dart';
import 'package:concept_nhv/application/favorites/sync_remote_favorites_use_case.dart';
import 'package:concept_nhv/application/favorites/toggle_favorite_use_case.dart';
import 'package:concept_nhv/application/feed/load_collection_summaries_use_case.dart';
import 'package:concept_nhv/application/feed/search_comics_use_case.dart';
import 'package:concept_nhv/application/library/collection_page_coordinator.dart';
import 'package:concept_nhv/application/library/load_collection_comics_use_case.dart';
import 'package:concept_nhv/models/collection_type.dart';
import 'package:concept_nhv/models/comic.dart';
import 'package:concept_nhv/models/comic_card_data.dart';
import 'package:concept_nhv/models/stored_comic.dart';
import 'package:concept_nhv/screens/collection_screen.dart';
import 'package:concept_nhv/services/search_query_builder.dart';
import 'package:concept_nhv/state/comic_feed_model.dart';
import 'package:concept_nhv/state/favorite_sync_model.dart';
import 'package:concept_nhv/storage/nhentai_api_key_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../test_support/fakes/fake_blocked_tags_repository.dart';
import '../test_support/fakes/fake_nhentai_auth_service.dart';
import '../test_support/fakes/fake_nhentai_gateway.dart';
import '../test_support/fakes/fake_remote_favorite_gateway.dart';
import '../test_support/fakes/memory_secure_store.dart';
import '../test_support/fixtures/sample_comic.dart';
import '../test_support/storage/sqlite_test_harness.dart';

/// Counts loads so a test can tell a local reload from a remote sync.
class _SpyCoordinator extends CollectionPageCoordinator {
  _SpyCoordinator({
    required super.loadCollectionComicsUseCase,
    required super.favoriteSyncModel,
    required super.feedModel,
  });

  int loadCount = 0;
  int refreshCount = 0;

  @override
  Future<List<ComicCardData>> load(CollectionType collectionType) {
    loadCount += 1;
    return super.load(collectionType);
  }

  @override
  Future<List<ComicCardData>> refresh(CollectionType collectionType) {
    refreshCount += 1;
    return super.refresh(collectionType);
  }
}

void main() {
  late SqliteTestHarness harness;
  late FakeRemoteFavoriteGateway remoteFavoriteGateway;
  late FakeNhentaiAuthService authService;
  late FavoriteSyncModel favoriteSyncModel;
  late ComicFeedModel feedModel;
  late _SpyCoordinator coordinator;

  setUp(() async {
    harness = SqliteTestHarness();
    await harness.initialize();
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
    authService = FakeNhentaiAuthService(
      NhentaiApiKeyStore(secureStore: MemorySecureKeyValueStore()),
    );
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
        comicTagRepository: harness.comicTagRepository,
        remoteFavoriteGateway: remoteFavoriteGateway,
        pageDelay: Duration.zero,
      ),
      toggleFavoriteUseCase: ToggleFavoriteUseCase(
        collectionRepository: harness.collectionRepository,
        comicTagRepository: harness.comicTagRepository,
        remoteFavoriteGateway: remoteFavoriteGateway,
        authService: authService,
      ),
    );
    coordinator = _SpyCoordinator(
      loadCollectionComicsUseCase: LoadCollectionComicsUseCase(
        collectionRepository: harness.collectionRepository,
      ),
      favoriteSyncModel: favoriteSyncModel,
      feedModel: feedModel,
    );
  });

  tearDown(() async {
    favoriteSyncModel.dispose();
    feedModel.dispose();
    await harness.dispose();
  });

  Future<void> pumpSliver(
    WidgetTester tester, {
    bool selectionMode = false,
    Set<String>? filterComicIds,
  }) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: <SingleChildWidget>[
          ChangeNotifierProvider<FavoriteSyncModel>.value(
            value: favoriteSyncModel,
          ),
          Provider<CollectionPageCoordinator>.value(value: coordinator),
        ],
        child: MaterialApp(
          home: CustomScrollView(
            slivers: <Widget>[
              CollectionComicSliver(
                collectionType: CollectionType.favorite,
                onToggleSelection: selectionMode ? (_) {} : null,
                filterComicIds: filterComicIds,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('reloads local data when a background sync finishes', (
    tester,
  ) async {
    // Kept empty: a populated grid pulls in providers this test does not
    // need, and the assertion is about reloading, not about the rows.
    await pumpSliver(tester);
    final refreshesAfterEntry = coordinator.refreshCount;

    // A second sync, as if triggered from Settings while the screen is open.
    await favoriteSyncModel.syncFavorites();
    await tester.pumpAndSettle();

    expect(coordinator.refreshCount, refreshesAfterEntry + 1);
    // The reload reads local data only; it must not start another sync.
    expect(coordinator.loadCount, 1);
  });

  testWidgets('does not reload while multi-select is active', (tester) async {
    await pumpSliver(tester, selectionMode: true);
    final refreshesAfterEntry = coordinator.refreshCount;

    await favoriteSyncModel.syncFavorites();
    await tester.pumpAndSettle();

    expect(coordinator.refreshCount, refreshesAfterEntry);
  });

  testWidgets('a tag filter that matches nothing says so, not "empty"', (
    tester,
  ) async {
    // Remote has it too, or the background sync on entry would wipe the
    // local favorite and the screen would show the plain empty state.
    remoteFavoriteGateway.remoteFavorites = <Comic>[sampleComic(id: '11')];
    await harness.collectionRepository.replaceCollectionCache(
      collectionType: CollectionType.favorite,
      comics: <StoredComic>[StoredComic.fromComic(sampleComic(id: '11'))],
    );

    await pumpSliver(tester, filterComicIds: <String>{'999'});

    expect(find.text('No comics here carry that tag'), findsOneWidget);
    expect(find.textContaining('No comics in'), findsNothing);
  });

  testWidgets('an empty collection keeps its own empty state', (tester) async {
    await pumpSliver(tester, filterComicIds: <String>{'999'});

    expect(find.textContaining('No comics in'), findsOneWidget);
    expect(find.text('No comics here carry that tag'), findsNothing);
  });
}
