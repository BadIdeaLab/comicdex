import 'package:concept_nhv/application/downloads/download_settings_repository.dart';
import 'package:concept_nhv/application/feed/load_collection_summaries_use_case.dart';
import 'package:concept_nhv/application/feed/search_comics_use_case.dart';
import 'package:concept_nhv/application/tags/load_comic_meta_use_case.dart';
import 'package:concept_nhv/application/home/home_shell_controller.dart';
import 'package:concept_nhv/application/reader/load_comic_detail_use_case.dart';
import 'package:concept_nhv/application/reader/load_offline_comic_use_case.dart';
import 'package:concept_nhv/application/reader/open_comic_use_case.dart';
import 'package:concept_nhv/models/comic_tag.dart';
import 'package:concept_nhv/models/download_job_snapshot.dart';
import 'package:concept_nhv/models/download_job_status.dart';
import 'package:concept_nhv/models/download_list_item_snapshot.dart';
import 'package:concept_nhv/models/downloaded_comic_snapshot.dart';
import 'package:concept_nhv/models/downloads_sort_mode.dart';
import 'package:concept_nhv/services/search_query_builder.dart';
import 'package:concept_nhv/services/tag_display_service.dart';
import 'package:concept_nhv/services/tag_search_query_builder.dart';
import 'package:concept_nhv/services/download_asset_store.dart';
import 'package:concept_nhv/services/nhentai_cdn_config_service.dart';
import 'package:concept_nhv/state/blocked_tags_model.dart';
import 'package:concept_nhv/state/comic_feed_model.dart';
import 'package:concept_nhv/state/comic_reader_model.dart';
import 'package:concept_nhv/state/download_manager_model.dart';
import 'package:concept_nhv/state/home_ui_model.dart';
import 'package:concept_nhv/storage/options_store.dart';
import 'package:concept_nhv/storage/reader_progress_store.dart';
import 'package:concept_nhv/widgets/download_job_list_sliver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../test_support/fakes/fake_blocked_tags_repository.dart';
import '../test_support/fakes/fake_image_compression_service.dart';
import '../test_support/fakes/fake_nhentai_gateway.dart';
import '../test_support/fakes/fake_reader_settings_repository.dart';
import '../test_support/fixtures/sample_comic.dart';
import '../test_support/fakes/fake_remote_asset_fetcher.dart';
import '../test_support/storage/sqlite_test_harness.dart';

