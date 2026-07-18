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
}
