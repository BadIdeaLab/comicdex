import 'package:concept_nhv/application/feed/feed_load_result.dart';
import 'package:concept_nhv/application/search/blocked_tags_repository.dart';
import 'package:concept_nhv/application/feed/load_collection_summaries_use_case.dart';
import 'package:concept_nhv/application/feed/search_comics_use_case.dart';
import 'package:concept_nhv/models/comic.dart';
import 'package:concept_nhv/models/comic_search_response.dart';
import 'package:concept_nhv/models/comic_tag.dart';
import 'package:concept_nhv/services/nhentai_api_client.dart';
import 'package:concept_nhv/services/search_query_builder.dart';
import 'package:concept_nhv/state/comic_feed_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_support/fakes/fake_blocked_tags_repository.dart';
import '../test_support/fixtures/sample_comic.dart';
import '../test_support/storage/sqlite_test_harness.dart';

void main() {
  group('ComicFeedModel', () {
    late SqliteTestHarness harness;

    setUp(() async {
      harness = SqliteTestHarness();
      await harness.initialize();
    });

    tearDown(() async {
      await harness.dispose();
    });

    ComicFeedModel buildModel(_SequenceGateway gateway) {
      return ComicFeedModel(
        searchComicsUseCase: SearchComicsUseCase(
          nhentaiGateway: gateway,
          searchQueryBuilder: const SearchQueryBuilder(),
          retrySleep: (_) async {},
        ),
        loadCollectionSummariesUseCase: LoadCollectionSummariesUseCase(
          collectionRepository: harness.collectionRepository,
        ),
        blockedTagsRepository: FakeBlockedTagsRepository(),
      );
    }

    ComicSearchResponse page(String id) => ComicSearchResponse(
      result: <dynamic>[sampleComic(id: id)].cast(),
      numPages: 5,
    );

    group('isFetching', () {
      test(
        'is raised while a request is in flight and lowered after',
        () async {
          final gateway = _SequenceGateway(<Object>[page('1')]);
          final model = buildModel(gateway);
          expect(model.isFetching, isFalse);

          final pending = model.loadHomeFeed();
          expect(
            model.isFetching,
            isTrue,
            reason: 'raised synchronously, before the first await',
          );

          await pending;
          expect(model.isFetching, isFalse);
        },
      );

      test('comes back down when the blocked-tag read throws', () async {
        // The shape of the eight holes this replaced: nine callers used to
        // raise this flag by hand around their own calls, and only one of
        // them used try/finally. Anything thrown from in here left it raised
        // for ever — and because the same flag gates the infinite scroll,
        // that switched auto-loading off until a restart.
        final model = ComicFeedModel(
          searchComicsUseCase: SearchComicsUseCase(
            nhentaiGateway: _SequenceGateway(<Object>[page('1')]),
            searchQueryBuilder: const SearchQueryBuilder(),
            retrySleep: (_) async {},
          ),
          loadCollectionSummariesUseCase: LoadCollectionSummariesUseCase(
            collectionRepository: harness.collectionRepository,
          ),
          blockedTagsRepository: _ThrowingBlockedTagsRepository(),
        );

        await expectLater(
          model.loadHomeFeed(clearComic: true),
          throwsA(isA<StateError>()),
        );
        expect(model.isFetching, isFalse);
      });

      test(
        'two overlapping requests: the first to finish does not clear it',
        () async {
          // A bool would have the earlier one declare that nothing is running
          // while the later one is still going, which is exactly when the
          // infinite scroll would fire a third.
          final gateway = _SequenceGateway(<Object>[page('1'), page('2')]);
          final model = buildModel(gateway);

          final first = model.loadHomeFeed();
          final second = model.fetchNextPage(page: 2);
          await first;

          expect(model.isFetching, isTrue, reason: 'the second is still going');

          await second;
          expect(model.isFetching, isFalse);
        },
      );

      test('notifies listeners when it changes', () async {
        // The progress bar and the refresh button both read it, so a change
        // nobody is told about is a bar that never appears.
        final model = buildModel(_SequenceGateway(<Object>[page('1')]));
        var notifications = 0;
        model.addListener(() => notifications += 1);

        await model.loadHomeFeed();

        expect(notifications, greaterThanOrEqualTo(2));
      });
    });

    test('a failed page leaves pagination exactly where it was', () async {
      // The point of P89: one 504 used to set `noMorePage`, which switched
      // off infinite scrolling for the rest of the session, and advanced
      // `pageLoaded`, which skipped the page that never arrived.
      final gateway = _SequenceGateway(<Object>[
        page('1'),
        _serverError(),
        _serverError(),
        _serverError(),
      ]);
      final model = buildModel(gateway);

      await model.loadHomeFeed(clearComic: true);
      expect(model.pageLoaded, 1);

      await model.fetchNextPage(page: 2);

      expect(model.feedFailure, FeedLoadFailure.server);
      expect(model.noMorePage, isFalse, reason: 'scrolling must stay alive');
      expect(model.pageLoaded, 1, reason: 'page 2 never arrived');
      expect(model.comics, hasLength(1), reason: 'page 1 is still there');
    });

    test('a later attempt at the same page still works', () async {
      final gateway = _SequenceGateway(<Object>[
        page('1'),
        _serverError(),
        _serverError(),
        _serverError(),
        page('2'),
      ]);
      final model = buildModel(gateway);

      await model.loadHomeFeed(clearComic: true);
      await model.fetchNextPage(page: 2);
      await model.fetchNextPage(page: 2);

      expect(model.feedFailure, isNull);
      expect(model.pageLoaded, 2);
      expect(model.comics, hasLength(2));
    });

    test('an empty page really does mean the end', () async {
      final gateway = _SequenceGateway(<Object>[
        page('1'),
        ComicSearchResponse(result: const <Comic>[], numPages: 1),
      ]);
      final model = buildModel(gateway);

      await model.loadHomeFeed(clearComic: true);
      await model.fetchNextPage(page: 2);

      expect(model.feedFailure, isNull);
      expect(model.noMorePage, isTrue);
    });
  });
}

/// Fails before the request is even built, which is the path that used to
/// leak the flag.
class _ThrowingBlockedTagsRepository implements BlockedTagsRepository {
  @override
  Future<List<String>> loadBlockedTags() async =>
      throw StateError('blocked tags unavailable');

  @override
  Future<void> saveBlockedTags(List<String> tags) async {}
}

DioException _serverError() {
  final requestOptions = RequestOptions(path: '/');
  return DioException(
    requestOptions: requestOptions,
    response: Response<dynamic>(
      requestOptions: requestOptions,
      statusCode: 504,
    ),
    type: DioExceptionType.badResponse,
  );
}

/// Hands out one queued outcome per request, throwing the ones that are
/// exceptions.
class _SequenceGateway implements NhentaiGateway {
  _SequenceGateway(this._outcomes);

  final List<Object> _outcomes;
  int _index = 0;

  @override
  Future<ComicSearchResponse> searchComics(Uri uri) async {
    final outcome = _outcomes[_index++];
    if (outcome is DioException) throw outcome;
    return outcome as ComicSearchResponse;
  }

  @override
  Future<void> pingHomepage() async {}

  @override
  Future<Comic> loadComicDetail(String comicId) async =>
      throw UnimplementedError();

  @override
  Future<({List<ComicTag> tags, int? numFavorites, int? uploadDate})>
  loadComicMeta(String comicId) async => throw UnimplementedError();
}