void main() {
  group('DownloadJobListSliver', () {
    late SqliteTestHarness harness;

    setUp(() async {
      harness = SqliteTestHarness();
      await harness.initialize();
    });

    tearDown(() async {
      await harness.dispose();
    });

    testWidgets('filters by title and shows per-status actions when expanded', (
      tester,
    ) async {
      final model = _FakeDownloadManagerModel(
        harness: harness,
        itemsOverride: <DownloadListItemSnapshot>[
          _itemFromJob(
            comicId: 'paused',
            title: 'Paused Comic',
            status: DownloadJobStatus.paused,
            requestedAt: DateTime(2026, 4, 11),
          ),
          _itemFromDownloadedComic(
            comicId: 'completed',
            title: 'Downloaded Comic',
            requestedAt: DateTime(2026, 4, 10),
          ),
        ],
      );

      await tester.pumpWidget(
        _buildTestWidget(model: model, searchQuery: 'Paused'),
      );
      await tester.pump();

      expect(find.text('Paused Comic'), findsOneWidget);
      expect(find.text('Downloaded Comic'), findsNothing);

      await tester.tap(find.text('Paused Comic'));
      await tester.pumpAndSettle();

      expect(find.text('Resume'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);
      expect(find.text('Delete Download'), findsNothing);
    });

    testWidgets('filters by tag raw name', (tester) async {
      final model = _FakeDownloadManagerModel(
        harness: harness,
        itemsOverride: <DownloadListItemSnapshot>[
          _itemFromDownloadedComic(
            comicId: 'tagged',
            title: 'Tagged Comic',
            requestedAt: DateTime(2026, 4, 11),
            tags: <ComicTag>[ComicTag(type: 'tag', name: 'Full Color')],
          ),
          _itemFromDownloadedComic(
            comicId: 'untagged',
            title: 'Untagged Comic',
            requestedAt: DateTime(2026, 4, 10),
            tags: const <ComicTag>[],
          ),
        ],
      );

      await tester.pumpWidget(
        _buildTestWidget(model: model, searchQuery: 'full color'),
      );
      await tester.pump();

      expect(find.text('Tagged Comic'), findsOneWidget);
      expect(find.text('Untagged Comic'), findsNothing);
    });

    testWidgets('filters by translated (Chinese) tag name', (tester) async {
      final model = _FakeDownloadManagerModel(
        harness: harness,
        itemsOverride: <DownloadListItemSnapshot>[
          _itemFromDownloadedComic(
            comicId: 'tagged',
            title: 'Tagged Comic',
            requestedAt: DateTime(2026, 4, 11),
            tags: <ComicTag>[ComicTag(type: 'tag', name: 'Full Color')],
          ),
          _itemFromDownloadedComic(
            comicId: 'untagged',
            title: 'Untagged Comic',
            requestedAt: DateTime(2026, 4, 10),
            tags: const <ComicTag>[],
          ),
        ],
      );

      await tester.pumpWidget(
        _buildTestWidget(
          model: model,
          searchQuery: '全彩',
          tagDisplayMap: const <String, String>{'full-color': '全彩'},
        ),
      );
      await tester.pump();

      expect(find.text('Tagged Comic'), findsOneWidget);
      expect(find.text('Untagged Comic'), findsNothing);
    });

    testWidgets('shows Active and Completed section headers', (tester) async {
      final model = _FakeDownloadManagerModel(
        harness: harness,
        itemsOverride: <DownloadListItemSnapshot>[
          _itemFromJob(
            comicId: 'paused',
            title: 'Paused Comic',
            status: DownloadJobStatus.paused,
            requestedAt: DateTime(2026, 4, 11),
          ),
          _itemFromDownloadedComic(
            comicId: 'completed',
            title: 'Downloaded Comic',
            requestedAt: DateTime(2026, 4, 10),
          ),
        ],
      );

      await tester.pumpWidget(_buildTestWidget(model: model));
      await tester.pump();

      expect(find.text('Active Downloads'), findsOneWidget);
      expect(find.text('Completed Downloads'), findsOneWidget);
    });

    testWidgets('shows updated unified empty state copy', (tester) async {
      final model = _FakeDownloadManagerModel(
        harness: harness,
        itemsOverride: const <DownloadListItemSnapshot>[],
      );

      await tester.pumpWidget(_buildTestWidget(model: model));
      await tester.pump();

      expect(find.text('No downloads yet'), findsOneWidget);
    });

    testWidgets(
      'completed cards show tags and route tag chips through global tag search',
      (tester) async {
        final model = _FakeDownloadManagerModel(
          harness: harness,
          itemsOverride: <DownloadListItemSnapshot>[
            _itemFromDownloadedComic(
              comicId: 'completed',
              title: 'Downloaded Comic',
              requestedAt: DateTime(2026, 4, 10),
            ),
          ],
        );
        final controller = _FakeHomeShellController(harness: harness);

        await tester.pumpWidget(
          _buildTestWidget(model: model, controller: controller),
        );
        await tester.pump();

        expect(find.text('Downloaded Comic'), findsOneWidget);
        expect(find.text('2 pages'), findsOneWidget);

        // Completed cards: tap opens the offline reader; long-press expands details.
        await tester.longPress(find.text('Downloaded Comic'));
        await tester.pumpAndSettle();

        expect(find.text('sample'), findsOneWidget);
        expect(find.text('Delete Download'), findsOneWidget);

        await tester.tap(find.text('sample'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Search 1 tags'));
        await tester.pumpAndSettle();

        expect(controller.submittedTagQueries, <String>['tag:sample']);
      },
    );

    testWidgets(
      'toggles completed downloads between list and grid view',
      (tester) async {
        final model = _FakeDownloadManagerModel(
          harness: harness,
          itemsOverride: <DownloadListItemSnapshot>[
            _itemFromDownloadedComic(
              comicId: 'completed',
              title: 'Downloaded Comic',
              requestedAt: DateTime(2026, 4, 10),
            ),
          ],
        );

        await tester.pumpWidget(_buildTestWidget(model: model));
        await tester.pump();

        // List view (default): summary shows "Completed" + page count text.
        expect(find.text('Completed'), findsOneWidget);
        expect(find.text('2 pages'), findsOneWidget);
        expect(find.byIcon(Icons.grid_view), findsOneWidget);

        await tester.tap(find.byIcon(Icons.grid_view));
        await tester.pumpAndSettle();

        // Grid view: compact cell shows title + "Np" page count, no "Completed" label.
        expect(find.text('Completed'), findsNothing);
        expect(find.text('2p'), findsOneWidget);
        expect(find.byIcon(Icons.list), findsOneWidget);

        // Tap the grid cell opens the offline reader.
        bool opened = false;
        await tester.pumpWidget(
          _buildTestWidget(
            model: model,
            onOpenOfflineReader: (_) => opened = true,
          ),
        );
        await tester.tap(find.byIcon(Icons.grid_view));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Downloaded Comic'));
        await tester.pumpAndSettle();
        expect(opened, isTrue);

        // Toggle back to list view.
        await tester.tap(find.byIcon(Icons.list));
        await tester.pumpAndSettle();
        expect(find.text('Completed'), findsOneWidget);
      },
    );

    testWidgets('random completed button opens a visible completed download', (
      tester,
    ) async {
      final model = _FakeDownloadManagerModel(
        harness: harness,
        itemsOverride: <DownloadListItemSnapshot>[
          _itemFromDownloadedComic(
            comicId: 'completed',
            title: 'Downloaded Comic',
            requestedAt: DateTime(2026, 4, 10),
          ),
        ],
      );
      String? openedComicId;

      await tester.pumpWidget(
        _buildTestWidget(
          model: model,
          onOpenOfflineReader: (comicId) => openedComicId = comicId,
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.shuffle));
      await tester.pumpAndSettle();

      expect(openedComicId, 'completed');
    });

    testWidgets(
      'repair all button asks for confirmation before scanning completed downloads',
      (tester) async {
        final model = _FakeDownloadManagerModel(
          harness: harness,
          itemsOverride: <DownloadListItemSnapshot>[
            _itemFromDownloadedComic(
              comicId: 'completed',
              title: 'Downloaded Comic',
              requestedAt: DateTime(2026, 4, 10),
            ),
          ],
          repairAllResult: (
            repairedCount: 1,
            failedCount: 0,
            totalCount: 2,
            stoppedEarly: false,
          ),
        );

        await tester.pumpWidget(_buildTestWidget(model: model));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.build_circle_outlined));
        await tester.pumpAndSettle();

        // Confirmation dialog appears; cancelling does not run the repair.
        expect(find.text('Repair all completed downloads?'), findsOneWidget);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.text('Repaired 1 of 2 downloads'), findsNothing);

        // Confirming runs the repair and shows the summary snackbar.
        await tester.tap(find.byIcon(Icons.build_circle_outlined));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Repair All'));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('Repaired 1 of 2 downloads'), findsOneWidget);
      },
    );
  });
}

