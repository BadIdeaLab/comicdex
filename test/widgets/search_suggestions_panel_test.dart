import 'package:concept_nhv/application/feed/load_collection_summaries_use_case.dart';
import 'package:concept_nhv/application/feed/search_comics_use_case.dart';
import 'package:concept_nhv/application/home/home_shell_controller.dart';
import 'package:concept_nhv/application/reader/load_comic_detail_use_case.dart';
import 'package:concept_nhv/application/reader/load_offline_comic_use_case.dart';
import 'package:concept_nhv/application/reader/open_comic_use_case.dart';
import 'package:concept_nhv/models/local_tag_catalog_entry.dart';
import 'package:concept_nhv/models/tag_catalog_type.dart';
import 'package:concept_nhv/services/download_asset_store.dart';
import 'package:concept_nhv/services/local_tag_catalog_service.dart';
import 'package:concept_nhv/services/search_query_builder.dart';
import 'package:concept_nhv/services/tag_display_service.dart';
import 'package:concept_nhv/services/tag_search_query_builder.dart';
import 'package:concept_nhv/state/comic_feed_model.dart';
import 'package:concept_nhv/state/comic_reader_model.dart';
import 'package:concept_nhv/state/home_ui_model.dart';
import 'package:concept_nhv/state/tag_catalog_browser_model.dart';
import 'package:concept_nhv/storage/options_store.dart';
import 'package:concept_nhv/storage/reader_progress_store.dart';
import 'package:concept_nhv/widgets/search_suggestions_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../test_support/fakes/fake_blocked_tags_repository.dart';
import '../test_support/fakes/fake_nhentai_gateway.dart';
import '../test_support/fakes/fake_reader_settings_repository.dart';
import '../test_support/fixtures/sample_comic.dart';
import '../test_support/storage/sqlite_test_harness.dart';

void main() {
  testWidgets(
    'submits selected tag catalog queries without extra overlay cleanup',
    (tester) async {
      final setup = await _pumpSearchSuggestionsPanel(
        tester,
        catalogEntries: const <LocalTagCatalogEntry>[
          LocalTagCatalogEntry(
            type: TagCatalogType.tag,
            name: 'full color',
            slug: 'full-color',
            count: 10,
          ),
        ],
      );

      await tester.tap(find.text('Tags').last);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.ensureVisible(
        find.widgetWithText(FilterChip, 'full color (10)'),
      );
      await tester.tap(find.widgetWithText(FilterChip, 'full color (10)'));
      await tester.pump();
      expect(find.text('Selected 1'), findsOneWidget);
      expect(find.widgetWithText(InputChip, 'tag:full-color'), findsOneWidget);

      await tester.tap(find.text('Search 1 tags'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final history = await setup.harness.searchHistoryRepository.load();
      expect(history.first.query, 'tag:full-color');
      expect(setup.homeUiModel.searchController.text, 'tag:full-color');
      expect(
        setup.gateway.searchedUris.single.queryParameters['query'],
        'tag:full-color language:chinese',
      );
    },
  );

  testWidgets(
    'searches the whole category instantly without hiding selection summary',
    (tester) async {
      await _pumpSearchSuggestionsPanel(
        tester,
        catalogEntries: const <LocalTagCatalogEntry>[
          LocalTagCatalogEntry(
            type: TagCatalogType.tag,
            name: 'full color',
            slug: 'full-color',
            count: 10,
          ),
          LocalTagCatalogEntry(
            type: TagCatalogType.tag,
            name: 'big breasts',
            slug: 'big-breasts',
            count: 20,
          ),
        ],
      );

      await tester.tap(find.text('Tags').last);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.widgetWithText(FilterChip, 'full color (10)'));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'breasts');
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.widgetWithText(FilterChip, 'full color (10)'), findsNothing);
      expect(find.widgetWithText(FilterChip, 'big breasts (20)'), findsOneWidget);
      expect(find.text('Selected 1'), findsOneWidget);
      expect(find.widgetWithText(InputChip, 'tag:full-color'), findsOneWidget);
    },
  );
}

Future<
  ({
    SqliteTestHarness harness,
    FakeNhentaiGateway gateway,
    HomeUiModel homeUiModel,
  })
>
_pumpSearchSuggestionsPanel(
  WidgetTester tester, {
  required List<LocalTagCatalogEntry> catalogEntries,
}) async {
  final harness = SqliteTestHarness();
  await harness.initialize();
  addTearDown(harness.dispose);

  final gateway = FakeNhentaiGateway();
  final homeUiModel = HomeUiModel();
  addTearDown(homeUiModel.searchController.dispose);
  addTearDown(homeUiModel.dispose);

  final feedModel = ComicFeedModel(
    searchComicsUseCase: SearchComicsUseCase(
      nhentaiGateway: gateway,
      searchQueryBuilder: const SearchQueryBuilder(),
    ),
    loadCollectionSummariesUseCase: LoadCollectionSummariesUseCase(
      collectionRepository: harness.collectionRepository,
    ),
    blockedTagsRepository: FakeBlockedTagsRepository(),
  );
  addTearDown(feedModel.dispose);

  final readerModel = ComicReaderModel(
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
  );
  addTearDown(readerModel.dispose);

  final tagDisplayService = TagDisplayService.fromMap({});
  final localTagCatalogService = LocalTagCatalogService.fromEntries(
    catalogEntries,
  );
  final tagCatalogModel = TagCatalogBrowserModel(
    localTagCatalogService: localTagCatalogService,
    tagDisplayService: tagDisplayService,
  );
  addTearDown(tagCatalogModel.dispose);

  final providers = <SingleChildWidget>[
    Provider<TagDisplayService>.value(value: tagDisplayService),
    Provider.value(value: harness.searchHistoryRepository),
    ChangeNotifierProvider<HomeUiModel>.value(value: homeUiModel),
    ChangeNotifierProvider<TagCatalogBrowserModel>.value(
      value: tagCatalogModel,
    ),
    Provider<HomeShellController>(
      create: (_) => HomeShellController(
        searchHistoryRepository: harness.searchHistoryRepository,
        homeUiModel: homeUiModel,
        feedModel: feedModel,
        readerModel: readerModel,
        tagSearchQueryBuilder: const TagSearchQueryBuilder(),
      ),
    ),
  ];

  await tester.pumpWidget(
    MultiProvider(
      providers: providers,
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 500,
            child: SearchSuggestionsPanel(onHistorySelected: (_) {}),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));

  return (harness: harness, gateway: gateway, homeUiModel: homeUiModel);
}
