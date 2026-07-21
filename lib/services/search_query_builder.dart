import 'package:concept_nhv/models/popular_sort_type.dart';

class SearchQueryBuilder {
  const SearchQueryBuilder();

  Uri buildSearchUri({
    required String userQuery,
    required int page,
    PopularSortType? sortType,
    List<String> blockedTagQueries = const <String>[],
  }) {
    final normalizedQuery = [
      userQuery.trim(),
      ...blockedTagQueries.map((q) => '-$q'),
    ].where((element) => element.isNotEmpty).join(' ').trim();

    if (normalizedQuery.isEmpty && sortType == null) {
      return Uri.https('nhentai.net', '/api/v2/galleries', <String, String>{
        'page': '$page',
      });
    }

    return Uri.https('nhentai.net', '/api/v2/search', <String, String>{
      'query': normalizedQuery.isEmpty ? 'pages:>0' : normalizedQuery,
      'page': '$page',
      if (sortType != null) 'sort': sortType.apiValue,
    });
  }
}
