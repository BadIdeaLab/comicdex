import 'package:concept_nhv/application/favorites/toggle_favorite_use_case.dart';
import 'package:concept_nhv/models/collection_type.dart';
import 'package:concept_nhv/models/comic_card_data.dart';
import 'package:concept_nhv/storage/nhentai_api_key_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_support/fakes/fake_nhentai_auth_service.dart';
import '../test_support/fakes/fake_remote_favorite_gateway.dart';
import '../test_support/fakes/memory_secure_store.dart';
import '../test_support/fixtures/sample_comic.dart';
import '../test_support/storage/sqlite_test_harness.dart';

void main() {
  group('ToggleFavoriteUseCase', () {
    late SqliteTestHarness harness;
    late NhentaiApiKeyStore apiKeyStore;
    late FakeNhentaiAuthService authService;
    late FakeRemoteFavoriteGateway remoteFavoriteGateway;
    late ToggleFavoriteUseCase useCase;

    setUp(() async {
      harness = SqliteTestHarness();
      await harness.initialize();
      apiKeyStore = NhentaiApiKeyStore(
        secureStore: MemorySecureKeyValueStore(),
      );
      authService = FakeNhentaiAuthService(apiKeyStore);
      remoteFavoriteGateway = FakeRemoteFavoriteGateway();
      useCase = ToggleFavoriteUseCase(
        collectionRepository: harness.collectionRepository,
        remoteFavoriteGateway: remoteFavoriteGateway,
        authService: authService,
      );
    });

    tearDown(() async {
      await harness.dispose();
    });

    test('updates remote favorite and local cache without a full resync', () async {
      authService.isValid = true;
      final comic = ComicCardData.fromComic(sampleComic(id: '7'));

      final addResult = await useCase.execute(comic: comic, isFavorite: false);
      final idsAfterAdd = await harness.collectionRepository
          .loadCollectedComicIds(CollectionType.favorite);

      final removeResult = await useCase.execute(comic: comic, isFavorite: true);
      final idsAfterRemove = await harness.collectionRepository
          .loadCollectedComicIds(CollectionType.favorite);

      expect(addResult.success, isTrue);
      expect(addResult.favoriteIds, <String>{'7'});
      expect(idsAfterAdd, <String>{'7'});
      expect(removeResult.success, isTrue);
      expect(removeResult.favoriteIds, isEmpty);
      expect(idsAfterRemove, isEmpty);
      expect(remoteFavoriteGateway.addedComicIds, <String>['7']);
      expect(remoteFavoriteGateway.removedComicIds, <String>['7']);
      // A lightweight toggle never calls the paginated listing endpoint.
      expect(remoteFavoriteGateway.loadCallCount, 0);
    });

    test('returns cached ids when no valid api key is available', () async {
      authService.isValid = false;
      final comic = ComicCardData.fromComic(sampleComic(id: '7'));

      final result = await useCase.execute(comic: comic, isFavorite: false);

      expect(result.success, isFalse);
      expect(result.isAuthenticated, isFalse);
      expect(result.errorMessage, 'Valid API key required to edit favorites.');
    });
  });
}