Widget _buildTestWidget({
  required DownloadManagerModel model,
  HomeShellController? controller,
  String searchQuery = '',
  ValueChanged<String>? onOpenOfflineReader,
  Map<String, String> tagDisplayMap = const <String, String>{},
}) {
  final providers = <SingleChildWidget>[
    Provider<TagDisplayService>.value(
      value: TagDisplayService.fromMap(tagDisplayMap),
    ),
    Provider<LoadComicMetaUseCase>(
      create: (_) => LoadComicMetaUseCase(nhentaiGateway: FakeNhentaiGateway()),
    ),
    ChangeNotifierProvider<DownloadManagerModel>.value(value: model),
    ChangeNotifierProvider<BlockedTagsModel>(
      create: (_) => BlockedTagsModel(
        blockedTagsRepository: FakeBlockedTagsRepository(),
      ),
    ),
    if (controller != null)
      Provider<HomeShellController>.value(value: controller),
  ];

  final router = GoRouter(
    initialLocation: '/index',
    routes: <RouteBase>[
      GoRoute(
        name: 'index',
        path: '/index',
        builder: (context, state) {
          return Scaffold(
            body: CustomScrollView(
              slivers: <Widget>[
                DownloadJobListSliver(
                  searchQuery: searchQuery,
                  onOpenOfflineReader: onOpenOfflineReader ?? (_) {},
                ),
              ],
            ),
          );
        },
      ),
    ],
  );

  return MultiProvider(
    providers: providers,
    child: MaterialApp.router(routerConfig: router),
  );
}

DownloadJobSnapshot _job({
  required String comicId,
  required String title,
  required DownloadJobStatus status,
  required DateTime requestedAt,
}) {
  return DownloadJobSnapshot(
    comicId: comicId,
    mediaId: comicId,
    title: title,
    thumbnailPath: null,
    status: status,
    totalPages: 10,
    completedPages: status == DownloadJobStatus.completed ? 10 : 3,
    nextPageNumber: 4,
    requestedAt: requestedAt,
    updatedAt: requestedAt,
  );
}

DownloadListItemSnapshot _itemFromJob({
  required String comicId,
  required String title,
  required DownloadJobStatus status,
  required DateTime requestedAt,
  DateTime? downloadedAt,
}) {
  return DownloadListItemSnapshot.fromJob(
    _job(
      comicId: comicId,
      title: title,
      status: status,
      requestedAt: requestedAt,
    ),
    downloadedComic: status == DownloadJobStatus.completed
        ? DownloadedComicSnapshot(
            comicId: comicId,
            mediaId: comicId,
            title: title,
            coverLocalPath: null,
            rootDirectoryPath: '/downloads/$comicId',
            pageCount: 10,
            downloadedAt: downloadedAt ?? requestedAt,
            tags: sampleComic().tags,
          )
        : null,
  );
}

