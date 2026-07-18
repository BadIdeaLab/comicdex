import 'package:concept_nhv/application/feed/feed_load_result.dart';
import 'package:concept_nhv/models/comic.dart';
import 'package:concept_nhv/models/comic_language.dart';
import 'package:concept_nhv/models/popular_sort_type.dart';
import 'package:concept_nhv/services/nhentai_api_client.dart';
import 'package:concept_nhv/services/search_query_builder.dart';
import 'package:dio/dio.dart';

class SearchComicsUseCase {
  const SearchComicsUseCase({
    required this.nhentaiGateway,
    required this.searchQueryBuilder,
  });

  final NhentaiGateway nhentaiGateway;
  final SearchQueryBuilder searchQueryBuilder;

  Future<FeedLoadResult> execute({
    required String query,
    required int page,
    required ComicLanguage language,
    PopularSortType? sortType,
    List<String> blockedTagQueries = const <String>[],
  }) async {
    final languageQueries = <String>[
      language.apiQuery,
      ...language.fallbackQueries,
    ];
    var lastStatusCode = 200;
    String? errorMessage;

    for (var retryCount = 0; retryCount < languageQueries.length; retryCount++) {
      final uri = searchQueryBuilder.buildSearchUri(
        userQuery: query,
        languageQuery: languageQueries[retryCount],
        page: page,
        sortType: sortType,
        blockedTagQueries: blockedTagQueries,
      );

      try {
        final freshComics = await nhentaiGateway.searchComics(uri);
        return FeedLoadResult(
          comics: freshComics.result,
          pageLoaded: page,
          noMorePage: freshComics.result.isEmpty,
          statusCode: 200,
          numPages: freshComics.numPages,
        );
      } on DioException catch (error) {
        lastStatusCode = error.response?.statusCode ?? lastStatusCode;
        errorMessage = _mapDioError(error);
      }
    }

    return FeedLoadResult(
      comics: const <Comic>[],
      pageLoaded: page,
      noMorePage: true,
      statusCode: lastStatusCode,
      errorMessage: errorMessage ?? 'Failed to load comics from website.',
    );
  }

  String _mapDioError(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.unknown) {
      return 'Network error. Check the emulator/device internet connection and DNS.';
    }

    final statusCode = error.response?.statusCode;
    if (statusCode == 403) {
      return 'Authentication issue (403).';
    }
    if (statusCode == 404) {
      return 'Website API issue (404).';
    }

    return 'Failed to load comics from website.';
  }
}
