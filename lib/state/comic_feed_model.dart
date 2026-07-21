import 'package:concept_nhv/application/feed/load_collection_summaries_use_case.dart';
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
  String? _feedErrorMessage;
  bool _includePersistentTagFiltersForCurrentQuery = true;
  PopularSortType? sortByPopularType;
  List<String> _tagFilters = <String>[];

  List<Comic>? get comics {
    if (_comics.isEmpty) {
      return null;
    }
    return List<Comic>.unmodifiable(_comics);
  }

  bool get noMorePage => _noMorePage;
  int? get numPages => _numPages;
  int get comicsLoaded => _comics.length;
  String? get feedErrorMessage => _feedErrorMessage;
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
    ]
        .where((s) => s.isNotEmpty)
        .join(' ')
        .trim();
    final result = await searchComicsUseCase.execute(
      query: combinedQuery,
      page: page,
      sortType: sortType ?? sortByPopularType,
      blockedTagQueries: _sessionBlockedTags,
    );

    _feedErrorMessage = result.errorMessage;
    _noMorePage = result.noMorePage;
    if (!_noMorePage) {
      _comics.addAll(result.comics);
      _numPages = result.numPages;
    }
    pageLoaded = result.pageLoaded;
    notifyListeners();
    return result.statusCode;
  }

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