DownloadListItemSnapshot _itemFromDownloadedComic({
  required String comicId,
  required String title,
  required DateTime requestedAt,
  List<ComicTag>? tags,
}) {
  return DownloadListItemSnapshot.fromDownloadedComic(
    DownloadedComicSnapshot(
      comicId: comicId,
      mediaId: comicId,
      title: title,
      coverLocalPath: null,
      rootDirectoryPath: '/downloads/$comicId',
      pageCount: 2,
      downloadedAt: requestedAt,
      tags: tags ?? sampleComic().tags,
    ),
  );
}

class _FakeDownloadManagerModel extends DownloadManagerModel {
  _FakeDownloadManagerModel({
    required this.harness,
    required this.itemsOverride,
    this.repairAllResult = (
      repairedCount: 0,
      failedCount: 0,
      totalCount: 0,
      stoppedEarly: false,
    ),
  }) : super(
         nhentaiGateway: FakeNhentaiGateway(),
         cdnConfigService: NhentaiCdnConfigService(),
         downloadQueueRepository: harness.downloadQueueRepository,
         downloadedLibraryRepository: harness.downloadedLibraryRepository,
         downloadSettingsRepository: _FakeDownloadSettingsRepository(),
         downloadAssetStore: DownloadAssetStore(
           directoryResolver: () async => throw UnimplementedError(),
         ),
         imageCompressionService: FakeImageCompressionService(),
         remoteAssetFetcher: FakeRemoteAssetFetcher(),
       );

  final SqliteTestHarness harness;
  final List<DownloadListItemSnapshot> itemsOverride;
  final ({int repairedCount, int failedCount, int totalCount, bool stoppedEarly})
  repairAllResult;

  @override
  Future<({int repairedCount, int failedCount, int totalCount, bool stoppedEarly})>
  repairAllCompleted({void Function(int processed, int total)? onProgress}) async =>
      repairAllResult;

  @override
  List<DownloadJobSnapshot> get jobs => itemsOverride
      .map(
        (item) => _job(
          comicId: item.comicId,
          title: item.title,
          status: item.status,
          requestedAt: item.requestedAt,
        ),
      )
      .toList(growable: false);

  @override
  List<DownloadListItemSnapshot> get downloadItems => itemsOverride;

  @override
  DownloadsSortMode get downloadsSortMode => DownloadsSortMode.latestDownloaded;

  @override
  List<DownloadListItemSnapshot> get sortedDownloadItems {
    final activeItems =
        itemsOverride
            .where((item) => !item.isCompletedCard)
            .toList(growable: false)
          ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    final completedItems =
        itemsOverride
            .where((item) => item.isCompletedCard)
            .toList(growable: false)
          ..sort(
            (a, b) => (b.downloadedAt ?? b.updatedAt).compareTo(
              a.downloadedAt ?? a.updatedAt,
            ),
          );
    return <DownloadListItemSnapshot>[...activeItems, ...completedItems];
  }

  @override
  Future<void> refresh() async {}

  @override
  bool isMutating(String comicId) => false;

  @override
  Future<String?> loadCoverLocalPath(String comicId) async => null;
}

class _FakeHomeShellController extends HomeShellController {
  _FakeHomeShellController({required SqliteTestHarness harness})
    : super(
        searchHistoryRepository: harness.searchHistoryRepository,
        homeUiModel: HomeUiModel(),
        feedModel: ComicFeedModel(
          searchComicsUseCase: SearchComicsUseCase(
            nhentaiGateway: FakeNhentaiGateway(),
            searchQueryBuilder: const SearchQueryBuilder(),
          ),
          loadCollectionSummariesUseCase: LoadCollectionSummariesUseCase(
            collectionRepository: harness.collectionRepository,
          ),
          blockedTagsRepository: FakeBlockedTagsRepository(),
        ),
        readerModel: ComicReaderModel(
          loadComicDetailUseCase: LoadComicDetailUseCase(
            nhentaiGateway: FakeNhentaiGateway(detailComic: sampleComic()),
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
        ),
        tagSearchQueryBuilder: const TagSearchQueryBuilder(),
      );

  final List<String> submittedTagQueries = <String>[];

  @override
  Future<void> submitTagSearch(Iterable<String> tagQueries) async {
    submittedTagQueries.addAll(tagQueries);
  }
}

class _FakeDownloadSettingsRepository implements DownloadSettingsRepository {
  @override
  Future<bool> loadAutoResumeEnabled() async => false;

  @override
  Future<void> saveAutoResumeEnabled(bool enabled) async {}

  @override
  Future<int> loadPageIntervalMs() async => 500;

  @override
  Future<void> savePageIntervalMs(int milliseconds) async {}
}
