import 'package:concept_nhv/widgets/comic_card.dart';
import 'package:concept_nhv/widgets/comic_language_badge.dart';
import 'package:concept_nhv/application/favorites/clear_favorite_auth_use_case.dart';
import 'package:concept_nhv/application/favorites/initialize_favorites_use_case.dart';
import 'package:concept_nhv/application/favorites/save_api_key_use_case.dart';
import 'package:concept_nhv/application/favorites/sync_remote_favorites_use_case.dart';
import 'package:concept_nhv/application/favorites/toggle_favorite_use_case.dart';
import 'package:concept_nhv/models/download_job_snapshot.dart';
import 'package:concept_nhv/models/download_job_status.dart';
import 'package:concept_nhv/models/comic_card_data.dart';
import 'package:concept_nhv/models/comic_tag.dart';
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
          comicTagRepository: harness.comicTagRepository,
          remoteFavoriteGateway: remoteFavoriteGateway,
        ),
        toggleFavoriteUseCase: ToggleFavoriteUseCase(
          collectionRepository: harness.collectionRepository,
          comicTagRepository: harness.comicTagRepository,
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

    group('language', () {
      testWidgets('draws the badge at a width a reader can actually see', (
        tester,
      ) async {
        // The bug this replaces: the badge was laid out but squeezed to its own
        // padding, so the grid showed a row of empty grey boxes. `find.text`
        // reports a clipped label as present, so presence alone proves nothing
        // — the rendered width has to be asserted.
        //
        // 133 px is a phone in portrait (three columns at maxCrossAxisExtent
        // 180), which is the narrowest case that ships and the one the earlier
        // layout could never have satisfied.
        await tester.pumpWidget(
          _buildCardTestWidget(
            favoriteSyncModel: favoriteSyncModel,
            downloadManagerModel: _FakeDownloadManagerModel(
              harness: harness,
              jobs: const <DownloadJobSnapshot>[],
            ),
            tags: <ComicTag>[_languageTag('chinese')],
            width: 133,
          ),
        );
        await tester.pump();

        final label = tester.getSize(find.text('ZH'));
        expect(label.width, greaterThan(0));
        expect(label.height, greaterThan(0));
        expect(
          tester.getSize(find.byKey(languageBadgeKey)).width,
          greaterThan(label.width),
          reason: 'the plate must be wider than the text it wraps',
        );
      });

      testWidgets('leaves the page count centred', (tester) async {
        // The page count is centred only because the two icon buttons either
        // side are the same width. Putting anything beside it in that row moves
        // it off centre, which is why the badge lives over the cover instead.
        Future<double> pageCountOffset({required bool withLanguage}) async {
          await tester.pumpWidget(
            _buildCardTestWidget(
              favoriteSyncModel: favoriteSyncModel,
              downloadManagerModel: _FakeDownloadManagerModel(
                harness: harness,
                jobs: const <DownloadJobSnapshot>[],
              ),
              tags: withLanguage
                  ? <ComicTag>[_languageTag('chinese')]
                  : const <ComicTag>[],
            ),
          );
          await tester.pump();
          return tester.getCenter(find.text('2p')).dx -
              tester.getCenter(find.byType(ComicCard)).dx;
        }

        final withoutLanguage = await pageCountOffset(withLanguage: false);
        final withLanguage = await pageCountOffset(withLanguage: true);

        expect(withoutLanguage, moreOrLessEquals(0, epsilon: 0.5));
        expect(withLanguage, moreOrLessEquals(withoutLanguage, epsilon: 0.01));
      });

      testWidgets('shows the language over the cover', (tester) async {
        await tester.pumpWidget(
          _buildCardTestWidget(
            favoriteSyncModel: favoriteSyncModel,
            downloadManagerModel: _FakeDownloadManagerModel(
              harness: harness,
              jobs: const <DownloadJobSnapshot>[],
            ),
            tags: <ComicTag>[_languageTag('chinese')],
          ),
        );
        await tester.pump();

        expect(find.text('ZH'), findsOneWidget);
        expect(find.byKey(languageBadgeKey), findsOneWidget);
      });

      testWidgets('shows the language for a card straight off the feed', (
        tester,
      ) async {
        // The shape that actually reaches the home grid: no `tags` at all,
        // only `tag_ids`. The first version of this feature rendered nothing
        // here, and every tags-based test still passed.
        await tester.pumpWidget(
          _buildCardTestWidget(
            favoriteSyncModel: favoriteSyncModel,
            downloadManagerModel: _FakeDownloadManagerModel(
              harness: harness,
              jobs: const <DownloadJobSnapshot>[],
            ),
            tags: const <ComicTag>[],
            tagIds: const <int>[166978, 17249, 29963],
          ),
        );
        await tester.pump();

        expect(find.text('ZH'), findsOneWidget);
        expect(find.byKey(languageBadgeKey), findsOneWidget);
      });

      testWidgets('ignores translated and shows the real language', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildCardTestWidget(
            favoriteSyncModel: favoriteSyncModel,
            downloadManagerModel: _FakeDownloadManagerModel(
              harness: harness,
              jobs: const <DownloadJobSnapshot>[],
            ),
            tags: <ComicTag>[
              _languageTag('translated'),
              _languageTag('chinese'),
            ],
          ),
        );
        await tester.pump();

        expect(find.text('ZH'), findsOneWidget);
        expect(find.text('translated'), findsNothing);
      });

      testWidgets('shows nothing at all when the comic names no language', (
        tester,
      ) async {
        // The default fixture carries only a `tag`-type tag, which is also what
        // every card built from a stored comic looks like. Absent has to mean
        // *absent* — an empty chip or a stray separator would appear on most of
        // the Favorites grid.
        await tester.pumpWidget(
          _buildCardTestWidget(
            favoriteSyncModel: favoriteSyncModel,
            downloadManagerModel: _FakeDownloadManagerModel(
              harness: harness,
              jobs: const <DownloadJobSnapshot>[],
            ),
          ),
        );
        await tester.pump();

        expect(find.text('2p'), findsOneWidget, reason: 'page count still shows');
        expect(find.byKey(languageBadgeKey), findsNothing);
      });
    });
  });
}

Widget _buildCardTestWidget({
  required FavoriteSyncModel favoriteSyncModel,
  required DownloadManagerModel downloadManagerModel,
  List<ComicTag>? tags,
  List<int>? tagIds,
  double width = 180,
}) {
  var comic = sampleComic(id: 'card-1');
  if (tags != null) {
    comic = comic.copyWith(tags: tags);
  }
  if (tagIds != null) {
    comic = comic.copyWith(tagIds: tagIds);
  }
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
          width: width,
          child: ComicCard(comic: ComicCardData.fromComic(comic)),
        ),
      ),
    ),
  );
}

ComicTag _languageTag(String slug) {
  return ComicTag(type: 'language', name: slug, url: '/language/$slug/');
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
