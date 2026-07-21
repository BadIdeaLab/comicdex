import 'package:concept_nhv/application/feed/feed_load_result.dart';
import 'package:concept_nhv/models/comic.dart';
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
    PopularSortType? sortType,
    List<String> blockedTagQueries = const <String>[],
  }) async {
    final uri = searchQueryBuilder.buildSearchUri(
      userQuery: query,
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
      return FeedLoadResult(
        comics: const <Comic>[],
        pageLoaded: page,
        noMorePage: true,
        statusCode: error.response?.statusCode ?? 200,
        errorMessage: _mapDioError(error),
      );
    }
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
