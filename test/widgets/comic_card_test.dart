import 'package:concept_nhv/widgets/comic_card.dart';
import 'package:concept_nhv/application/favorites/clear_favorite_auth_use_case.dart';
import 'package:concept_nhv/application/favorites/initialize_favorites_use_case.dart';
import 'package:concept_nhv/application/favorites/save_api_key_use_case.dart';
import 'package:concept_nhv/application/favorites/sync_remote_favorites_use_case.dart';
import 'package:concept_nhv/application/favorites/toggle_favorite_use_case.dart';
import 'package:concept_nhv/models/download_job_snapshot.dart';
import 'package:concept_nhv/models/download_job_status.dart';
import 'package:concept_nhv/models/comic_card_data.dart';
import 'package:concept_nhv/services/download_asset_store.dart';
import 'package:concept_nhv/services/nhentai_cdn_config_service.dart';
import 'package:concept_nhv/state/download_manager_model.dart';
import 'package:concept_nhv/state/favorite_sync_model.dart';
import 'package:concept_nhv/storage/download_settings_store.dart';
import 'package:concept_nhv/storage/nhentai_api_key_store.dart';
import 'package:concept_nhv/storage/options_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../test_support/fakes/fake_image_compression_service.dart';
import '../test_support/fakes/fake_nhentai_auth_service.dart';
import '../test_support/fakes/fake_nhentai_gateway.dart';
import '../test_support/fakes/fake_remote_asset_fetcher.dart';
import '../test_support/fakes/fake_remote_favorite_gateway.dart';
import '../test_support/fakes/memory_secure_store.dart';
import '../test_support/fixtures/sample_comic.dart';
import '../test_support/storage/sqlite_test_harness.dart';

void main() {
  group('ComicCard', () {
    late SqliteTestHarness harness;
    late FavoriteSyncModel favoriteSyncModel;

    setUp(() async {
      harness = SqliteTestHarness();
      await harness.initialize();
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
      await harness.dispose();
    });

    testWidgets('shows a downloading icon when the comic is downloading', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildCardTestWidget(
          favoriteSyncModel: favoriteSyncModel,
          downloadManagerModel: _FakeDownloadManagerModel(
            harness: harness,
            jobs: <DownloadJobSnapshot>[
              _job(DownloadJobStatus.downloading),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.downloading), findsOneWidget);
      expect(find.byIcon(Icons.download_done), findsNothing);
    });

    testWidgets('shows a downloaded icon when the comic is completed', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildCardTestWidget(
          favoriteSyncModel: favoriteSyncModel,
          downloadManagerModel: _FakeDownloadManagerModel(
            harness: harness,
            jobs: <DownloadJobSnapshot>[
              _job(DownloadJobStatus.completed),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.download_done), findsOneWidget);
      expect(find.byIcon(Icons.downloading), findsNothing);
    });

    testWidgets('does not show a status icon for queued jobs', (tester) async {
      await tester.pumpWidget(
        _buildCardTestWidget(
          favoriteSyncModel: favoriteSyncModel,
          downloadManagerModel: _FakeDownloadManagerModel(
            harness: harness,
            jobs: <DownloadJobSnapshot>[
              _job(DownloadJobStatus.queued),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.downloading), findsNothing);
      expect(find.byIcon(Icons.download_done), findsNothing);
    });
  });
}

Widget _buildCardTestWidget({
  required FavoriteSyncModel favoriteSyncModel,
  required DownloadManagerModel downloadManagerModel,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<FavoriteSyncModel>.value(value: favoriteSyncModel),
      ChangeNotifierProvider<DownloadManagerModel>.value(
        value: downloadManagerModel,
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 180,
          child: ComicCard(
            comic: ComicCardData.fromComic(sampleComic(id: 'card-1')),
          ),
        ),
      ),
    ),
  );
}

DownloadJobSnapshot _job(DownloadJobStatus status) {
  return DownloadJobSnapshot(
    comicId: 'card-1',
    mediaId: '321',
    title: 'English title',
    status: status,
    totalPages: 10,
    completedPages: status == DownloadJobStatus.completed ? 10 : 2,
    nextPageNumber: 3,
    requestedAt: DateTime(2026, 4, 16),
    updatedAt: DateTime(2026, 4, 16),
  );
}

class _FakeDownloadManagerModel extends DownloadManagerModel {
  _FakeDownloadManagerModel({
    required SqliteTestHarness harness,
    required this.jobs,
  }) : super(
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

  @override
  final List<DownloadJobSnapshot> jobs;

  @override
  DownloadJobSnapshot? jobForComic(String comicId) {
    for (final job in jobs) {
      if (job.comicId == comicId) {
        return job;
      }
    }
    return null;
  }
}
