import 'package:concept_nhv/application/feed/load_collection_summaries_use_case.dart';
import 'package:concept_nhv/application/feed/search_comics_use_case.dart';
import 'package:concept_nhv/application/home/app_shell_navigation_controller.dart';
import 'package:concept_nhv/models/popular_sort_type.dart';
import 'package:concept_nhv/services/search_query_builder.dart';
import 'package:concept_nhv/state/comic_feed_model.dart';
import 'package:concept_nhv/state/home_ui_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_support/fakes/fake_blocked_tags_repository.dart';
import '../test_support/fakes/fake_nhentai_gateway.dart';
import '../test_support/storage/sqlite_test_harness.dart';

void main() {
  group('AppShellNavigationController', () {
    late SqliteTestHarness harness;
    late HomeUiModel homeUiModel;
    late ComicFeedModel feedModel;
    late FakeNhentaiGateway gateway;
    late AppShellNavigationController controller;

    setUp(() async {
      harness = SqliteTestHarness();
      await harness.initialize();
      homeUiModel = HomeUiModel();
      gateway = FakeNhentaiGateway();
      feedModel = ComicFeedModel(
        searchComicsUseCase: SearchComicsUseCase(
          nhentaiGateway: gateway,
          searchQueryBuilder: const SearchQueryBuilder(),
        ),
        loadCollectionSummariesUseCase: LoadCollectionSummariesUseCase(
          collectionRepository: harness.collectionRepository,
        ),
        blockedTagsRepository: FakeBlockedTagsRepository(),
      );
      controller = AppShellNavigationController(
        homeUiModel: homeUiModel,
        feedModel: feedModel,
      );
    });

    tearDown(() async {
      homeUiModel.searchController.dispose();
      homeUiModel.dispose();
      feedModel.dispose();
      await harness.dispose();
    });

    test('loads home feed and keeps index navigation selected', () async {
      final result = await controller.handleDestinationSelected(0);

      expect(homeUiModel.navigationIndex, 0);
      expect(homeUiModel.isLoading, isFalse);
      expect(feedModel.comicsLoaded, greaterThan(0));
      expect(result.statusMessage, isNull);
    });

    test('keeps the search query across a tab switch', () async {
      // Asserted here rather than on HomeUiModel alone: every switch goes
      // through this controller, and its resetSearchView() call used to clear
      // the query before HomeUiModel ever got to decide.
      homeUiModel.searchController.text = 'artist:someone';

      await controller.handleDestinationSelected(1);
      await controller.handleDestinationSelected(0);

      expect(homeUiModel.searchController.text, 'artist:someone');
    });

    test('clears the search query when tapping Home while on Home', () async {
      homeUiModel.searchController.text = 'artist:someone';

      await controller.handleDestinationSelected(0);

      expect(homeUiModel.searchController.text, isEmpty);
    });

    test('does not refetch when returning to home with results in hand', () async {
      // The reported symptom: every trip back to Home re-ran the search and
      // dropped the reader at the top, discarding everything already paged in.
      await controller.handleDestinationSelected(0);
      final searchesAfterFirstLoad = gateway.searchedUris.length;
      final loadedAfterFirstLoad = feedModel.comicsLoaded;

      await controller.handleDestinationSelected(1);
      await controller.handleDestinationSelected(0);

      expect(gateway.searchedUris.length, searchesAfterFirstLoad);
      expect(feedModel.comicsLoaded, loadedAfterFirstLoad);
      expect(homeUiModel.navigationIndex, 0);
    });

    test('loads on return when there is still nothing to show', () async {
      // An empty feed means the first load never succeeded, so coming back has
      // to try again — otherwise a failed start leaves Home blank for good.
      expect(feedModel.comics, isNull);

      await controller.handleDestinationSelected(1);
      await controller.handleDestinationSelected(0);

      expect(gateway.searchedUris, isNotEmpty);
      expect(feedModel.comicsLoaded, greaterThan(0));
    });

    test('refreshes collection summaries when opening collection tabs', () async {
      final result = await controller.handleDestinationSelected(2);

      expect(homeUiModel.navigationIndex, 2);
      expect(feedModel.collectionSummariesFuture, isNotNull);
      expect(result.statusMessage, isNull);
    });

    test('switches to downloads without refreshing collection summaries', () async {
      final result = await controller.handleDestinationSelected(1);

      expect(homeUiModel.navigationIndex, 1);
      expect(feedModel.collectionSummariesFuture, isNull);
      expect(result.statusMessage, isNull);
    });

    test('returns a sort snackbar message when the sort state changes', () async {
      final result = await controller.toggleSortAndRefresh(
        PopularSortType.month,
      );

      expect(result.sortMessage, 'Sort by popular type: This month');
      expect(feedModel.sortByPopularType, PopularSortType.month);
      expect(homeUiModel.isLoading, isFalse);
    });
  });
}
