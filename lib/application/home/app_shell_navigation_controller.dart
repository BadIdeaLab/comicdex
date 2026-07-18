import 'package:concept_nhv/models/popular_sort_type.dart';
import 'package:concept_nhv/state/comic_feed_model.dart';
import 'package:concept_nhv/state/home_ui_model.dart';

import 'app_shell_navigation_result.dart';

class AppShellNavigationController {
  const AppShellNavigationController({
    required this.homeUiModel,
    required this.feedModel,
  });

  final HomeUiModel homeUiModel;
  final ComicFeedModel feedModel;

  Future<AppShellNavigationResult> handleDestinationSelected(int index) async {
    homeUiModel.resetSearchView();

    switch (index) {
      case 0:
        homeUiModel.setNavigationIndex(index);
        homeUiModel.setLoading(true);
        final statusCode = await feedModel.loadHomeFeed(clearComic: true);
        homeUiModel.setLoading(false);
        return AppShellNavigationResult(
          statusMessage: _statusMessageFromCode(statusCode),
        );
      case 1:
        homeUiModel.setNavigationIndex(index);
        return const AppShellNavigationResult();
      case 2:
        homeUiModel.setNavigationIndex(index);
        feedModel.refreshCollections();
        return const AppShellNavigationResult();
      default:
        return const AppShellNavigationResult();
    }
  }

  Future<AppShellNavigationResult> toggleSortAndRefresh(
    PopularSortType type,
  ) async {
    final previous = feedModel.sortByPopularType;
    feedModel.toggleSort(type);

    final current = feedModel.sortByPopularType;
    final sortMessage = current != previous
        ? 'Sort by popular type: ${current?.label ?? 'None'}'
        : null;

    homeUiModel.setLoading(true);
    await feedModel.fetchNextPage(page: 1);
    homeUiModel.setLoading(false);

    return AppShellNavigationResult(sortMessage: sortMessage);
  }

  String? _statusMessageFromCode(int? statusCode) {
    if (statusCode == 404) {
      return 'API issue (404)';
    }
    if (statusCode == 403) {
      return 'Authentication issue (403)';
    }
    return null;
  }
}
