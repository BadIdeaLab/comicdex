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
    late AppShellNavigationController controller;

    setUp(() async {
      harness = SqliteTestHarness();
      await harness.initialize();
      homeUiModel = HomeUiModel();
      feedModel = ComicFeedModel(
        searchComicsUseCase: SearchComicsUseCase(
          nhentaiGateway: FakeNhentaiGateway(),
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
