import 'package:concept_nhv/application/feed/load_collection_summaries_use_case.dart';
import 'package:concept_nhv/application/feed/feed_load_result.dart';
import 'package:concept_nhv/application/feed/search_comics_use_case.dart';
import 'package:concept_nhv/application/search/blocked_tags_repository.dart';
import 'package:concept_nhv/models/collection_summary.dart';
import 'package:concept_nhv/models/comic.dart';
import 'package:concept_nhv/models/popular_sort_type.dart';
import 'package:flutter/material.dart';

class ComicFeedModel extends ChangeNotifier {
  ComicFeedModel({
    required this.searchComicsUseCase,
    required this.loadCollectionSummariesUseCase,
    required this.blockedTagsRepository,
  });

  final SearchComicsUseCase searchComicsUseCase;
  final LoadCollectionSummariesUseCase loadCollectionSummariesUseCase;
  final BlockedTagsRepository blockedTagsRepository;

  final List<Comic> _comics = <Comic>[];
  Future<List<CollectionSummary>>? collectionSummariesFuture;
  int pageLoaded = 1;
  int? _numPages;
  List<String> _sessionBlockedTags = const <String>[];
  bool _noMorePage = false;
  String _lastQuery = '';
  FeedLoadFailure? _feedFailure;
  bool _includePersistentTagFiltersForCurrentQuery = true;
  PopularSortType? sortByPopularType;
  List<String> _tagFilters = <String>[];

  /// How many feed requests are in flight.
  ///
  /// A count, not a flag: two overlapping requests would otherwise have the
  /// first one to finish declare that nothing is running.
  int _inFlight = 0;

  List<Comic>? get comics {
    if (_comics.isEmpty) {
      return null;
    }
    return List<Comic>.unmodifiable(_comics);
  }

  /// Whether a feed request is in flight.
  ///
  /// This is both the progress bar and the guard that stops the infinite
  /// scroll from firing a second request on top of the first. It lives here —
  /// rather than on `HomeUiModel`, where nine callers used to raise and lower
  /// it by hand around their own calls into this class — because this is the
  /// object that knows. Eight of those nine had no `try`/`finally`, so any
  /// throw left the flag raised for ever, and with it the infinite scroll
  /// switched off (P99).
  bool get isFetching => _inFlight > 0;

  bool get noMorePage => _noMorePage;
  int? get numPages => _numPages;
  int get comicsLoaded => _comics.length;
  FeedLoadFailure? get feedFailure => _feedFailure;
  List<String> get tagFilters => List<String>.unmodifiable(_tagFilters);

  void toggleSort(PopularSortType type) {
    sortByPopularType = sortByPopularType == type ? null : type;
    notifyListeners();
  }

  void setSortType(PopularSortType? type) {
    sortByPopularType = type;
    notifyListeners();
  }

  void setTagFilters(List<String> tags) {
    _tagFilters = List<String>.from(tags);
    notifyListeners();
  }

  void refreshCollections() {
    collectionSummariesFuture = loadCollectionSummariesUseCase.execute();
    notifyListeners();
  }

  Future<int?> loadHomeFeed({int page = 1, bool clearComic = false}) {
    return searchComics(
      query: '',
      page: page,
      clearComic: clearComic,
      includeTagFilters: true,
    );
  }

  Future<int?> searchComics({
    required String query,
    int page = 1,
    PopularSortType? sortType,
    bool clearComic = false,
    bool includeTagFilters = true,
  }) async {
    // Every feed read funnels through here — loadHomeFeed, fetchNextPage and
    // jumpToPage all call it — so counting in one place covers all of them.
    _inFlight += 1;
    notifyListeners();
    try {
      return await _search(
        query: query,
        page: page,
        sortType: sortType,
        clearComic: clearComic,
        includeTagFilters: includeTagFilters,
      );
    } finally {
      _inFlight -= 1;
      notifyListeners();
    }
  }

  Future<int?> _search({
    required String query,
    required int page,
    required PopularSortType? sortType,
    required bool clearComic,
    required bool includeTagFilters,
  }) async {
    if (clearComic) {
      _comics.clear();
      _noMorePage = false;
      _numPages = null;
      _sessionBlockedTags = await blockedTagsRepository.loadBlockedTags();
    }

    _lastQuery = query;
    _includePersistentTagFiltersForCurrentQuery = includeTagFilters;
    final combinedQuery = [
      query,
      if (includeTagFilters) ..._tagFilters,
    ].where((s) => s.isNotEmpty).join(' ').trim();
    final result = await searchComicsUseCase.execute(
      query: combinedQuery,
      page: page,
      sortType: sortType ?? sortByPopularType,
      blockedTagQueries: _sessionBlockedTags,
    );

    _feedFailure = result.failure;
    if (result.hasFailed) {
      // Leave the pagination state exactly as it was: advancing `pageLoaded`
      // would skip the page that failed, and setting `noMorePage` would end
      // infinite scrolling over one bad request (P89).
      notifyListeners();
      return result.statusCode;
    }

    _noMorePage = result.noMorePage;
    if (!_noMorePage) {
      _comics.addAll(result.comics);
      _numPages = result.numPages;
    }
    pageLoaded = result.pageLoaded;
    notifyListeners();
    return result.statusCode;
  }

  /// Reloads the first page of whatever is on screen, search terms included.
  ///
  /// Used by the home tab refresh button. It deliberately re-runs the last
  /// query rather than resetting to the plain feed: refreshing while a search
  /// is active should not silently throw the search away.
  Future<void> refreshCurrentQuery() => fetchNextPage(page: 1);

  Future<void> fetchNextPage({int? page, bool? includeTagFilters}) async {
    final targetPage = page ?? pageLoaded + 1;
    await searchComics(
      query: _lastQuery,
      page: targetPage,
      clearComic: targetPage == 1,
      includeTagFilters:
          includeTagFilters ?? _includePersistentTagFiltersForCurrentQuery,
    );
  }

  Future<void> jumpToPage(int page) async {
    await searchComics(
      query: _lastQuery,
      page: page,
      clearComic: true,
      includeTagFilters: _includePersistentTagFiltersForCurrentQuery,
    );
  }
}
