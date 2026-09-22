import 'package:concept_nhv/application/favorites/sync_remote_favorites_use_case.dart';
import 'package:concept_nhv/models/collection_type.dart';
import 'package:concept_nhv/models/comic.dart';
import 'package:concept_nhv/models/stored_comic.dart';
import 'package:concept_nhv/storage/nhentai_api_key_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_support/fakes/fake_nhentai_auth_service.dart';
import '../test_support/fakes/fake_remote_favorite_gateway.dart';
import '../test_support/fakes/memory_secure_store.dart';
import '../test_support/fixtures/sample_comic.dart';
import '../test_support/storage/sqlite_test_harness.dart';

void main() {
  group('SyncRemoteFavoritesUseCase', () {
    late SqliteTestHarness harness;
    late NhentaiApiKeyStore apiKeyStore;
    late FakeNhentaiAuthService authService;
    late FakeRemoteFavoriteGateway remoteFavoriteGateway;
    late SyncRemoteFavoritesUseCase useCase;

    setUp(() async {
      harness = SqliteTestHarness();
      await harness.initialize();
      apiKeyStore = NhentaiApiKeyStore(
        secureStore: MemorySecureKeyValueStore(),
      );
      authService = FakeNhentaiAuthService(apiKeyStore);
      remoteFavoriteGateway = FakeRemoteFavoriteGateway();
      useCase = SyncRemoteFavoritesUseCase(
        collectionRepository: harness.collectionRepository,
        comicTagRepository: harness.comicTagRepository,
        remoteFavoriteGateway: remoteFavoriteGateway,
      );
    });

    tearDown(() async {
      await harness.dispose();
    });

    test('refreshes local favorite cache when api key is valid', () async {
      remoteFavoriteGateway.remoteFavorites = <Comic>[
        sampleComic(id: '11'),
        sampleComic(id: '22'),
      ];
      authService.isValid = true;

      final result = await useCase.execute();

      expect(result.success, isTrue);
      expect(result.favoriteIds, <String>{'11', '22'});
      expect(
        await harness.collectionRepository.loadCollectedComicIds(
          CollectionType.favorite,
        ),
        <String>{'11', '22'},
      );
    });

    test('stores the tag ids each favorite carries', () async {
      remoteFavoriteGateway.remoteFavorites = <Comic>[
        sampleComic(
          id: '11',
        ).copyWith(tags: const [], tagIds: <int>[2937, 12227]),
        sampleComic(id: '22').copyWith(tags: const [], tagIds: const <int>[]),
      ];
      authService.isValid = true;

      await useCase.execute();

      expect(await harness.comicTagRepository.loadTagIds('11'), <int>{
        2937,
        12227,
      });
      expect(await harness.comicTagRepository.loadTagIds('22'), isEmpty);
    });

    test('keeps cached favorites when auth validation fails', () async {
      await harness.comicRepository.upsertComic(
        StoredComic.fromComic(sampleComic(id: '1')),
      );
      await harness.collectionRepository.addComicToCollection(
        collectionType: CollectionType.favorite,
        comicId: '1',
      );
      remoteFavoriteGateway.throwAuthException = true;

      final result = await useCase.execute();

      expect(result.success, isFalse);
      expect(result.isAuthenticated, isFalse);
      expect(result.favoriteIds, <String>{'1'});
      expect(
        result.errorMessage,
        'API key expired or invalid. Showing cached favorites.',
      );
    });
  });

  group('SyncRemoteFavoritesUseCase.executeIncremental', () {
    late SqliteTestHarness harness;
    late FakeRemoteFavoriteGateway gateway;
    late SyncRemoteFavoritesUseCase useCase;

    List<Comic> comics(List<String> ids) => ids
        .map(
          (id) => sampleComic(
            id: id,
          ).copyWith(tags: const [], tagIds: <int>[int.parse(id)]),
        )
        .toList();

    Future<void> seedLocal(List<String> ids) {
      return harness.collectionRepository.replaceCollectionCache(
        collectionType: CollectionType.favorite,
        comics: comics(ids).map(StoredComic.fromComic),
      );
    }

    Future<List<String>> localOrder() =>
        harness.collectionRepository.loadFavoriteIdsInOrder();

    setUp(() async {
      harness = SqliteTestHarness();
      await harness.initialize();
      gateway = FakeRemoteFavoriteGateway()..pageSize = 3;
      useCase = SyncRemoteFavoritesUseCase(
        collectionRepository: harness.collectionRepository,
        comicTagRepository: harness.comicTagRepository,
        remoteFavoriteGateway: gateway,
        pageDelay: Duration.zero,
      );
    });

    tearDown(() async {
      await harness.dispose();
    });

    test('no change: one page request and no full sync', () async {
      await seedLocal(<String>['1', '2', '3', '4', '5', '6', '7']);
      gateway.remoteFavorites = comics(<String>[
        '1',
        '2',
        '3',
        '4',
        '5',
        '6',
        '7',
      ]);

      final result = await useCase.executeIncremental();

      expect(result.success, isTrue);
      expect(gateway.requestedPages, <int>[1]);
      expect(gateway.loadCallCount, 0);
      expect(await localOrder(), <String>['1', '2', '3', '4', '5', '6', '7']);
    });

    test(
      'new favorites are fetched until a fully known page, then merged first',
      () async {
        await seedLocal(<String>['1', '2', '3', '4', '5', '6']);
        gateway.remoteFavorites = comics(<String>[
          '10',
          '11',
          '1',
          '2',
          '3',
          '4',
          '5',
          '6',
        ]);

        final result = await useCase.executeIncremental();

        expect(result.success, isTrue);
        // Page 1 = [10,11,1] has new ids, page 2 = [2,3,4] is all known.
        expect(gateway.requestedPages, <int>[1, 2]);
        expect(gateway.loadCallCount, 0);
        expect(await localOrder(), <String>[
          '10',
          '11',
          '1',
          '2',
          '3',
          '4',
          '5',
          '6',
        ]);
        expect(await harness.comicTagRepository.loadTagIds('10'), <int>{10});
        expect(result.favoriteIds, contains('11'));
      },
    );

    test(
      'a re-favorited old comic on top does not stop the walk early',
      () async {
        await seedLocal(<String>['1', '2', '3', '4', '5', '6']);
        // 6 was re-favorited, so it sits above the genuinely new 10.
        gateway.remoteFavorites = comics(<String>[
          '6',
          '10',
          '1',
          '2',
          '3',
          '4',
          '5',
        ]);

        await useCase.executeIncremental();

        expect(await localOrder(), <String>[
          '6',
          '10',
          '1',
          '2',
          '3',
          '4',
          '5',
        ]);
      },
    );

    test('a favorite removed elsewhere falls back to a full sync', () async {
      await seedLocal(<String>['1', '2', '3', '4']);
      gateway.remoteFavorites = comics(<String>['1', '2', '4']);

      final result = await useCase.executeIncremental();

      expect(result.success, isTrue);
      expect(gateway.loadCallCount, 1);
      expect(await localOrder(), <String>['1', '2', '4']);
    });

    test('a missing total falls back to a full sync', () async {
      await seedLocal(<String>['1', '2', '3']);
      gateway.remoteFavorites = comics(<String>['1', '2', '3']);
      gateway.omitTotal = true;

      await useCase.executeIncremental();

      expect(gateway.loadCallCount, 1);
    });

    test('empty local favorites go straight to a full sync', () async {
      gateway.remoteFavorites = comics(<String>['1', '2']);

      await useCase.executeIncremental();

      expect(gateway.requestedPages, isEmpty);
      expect(gateway.loadCallCount, 1);
      expect(await localOrder(), <String>['1', '2']);
    });

    test('auth failure keeps cached favorites', () async {
      await seedLocal(<String>['1']);
      gateway.throwAuthException = true;

      final result = await useCase.executeIncremental();

      expect(result.success, isFalse);
      expect(result.isAuthenticated, isFalse);
      expect(result.favoriteIds, <String>{'1'});
    });
  });
}
