import 'dart:async';

import 'package:concept_nhv/application/feed/load_collection_summaries_use_case.dart';
import 'package:concept_nhv/application/feed/search_comics_use_case.dart';
import 'package:concept_nhv/application/favorites/clear_favorite_auth_use_case.dart';
import 'package:concept_nhv/application/favorites/initialize_favorites_use_case.dart';
import 'package:concept_nhv/application/favorites/save_api_key_use_case.dart';
import 'package:concept_nhv/application/favorites/sync_remote_favorites_use_case.dart';
import 'package:concept_nhv/application/favorites/toggle_favorite_use_case.dart';
import 'package:concept_nhv/application/library/collection_page_coordinator.dart';
import 'package:concept_nhv/application/library/load_collection_comics_use_case.dart';
import 'package:concept_nhv/models/collection_type.dart';
import 'package:concept_nhv/models/comic.dart';
import 'package:concept_nhv/models/stored_comic.dart';
import 'package:concept_nhv/services/search_query_builder.dart';
import 'package:concept_nhv/state/comic_feed_model.dart';
import 'package:concept_nhv/state/favorite_sync_model.dart';
import 'package:concept_nhv/storage/nhentai_api_key_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_support/fakes/fake_blocked_tags_repository.dart';
import '../test_support/fakes/fake_nhentai_auth_service.dart';
import '../test_support/fakes/fake_nhentai_gateway.dart';
import '../test_support/fakes/fake_remote_favorite_gateway.dart';
import '../test_support/fakes/memory_secure_store.dart';
import '../test_support/fixtures/sample_comic.dart';
import '../test_support/storage/sqlite_test_harness.dart';

void main() {
  group('CollectionPageCoordinator', () {
    late SqliteTestHarness harness;
    late ComicFeedModel feedModel;
    late FavoriteSyncModel favoriteSyncModel;
    late FakeRemoteFavoriteGateway remoteFavoriteGateway;
    late FakeNhentaiAuthService authService;
    late CollectionPageCoordinator coordinator;

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
      coordinator = CollectionPageCoordinator(
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

    test(
      'load returns locally cached comics without waiting for favorite sync',
      () async {
        authService.isValid = true;
        await harness.comicRepository.upsertComic(
          StoredComic.fromComic(sampleComic(id: '12')),
        );
        await harness.collectionRepository.addComicToCollection(
          collectionType: CollectionType.favorite,
          comicId: '12',
        );
        // Simulate a remote sync that never completes (e.g. stuck in a
        // rate-limit backoff) — load() must not block on it.
        remoteFavoriteGateway.hangCompleter = Completer<void>();

        final comics = await coordinator
            .load(CollectionType.favorite)
            .timeout(const Duration(seconds: 2));

        expect(comics.map((comic) => comic.id).toList(), <String>['12']);
      },
    );

    test('load triggers a background favorite sync that eventually refreshes collections', () async {
      authService.isValid = true;
      remoteFavoriteGateway.remoteFavorites = <Comic>[
        sampleComic(id: '11'),
      ];

      await coordinator.load(CollectionType.favorite);
      // Let the un-awaited background sync run to completion.
      await Future<void>.delayed(Duration.zero);

      expect(feedModel.collectionSummariesFuture, isNotNull);
      final ids = await harness.collectionRepository.loadCollectedComicIds(
        CollectionType.favorite,
      );
      expect(ids, <String>{'11'});
    });

    test('refresh loads collection records without favorite sync side effects', () async {
      await harness.comicRepository.upsertComic(
        StoredComic.fromComic(sampleComic(id: '12')),
      );
      await harness.collectionRepository.addComicToCollection(
        collectionType: CollectionType.next,
        comicId: '12',
      );

      final comics = await coordinator.refresh(CollectionType.next);

      expect(comics.map((comic) => comic.id).toList(), <String>['12']);
      expect(feedModel.collectionSummariesFuture, isNull);
    });
  });
}
