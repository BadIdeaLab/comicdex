import 'package:concept_nhv/state/comic_feed_model.dart';
import 'package:concept_nhv/state/comic_reader_model.dart';
import 'package:concept_nhv/state/home_ui_model.dart';
import 'package:concept_nhv/storage/search_history_repository.dart';
import 'package:concept_nhv/services/tag_search_query_builder.dart';
import 'package:concept_nhv/models/comic_language.dart';

import 'home_search_action_result.dart';

class HomeShellController {
  const HomeShellController({
    required this.searchHistoryRepository,
    required this.homeUiModel,
    required this.feedModel,
    required this.readerModel,
    required this.tagSearchQueryBuilder,
  });

  final SearchHistoryRepository searchHistoryRepository;
  final HomeUiModel homeUiModel;
  final ComicFeedModel feedModel;
  final ComicReaderModel readerModel;
  final TagSearchQueryBuilder tagSearchQueryBuilder;

  Future<HomeSearchActionResult> submitSearch(String value) async {
    await searchHistoryRepository.save(value);

    if (int.tryParse(value) != null) {
      await readerModel.loadComicDetail(value);
      return HomeSearchActionResult(openComicReader: true, comicId: value);
    }

    homeUiModel.closeSearchView(value);
    if (homeUiModel.navigationIndex != 0) {
      homeUiModel.setNavigationIndex(0);
    }

    homeUiModel.setLoading(true);
    await feedModel.searchComics(query: value, clearComic: true);
    homeUiModel.setLoading(false);
    return const HomeSearchActionResult(openComicReader: false);
  }

  Future<int?> retryHomeFeed() async {
    homeUiModel.setLoading(true);
    final statusCode = await feedModel.loadHomeFeed(clearComic: true);
    homeUiModel.setLoading(false);
    return statusCode;
  }

  /// Navigates to the home tab and searches using a tag query
  /// (e.g. "tag:full-color"). Does not save to search history since
  /// the user triggered this from a tag chip rather than a text input.
  Future<void> searchWithTag(String tagQuery) async {
    await submitTagSearch(<String>[tagQuery]);
  }

  Future<void> submitTagSearch(Iterable<String> tagQueries) async {
    final normalizedQueries = tagQueries
        .map((query) => query.trim().toLowerCase())
        .where((query) => query.isNotEmpty)
        .toList(growable: false);
    final query = tagSearchQueryBuilder.build(normalizedQueries);
    if (query.isEmpty) {
      return;
    }
    final containsExplicitLanguage = normalizedQueries.any(
      (query) => query.startsWith('language:'),
    );

    await searchHistoryRepository.save(query);
    homeUiModel.closeSearchView(query);
    if (homeUiModel.navigationIndex != 0) {
      homeUiModel.setNavigationIndex(0);
    }

    homeUiModel.setLoading(true);
    await feedModel.searchComics(
      query: query,
      clearComic: true,
      includeTagFilters: false,
      languageOverride:
          containsExplicitLanguage ? ComicLanguage.all : null,
    );
    homeUiModel.setLoading(false);
  }

  /// Applies the selected sort type and tag filters, then refreshes the feed.
  Future<void> applySortAndFilters() async {
    homeUiModel.setLoading(true);
    await feedModel.fetchNextPage(page: 1, includeTagFilters: true);
    homeUiModel.setLoading(false);
  }
}
