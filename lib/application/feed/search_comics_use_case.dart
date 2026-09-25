import 'package:concept_nhv/application/feed/feed_load_result.dart';
import 'package:concept_nhv/models/comic.dart';
import 'package:concept_nhv/models/popular_sort_type.dart';
import 'package:concept_nhv/services/nhentai_api_client.dart';
import 'package:concept_nhv/services/request_retry.dart';
import 'package:concept_nhv/services/search_query_builder.dart';
import 'package:dio/dio.dart';

class SearchComicsUseCase {
  const SearchComicsUseCase({
    required this.nhentaiGateway,
    required this.searchQueryBuilder,
    this.retrySleep,
  });

  final NhentaiGateway nhentaiGateway;
  final SearchQueryBuilder searchQueryBuilder;

  /// Overrides the wait between retries. Only tests pass it: otherwise a
  /// test covering the 504 path would sit through the real backoff.
  final Future<void> Function(Duration duration)? retrySleep;

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
      // Retried, because the site answers 504 often enough that a single
      // attempt fails the user for something that works a second later.
      final freshComics = await withRequestRetry(
        () => nhentaiGateway.searchComics(uri),
        sleep: retrySleep,
      );
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
        // Emphatically not `true`: this request failed, which says nothing
        // about whether more pages exist. Reporting the end of the results
        // here is what used to switch off infinite scrolling (P89).
        noMorePage: false,
        statusCode: error.response?.statusCode ?? 200,
        failure: _classify(error),
      );
    }
  }

  FeedLoadFailure _classify(DioException error) {
    if (isTransientFailure(error)) return FeedLoadFailure.server;
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.unknown) {
      return FeedLoadFailure.network;
    }

    return switch (error.response?.statusCode) {
      403 => FeedLoadFailure.forbidden,
      404 => FeedLoadFailure.notFound,
      _ => FeedLoadFailure.unknown,
    };
  }
}
