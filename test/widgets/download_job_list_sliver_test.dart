import 'package:concept_nhv/application/downloads/download_settings_repository.dart';
import 'package:concept_nhv/application/feed/load_collection_summaries_use_case.dart';
import 'package:concept_nhv/application/feed/search_comics_use_case.dart';
import 'package:concept_nhv/application/tags/load_comic_meta_use_case.dart';
import 'package:concept_nhv/application/home/home_shell_controller.dart';
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
import 'package:concept_nhv/state/download_manager_model.dart';
import 'package:concept_nhv/state/home_ui_model.dart';
import 'package:concept_nhv/widgets/download_job_list_sliver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../test_support/fakes/fake_blocked_tags_repository.dart';
import '../test_support/fakes/fake_image_compression_service.dart';
import '../test_support/fakes/fake_nhentai_gateway.dart';
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
        await tester.pumpAndSettle();

        // Rebuilding the tree must not put us back in list view: the choice
        // belongs to the model now, precisely so leaving the tab and coming
        // back does not forget it.
        expect(find.byIcon(Icons.list), findsOneWidget);

        await tester.tap(find.text('Downloaded Comic'));
        await tester.pumpAndSettle();
        expect(opened, isTrue);

        // Toggle back to list view.
        await tester.tap(find.byIcon(Icons.list));
        await tester.pumpAndSettle();
        expect(find.text('Completed'), findsOneWidget);
      },
    );

    testWidgets('filters by the label the tag sheet writes', (tester) async {
      // The two halves of this feature sit in different files: the tag sheet
      // writes a string, this list interprets it. Writing the tag's
      // `type:slug` query instead of its label would still satisfy the sheet's
      // own test while matching nothing here, so the handover needs asserting
      // from this side too.
      final homeUiModel = HomeUiModel();
      addTearDown(homeUiModel.dispose);
      homeUiModel.searchInDownloads('全彩');

      final model = _FakeDownloadManagerModel(
        harness: harness,
        itemsOverride: <DownloadListItemSnapshot>[
          _itemFromDownloadedComic(
            comicId: 'colored',
            title: 'Colored Comic',
            requestedAt: DateTime(2026, 4, 10),
            tags: <ComicTag>[
              ComicTag(type: 'tag', name: 'full-color', url: '/tag/full-color/'),
            ],
          ),
          _itemFromDownloadedComic(
            comicId: 'plain',
            title: 'Plain Comic',
            requestedAt: DateTime(2026, 4, 11),
            tags: const <ComicTag>[],
          ),
        ],
      );

      await tester.pumpWidget(
        _buildTestWidget(
          model: model,
          searchQuery: homeUiModel.downloadsSearchQuery,
          tagDisplayMap: const <String, String>{'full-color': '全彩'},
        ),
      );
      await tester.pump();

      expect(find.text('Colored Comic'), findsOneWidget);
      expect(find.text('Plain Comic'), findsNothing);
    });

    testWidgets('shows the stored favorite count for a completed download', (
      tester,
    ) async {
      // The count is written at download time and sat unused: the sheet skips
      // loading when tags are already stored, so nothing ever put it on
      // screen — offline or not.
      final model = _FakeDownloadManagerModel(
        harness: harness,
        itemsOverride: <DownloadListItemSnapshot>[
          _itemFromDownloadedComic(
            comicId: 'completed',
            title: 'Downloaded Comic',
            requestedAt: DateTime(2026, 4, 10),
            numFavorites: 4821,
          ),
        ],
      );

      await tester.pumpWidget(
        _buildTestWidget(
          model: model,
          controller: _FakeHomeShellController(harness: harness),
        ),
      );
      await tester.pump();

      await tester.longPress(find.text('Downloaded Comic'));
      await tester.pumpAndSettle();

      expect(find.text('4.8k'), findsOneWidget);
    });

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

    testWidgets(
      'scrolling to the end of the current page auto-reveals the next '
      'page (list view), with no loading snackbar',
      (tester) async {
        final model = _FakeDownloadManagerModel(
          harness: harness,
          itemsOverride: _manyCompletedItems(35),
        );

        await tester.pumpWidget(_buildTestWidget(model: model));
        await tester.pump();

        expect(find.text('Completed 0'), findsOneWidget);
        expect(find.text('Completed 30'), findsNothing);

        await _scrollUntilVisible(tester, find.text('Completed 30'));

        expect(find.text('Completed 30'), findsOneWidget);
        expect(find.byType(SnackBar), findsNothing);
      },
    );

    testWidgets(
      'scrolling to the end of the current page auto-reveals the next '
      'page (grid view)',
      (tester) async {
        final model = _FakeDownloadManagerModel(
          harness: harness,
          itemsOverride: _manyCompletedItems(35),
        );

        await tester.pumpWidget(_buildTestWidget(model: model));
        await tester.pump();
        await tester.tap(find.byIcon(Icons.grid_view));
        await tester.pumpAndSettle();

        expect(find.text('Completed 0'), findsOneWidget);
        expect(find.text('Completed 30'), findsNothing);

        await _scrollUntilVisible(tester, find.text('Completed 30'));

        expect(find.text('Completed 30'), findsOneWidget);
      },
    );

    testWidgets(
      'jumping to a page shows only that page, and scrolling further '
      'keeps auto-loading forward pages',
      (tester) async {
        final model = _FakeDownloadManagerModel(
          harness: harness,
          itemsOverride: _manyCompletedItems(65),
        );

        await tester.pumpWidget(_buildTestWidget(model: model));
        await tester.pump();

        await tester.enterText(find.byType(TextField), '2');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        expect(find.text('Completed 0'), findsNothing);
        expect(find.text('Completed 30'), findsOneWidget);
        expect(find.text('Completed 60'), findsNothing);

        await _scrollUntilVisible(tester, find.text('Completed 60'));

        expect(find.text('Completed 60'), findsOneWidget);
      },
    );
  });
}

/// Drags [CustomScrollView] downward in small steps, pumping between each
/// step, until [finder] resolves — used instead of [WidgetController]'s
/// built-in `scrollUntilVisible`/`dragUntilVisible`, which throws "No
/// element" against this widget tree.
Future<void> _scrollUntilVisible(
  WidgetTester tester,
  Finder finder, {
  double delta = -300,
  int maxTries = 40,
}) async {
  for (var i = 0; i < maxTries; i++) {
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await tester.drag(find.byType(CustomScrollView), Offset(0, delta));
    await tester.pump();
  }
  expect(finder, findsOneWidget);
}

List<DownloadListItemSnapshot> _manyCompletedItems(int count) {
  return List<DownloadListItemSnapshot>.generate(
    count,
    (index) => _itemFromDownloadedComic(
      comicId: 'completed-$index',
      title: 'Completed $index',
      requestedAt: DateTime(2026, 4, 1).subtract(Duration(days: index)),
    ),
  );
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
  int? numFavorites,
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
      numFavorites: numFavorites,
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

  bool completedViewIsGrid = false;

  @override
  Future<bool> loadCompletedViewIsGrid() async => completedViewIsGrid;

  @override
  Future<void> saveCompletedViewIsGrid(bool isGrid) async {
    completedViewIsGrid = isGrid;
  }
}
