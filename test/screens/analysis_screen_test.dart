import 'package:concept_nhv/application/tags/load_tag_cooccurrence_use_case.dart';
import 'package:concept_nhv/application/tags/load_tag_coverage_use_case.dart';
import 'package:concept_nhv/application/tags/load_tag_preferences_use_case.dart';
import 'package:concept_nhv/models/collection_type.dart';
import 'package:concept_nhv/models/local_tag_catalog_entry.dart';
import 'package:concept_nhv/models/tag_catalog_type.dart';
import 'package:concept_nhv/screens/analysis_screen.dart';
import 'package:concept_nhv/services/local_tag_catalog_service.dart';
import 'package:concept_nhv/services/tag_display_service.dart';
import 'package:concept_nhv/state/blocked_tags_model.dart';
import 'package:concept_nhv/state/home_ui_model.dart';
import 'package:concept_nhv/state/tag_preference_model.dart';
import 'package:concept_nhv/storage/options_store.dart';
import 'package:concept_nhv/storage/tag_preference_store.dart';
import 'package:concept_nhv/application/feed/load_collection_summaries_use_case.dart';
import 'package:concept_nhv/application/feed/search_comics_use_case.dart';
import 'package:concept_nhv/application/home/home_shell_controller.dart';
import 'package:concept_nhv/services/search_query_builder.dart';
import 'package:concept_nhv/services/tag_search_query_builder.dart';
import 'package:concept_nhv/state/comic_feed_model.dart';
import 'package:concept_nhv/storage/search_history_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../test_support/fakes/fake_blocked_tags_repository.dart';
import '../test_support/fakes/fake_nhentai_gateway.dart';
import '../test_support/storage/sqlite_test_harness.dart';

