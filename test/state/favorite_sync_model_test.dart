import 'package:concept_nhv/application/favorites/clear_favorite_auth_use_case.dart';
import 'package:concept_nhv/application/favorites/initialize_favorites_use_case.dart';
import 'package:concept_nhv/application/favorites/save_api_key_use_case.dart';
import 'package:concept_nhv/application/favorites/sync_remote_favorites_use_case.dart';
import 'package:concept_nhv/application/favorites/toggle_favorite_use_case.dart';
import 'package:concept_nhv/models/collection_type.dart';
import 'package:concept_nhv/models/comic.dart';
import 'package:concept_nhv/models/comic_card_data.dart';
import 'package:concept_nhv/state/favorite_sync_model.dart';
import 'package:concept_nhv/models/stored_comic.dart';
import 'package:concept_nhv/storage/nhentai_api_key_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_support/fakes/fake_nhentai_auth_service.dart';
import '../test_support/fakes/fake_remote_favorite_gateway.dart';
import '../test_support/fakes/memory_secure_store.dart';
import '../test_support/fixtures/sample_comic.dart';
import '../test_support/storage/sqlite_test_harness.dart';

void main() {
  late SqliteTestHarness harness;
  late NhentaiApiKeyStore apiKeyStore;
  late FakeNhentaiAuthService authService;
  late FakeRemoteFavoriteGateway remoteFavoriteGateway;
  late FavoriteSyncModel model;
  late InitializeFavoritesUseCase initializeFavoritesUseCase;
  late SaveApiKeyUseCase saveApiKeyUseCase;
  late ClearFavoriteAuthUseCase clearFavoriteAuthUseCase;
  late SyncRemoteFavoritesUseCase syncRemoteFavoritesUseCase;
  late ToggleFavoriteUseCase toggleFavoriteUseCase;

  setUp(() async {
    harness = SqliteTestHarness();
    await harness.initialize();
    apiKeyStore = NhentaiApiKeyStore(secureStore: MemorySecureKeyValueStore());
    authService = FakeNhentaiAuthService(apiKeyStore);
    remoteFavoriteGateway = FakeRemoteFavoriteGateway();
    initializeFavoritesUseCase = InitializeFavoritesUseCase(
      collectionRepository: harness.collectionRepository,
      authService: authService,
    );
    saveApiKeyUseCase = SaveApiKeyUseCase(authService: authService);
    clearFavoriteAuthUseCase = ClearFavoriteAuthUseCase(
      authService: authService,
    );
    syncRemoteFavoritesUseCase = SyncRemoteFavoritesUseCase(
      collectionRepository: harness.collectionRepository,
      remoteFavoriteGateway: remoteFavoriteGateway,
    );
    toggleFavoriteUseCase = ToggleFavoriteUseCase(
      collectionRepository: harness.collectionRepository,
      remoteFavoriteGateway: remoteFavoriteGateway,
      authService: authService,
    );
    model = FavoriteSyncModel(
      initializeFavoritesUseCase: initializeFavoritesUseCase,
      saveApiKeyUseCase: saveApiKeyUseCase,
      clearFavoriteAuthUseCase: clearFavoriteAuthUseCase,
      syncRemoteFavoritesUseCase: syncRemoteFavoritesUseCase,
      toggleFavoriteUseCase: toggleFavoriteUseCase,
    );
  });

  tearDown(() async {
    await harness.dispose();
  });

  test('initialize loads cached favorites and auth state', () async {
    await harness.comicRepository.upsertComic(
      StoredComic.fromComic(sampleComic(id: '1')),
    );
    await harness.collectionRepository.addComicToCollection(
      collectionType: CollectionType.favorite,
      comicId: '1',
    );
    await apiKeyStore.save(await authService.saveAndValidateApiKey('key-123'));

    await model.initialize();

    expect(model.favoriteIds, <String>{'1'});
    expect(model.isAuthenticated, isTrue);
    expect(model.isInitialized, isTrue);
    expect(model.lastSyncAt, isNotNull);
  });

  test('syncFavorites refreshes remote favorites into local cache', () async {
    remoteFavoriteGateway.remoteFavorites = <Comic>[
      sampleComic(id: '11'),
      sampleComic(id: '22'),
    ];
    authService.isValid = true;
    await model.initialize();

    final ok = await model.syncFavorites();
    final ids = await harness.collectionRepository.loadCollectedComicIds(
      CollectionType.favorite,
    );

    expect(ok, isTrue);
    expect(model.isAuthenticated, isTrue);
    expect(model.syncError, isNull);
    expect(model.favoriteIds, <String>{'11', '22'});
    expect(ids, <String>{'11', '22'});
  });

  test('syncFavorites keeps cached favorites on auth failure', () async {
    await harness.comicRepository.upsertComic(
      StoredComic.fromComic(sampleComic(id: '1')),
    );
    await harness.collectionRepository.addComicToCollection(
      collectionType: CollectionType.favorite,
      comicId: '1',
    );
    authService.isValid = false;
    remoteFavoriteGateway.throwAuthException = true;
    await model.initialize();

    final ok = await model.syncFavorites();

    expect(ok, isFalse);
    expect(model.isAuthenticated, isFalse);
    expect(model.favoriteIds, <String>{'1'});
    expect(
      model.syncError,
      'API key expired or invalid. Showing cached favorites.',
    );
  });

  test('toggleFavorite adds and removes remote favorite after auth', () async {
    remoteFavoriteGateway.remoteFavorites = <Comic>[];
    authService.isValid = true;
    await model.initialize();
    final comic = ComicCardData.fromComic(sampleComic(id: '7'));

    final addOk = await model.toggleFavorite(comic);

    expect(addOk, isTrue);
    expect(remoteFavoriteGateway.addedComicIds, <String>['7']);
    expect(model.isFavorite('7'), isTrue);

    final removeOk = await model.toggleFavorite(comic);

    expect(removeOk, isTrue);
    expect(remoteFavoriteGateway.removedComicIds, <String>['7']);
    expect(model.isFavorite('7'), isFalse);
  });

  test('clearApiKey resets auth state and last sync metadata', () async {
    authService.isValid = true;
    await model.saveAndValidateApiKey('key-123');

    await model.clearApiKey();

    expect(model.isAuthenticated, isFalse);
    expect(model.lastSyncAt, isNull);
    expect(model.syncError, isNull);
    expect((await apiKeyStore.load()).isEmpty, isTrue);
  });
}
