import 'package:concept_nhv/application/feed/search_comics_use_case.dart';
import 'package:concept_nhv/models/comic.dart';
import 'package:concept_nhv/models/comic_search_response.dart';
import 'package:concept_nhv/models/comic_tag.dart';
import 'package:concept_nhv/models/popular_sort_type.dart';
import 'package:concept_nhv/services/nhentai_api_client.dart';
import 'package:concept_nhv/services/search_query_builder.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_support/fixtures/sample_comic.dart';

void main() {
  test('sends a single request and maps a failure without retrying', () async {
    final gateway = _SequenceNhentaiGateway(<Object>[_badResponseException(404)]);
    final useCase = SearchComicsUseCase(
      nhentaiGateway: gateway,
      searchQueryBuilder: const SearchQueryBuilder(),
    );

    final result = await useCase.execute(
      query: 'tag:test',
      page: 2,
      sortType: PopularSortType.month,
    );

    expect(result.statusCode, 404);
    expect(result.comics, isEmpty);
    expect(result.errorMessage, 'Website API issue (404).');
    expect(result.noMorePage, isTrue);
    expect(gateway.searchedUris, hasLength(1));
    expect(gateway.searchedUris.single.queryParameters['query'], 'tag:test');
    expect(gateway.searchedUris.single.queryParameters['sort'], 'popular-month');
  });

  test('appends blocked tag exclusions to search uri', () async {
    final gateway = _SequenceNhentaiGateway(<Object>[
      ComicSearchResponse(
        result: <dynamic>[sampleComic()].cast(),
        numPages: 1,
        perPage: 25,
      ),
    ]);
    final useCase = SearchComicsUseCase(
      nhentaiGateway: gateway,
      searchQueryBuilder: const SearchQueryBuilder(),
    );

    await useCase.execute(
      query: 'tag:art-jam',
      page: 1,
      blockedTagQueries: <String>['tag:males-only', 'tag:full-color'],
    );

    expect(gateway.searchedUris, hasLength(1));
    final query = gateway.searchedUris.first.queryParameters['query']!;
    expect(query, contains('-tag:males-only'));
    expect(query, contains('-tag:full-color'));
    expect(query, startsWith('tag:art-jam'));
  });

  test('returns mapped error for a 403 response', () async {
    final gateway = _SequenceNhentaiGateway(<Object>[_badResponseException(403)]);
    final useCase = SearchComicsUseCase(
      nhentaiGateway: gateway,
      searchQueryBuilder: const SearchQueryBuilder(),
    );

    final result = await useCase.execute(query: '', page: 1);

    expect(result.statusCode, 403);
    expect(result.comics, isEmpty);
    expect(result.errorMessage, 'Authentication issue (403).');
    expect(result.noMorePage, isTrue);
  });
}

DioException _badResponseException(int statusCode) {
  return DioException.badResponse(
    statusCode: statusCode,
    requestOptions: RequestOptions(path: '/'),
    response: Response<dynamic>(
      requestOptions: RequestOptions(path: '/'),
      statusCode: statusCode,
    ),
  );
}

class _SequenceNhentaiGateway implements NhentaiGateway {
  _SequenceNhentaiGateway(this._responses);

  final List<Object> _responses;
  final List<Uri> searchedUris = <Uri>[];
  var _index = 0;

  @override
  Future<({Comic comic, Map<String, String>? headers})> loadComicDetail(
    String comicId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<void> pingHomepage() async {}

  @override
  Future<({List<ComicTag> tags, int? numFavorites, int? uploadDate})> loadComicMeta(
    String comicId,
  ) async {
    return (tags: const <ComicTag>[], numFavorites: null, uploadDate: null);
  }

  @override
  Future<ComicSearchResponse> searchComics(Uri uri) async {
    searchedUris.add(uri);
    final response = _responses[_index++];
    if (response is DioException) {
      throw response;
    }
    return response as ComicSearchResponse;
  }
}