void main() {
  late SqliteTestHarness harness;

  const catalog = <LocalTagCatalogEntry>[
    LocalTagCatalogEntry(
      id: 10,
      type: TagCatalogType.tag,
      name: 'full color',
      slug: 'full-color',
      count: 1000,
    ),
    LocalTagCatalogEntry(
      id: 11,
      type: TagCatalogType.tag,
      name: 'schoolgirl',
      slug: 'schoolgirl',
      count: 1000,
    ),
  ];

  TagPreferenceModel buildModel() => TagPreferenceModel(
    loadTagPreferencesUseCase: LoadTagPreferencesUseCase(
      comicTagRepository: harness.comicTagRepository,
      localTagCatalogService: LocalTagCatalogService.fromEntries(catalog),
      blockedTagsRepository: FakeBlockedTagsRepository(),
    ),
    loadTagCooccurrenceUseCase: LoadTagCooccurrenceUseCase(
      comicTagRepository: harness.comicTagRepository,
      localTagCatalogService: LocalTagCatalogService.fromEntries(catalog),
      blockedTagsRepository: FakeBlockedTagsRepository(),
    ),
    loadTagCoverageUseCase: LoadTagCoverageUseCase(
      comicTagRepository: harness.comicTagRepository,
    ),
    tagPreferenceStore: TagPreferenceStore(
      optionsStore: OptionsStore(localDatabase: harness.localDatabase),
    ),
  );

  Future<void> keep(String comicId, List<int> tagIds) async {
    await harness.comicTagRepository.replaceTagIds(comicId, tagIds);
    await harness.collectionRepository.addComicToCollection(
      collectionType: CollectionType.favorite,
      comicId: comicId,
    );
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    final model = buildModel();
    addTearDown(model.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: <SingleChildWidget>[
          ChangeNotifierProvider<TagPreferenceModel>.value(value: model),
          ChangeNotifierProvider<BlockedTagsModel>(
            create: (_) => BlockedTagsModel(
              blockedTagsRepository: FakeBlockedTagsRepository(),
            ),
          ),
          ChangeNotifierProvider<HomeUiModel>(create: (_) => HomeUiModel()),
          Provider<TagDisplayService>.value(
            value: TagDisplayService.fromMap(const <String, String>{
              'full-color': '全彩',
            }),
          ),
        ],
        child: const MaterialApp(home: AnalysisScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() async {
    harness = SqliteTestHarness();
    await harness.initialize();
  });

  tearDown(() async {
    await harness.dispose();
  });

  testWidgets('shows coverage, the ranking and the taste combinations', (
    tester,
  ) async {
    for (var i = 0; i < 6; i++) {
      await keep('paired-$i', <int>[10, 11]);
    }
    // Kept but untagged, so coverage is 6 of 7.
    await harness.collectionRepository.addComicToCollection(
      collectionType: CollectionType.favorite,
      comicId: 'untagged',
    );

    await pumpScreen(tester);

    expect(find.text('7 comics kept'), findsOneWidget);
    expect(find.text('6 of them carry tags (86%)'), findsOneWidget);
    expect(find.textContaining('Sync favorites from Settings'), findsOneWidget);
    expect(find.text('Taste Combinations'), findsOneWidget);
    expect(find.text('全彩 + schoolgirl'), findsOneWidget);
    // The full ranking, with no "Show more" expander on this page.
    expect(find.text('全彩'), findsOneWidget);
    expect(find.textContaining('Show '), findsNothing);
  });

  testWidgets('a full-coverage library gets no sync nudge', (tester) async {
    for (var i = 0; i < 6; i++) {
      await keep('paired-$i', <int>[10, 11]);
    }

    await pumpScreen(tester);

    expect(find.text('6 of them carry tags (100%)'), findsOneWidget);
    expect(find.textContaining('Sync favorites from Settings'), findsNothing);
  });

  testWidgets('an empty library says so instead of showing zeroes', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.textContaining('Nothing kept yet'), findsOneWidget);
    expect(find.text('Taste Combinations'), findsNothing);
  });

  /// Pumps the analysis page inside a router with a stand-in home route, so
  /// a test can tell "the action ran" from "the page got out of the way".
  Future<HomeUiModel> pumpRoutedScreen(WidgetTester tester) async {
    final model = buildModel();
    addTearDown(model.dispose);
    final homeUiModel = HomeUiModel();
    addTearDown(homeUiModel.dispose);
    final feedModel = ComicFeedModel(
      searchComicsUseCase: SearchComicsUseCase(
        nhentaiGateway: FakeNhentaiGateway(),
        searchQueryBuilder: const SearchQueryBuilder(),
      ),
      loadCollectionSummariesUseCase: LoadCollectionSummariesUseCase(
        collectionRepository: harness.collectionRepository,
      ),
      blockedTagsRepository: FakeBlockedTagsRepository(),
    );
    addTearDown(feedModel.dispose);
    final router = GoRouter(
      initialLocation: '/analysis',
      routes: <RouteBase>[
        GoRoute(
          name: 'index',
          path: '/index',
          builder: (context, state) => const Scaffold(body: Text('home')),
        ),
        GoRoute(
          path: '/analysis',
          builder: (context, state) => const AnalysisScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: <SingleChildWidget>[
          ChangeNotifierProvider<TagPreferenceModel>.value(value: model),
          ChangeNotifierProvider<HomeUiModel>.value(value: homeUiModel),
          ChangeNotifierProvider<ComicFeedModel>.value(value: feedModel),
          ChangeNotifierProvider<BlockedTagsModel>(
            create: (_) => BlockedTagsModel(
              blockedTagsRepository: FakeBlockedTagsRepository(),
            ),
          ),
          Provider<HomeShellController>(
            create: (_) => HomeShellController(
              searchHistoryRepository: SearchHistoryRepository(
                localDatabase: harness.localDatabase,
              ),
              homeUiModel: homeUiModel,
              feedModel: feedModel,
              tagSearchQueryBuilder: const TagSearchQueryBuilder(),
            ),
          ),
          Provider<TagDisplayService>.value(
            value: TagDisplayService.fromMap(const <String, String>{
              'full-color': '全彩',
            }),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return homeUiModel;
  }

  testWidgets('long-pressing a tag filters Downloads by its id', (
    tester,
  ) async {
    for (var i = 0; i < 6; i++) {
      await keep('paired-$i', <int>[10, 11]);
    }

    final homeUiModel = await pumpRoutedScreen(tester);

    await tester.longPress(find.text('全彩'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Filter Downloads by "全彩"'));
    await tester.pumpAndSettle();

    // Same trap as the tap-to-search fix: setting the filter alone leaves the
    // analysis page on screen, so the action appears to do nothing.
    expect(homeUiModel.downloadsTagIds, <int>[10]);
    expect(homeUiModel.navigationIndex, 1);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('long-pressing a combination filters Downloads by its tags', (
    tester,
  ) async {
    for (var i = 0; i < 6; i++) {
      await keep('paired-$i', <int>[10, 11]);
    }

    final homeUiModel = await pumpRoutedScreen(tester);

    await tester.longPress(find.text('全彩 + schoolgirl'));
    await tester.pumpAndSettle();

    expect(homeUiModel.downloadsTagIds, <int>[10, 11]);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('tapping a pair searches both tags and returns to home', (
    tester,
  ) async {
    for (var i = 0; i < 6; i++) {
      await keep('paired-$i', <int>[10, 11]);
    }

    final homeUiModel = await pumpRoutedScreen(tester);

    await tester.tap(find.text('全彩 + schoolgirl'));
    await tester.pumpAndSettle();

    // Both halves matter: the search runs, and the page gets out of the way.
    // Submitting alone only switched the tab behind this page (P81 fix).
    expect(homeUiModel.searchController.text, contains('tag:full-color'));
    expect(homeUiModel.searchController.text, contains('tag:schoolgirl'));
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('the combinations header fits a phone', (tester) async {
    // Same overflow the ranking header had: the sort toggle plus a title do
    // not fit one row at phone width.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    for (var i = 0; i < 6; i++) {
      await keep('paired-$i', <int>[10, 11]);
    }

    await pumpScreen(tester);

    expect(find.text('Taste Combinations'), findsOneWidget);
    expect(find.text('Most distinctive'), findsWidgets);
    expect(find.text('全彩 + schoolgirl'), findsOneWidget);
  });
}
