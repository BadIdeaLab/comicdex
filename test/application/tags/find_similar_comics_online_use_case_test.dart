import 'package:concept_nhv/application/feed/search_comics_use_case.dart';
import 'package:concept_nhv/application/tags/find_similar_comics_online_use_case.dart';
import 'package:concept_nhv/models/collection_type.dart';
import 'package:concept_nhv/models/comic.dart';
import 'package:concept_nhv/models/comic_search_response.dart';
import 'package:concept_nhv/models/comic_tag.dart';
import 'package:concept_nhv/models/local_tag_catalog_entry.dart';
import 'package:concept_nhv/models/tag_catalog_type.dart';
import 'package:concept_nhv/services/local_tag_catalog_service.dart';
import 'package:concept_nhv/services/nhentai_api_client.dart';
import 'package:concept_nhv/services/search_query_builder.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_support/fakes/fake_blocked_tags_repository.dart';
import '../../test_support/fixtures/sample_comic.dart';
import '../../test_support/storage/sqlite_test_harness.dart';

void main() {
  group('FindSimilarComicsOnlineUseCase', () {
    late SqliteTestHarness harness;
    late FakeBlockedTagsRepository blockedTags;

    const commonTag = 1;
    const midTag = 2;
    const artist = 20;

    final catalog = <LocalTagCatalogEntry>[
      const LocalTagCatalogEntry(
        id: commonTag,
        type: TagCatalogType.tag,
        name: 'full color',
        slug: 'full-color',
        count: 100000,
      ),
      const LocalTagCatalogEntry(
        id: midTag,
        type: TagCatalogType.tag,
        name: 'glasses',
        slug: 'glasses',
        count: 8000,
      ),
      const LocalTagCatalogEntry(
        id: artist,
        type: TagCatalogType.artist,
        name: 'kataokasan',
        slug: 'kataokasan',
        count: 40,
      ),
    ];

    Comic remote(String id, List<int> tagIds) {
      return sampleComic(id: id, mediaId: 'm$id').copyWith(
        tags: const <ComicTag>[],
        tagIds: tagIds,
      );
    }

    FindSimilarComicsOnlineUseCase buildUseCase(_RecordingGateway gateway) {
      return FindSimilarComicsOnlineUseCase(
        searchComicsUseCase: SearchComicsUseCase(
          nhentaiGateway: gateway,
          searchQueryBuilder: const SearchQueryBuilder(),
        ),
        comicTagRepository: harness.comicTagRepository,
        localTagCatalogService: LocalTagCatalogService.fromEntries(catalog),
        blockedTagsRepository: blockedTags,
      );
    }

    Future<void> own(String comicId, List<int> tagIds) async {
      await harness.comicTagRepository.replaceTagIds(comicId, tagIds);
      await harness.collectionRepository.addComicToCollection(
        collectionType: CollectionType.favorite,
        comicId: comicId,
      );
    }

    setUp(() async {
      harness = SqliteTestHarness();
      await harness.initialize();
      blockedTags = FakeBlockedTagsRepository();
    });

    tearDown(() async {
      await harness.dispose();
    });

    test('searches the rarest tag, not the first one', () async {
      await own('source', <int>[commonTag, midTag, artist]);
      final gateway = _RecordingGateway(<Comic>[]);

      await buildUseCase(gateway).execute('source');

      expect(gateway.requests, hasLength(1), reason: 'one request per call');
      expect(
        gateway.requests.single.queryParameters['query'],
        contains('artist:kataokasan'),
      );
    });

    test('excludes what the user already has', () async {
      await own('source', <int>[artist]);
      await own('already-owned', <int>[artist]);
      final gateway = _RecordingGateway(<Comic>[
        remote('already-owned', <int>[artist]),
        remote('new-one', <int>[artist]),
        remote('source', <int>[artist]),
      ]);

      final result = await buildUseCase(gateway).execute('source');

      expect(result.comics.map((c) => c.comic.id), <String>['new-one']);
    });

    test('excludes a comic still in the download queue', () async {
      // Recommending something mid-download is worse than recommending
      // something already owned.
      await own('source', <int>[artist]);
      await harness.downloadQueueRepository.upsertJobManifest(
        comic: sampleComic(id: 'downloading', mediaId: 'md'),
        title: 'downloading',
      );
      final gateway = _RecordingGateway(<Comic>[
        remote('downloading', <int>[artist]),
        remote('new-one', <int>[artist]),
      ]);

      final result = await buildUseCase(gateway).execute('source');

      expect(result.comics.map((c) => c.comic.id), <String>['new-one']);
    });

    test('re-ranks locally instead of trusting the order it got', () async {
      // The site sorts by date or popularity, so the order it returns says
      // nothing about similarity.
      await own('source', <int>[artist, midTag]);
      final gateway = _RecordingGateway(<Comic>[
        remote('weak', <int>[artist, commonTag]),
        remote('strong', <int>[artist, midTag]),
      ]);

      final result = await buildUseCase(gateway).execute('source');

      expect(result.comics.first.comic.id, 'strong');
    });

    test('passes blocked tags to the search', () async {
      await own('source', <int>[artist]);
      await blockedTags.saveBlockedTags(<String>['tag:guro']);
      final gateway = _RecordingGateway(<Comic>[]);

      await buildUseCase(gateway).execute('source');

      expect(
        gateway.requests.single.queryParameters['query'],
        contains('-tag:guro'),
      );
    });

    test('says which tag it searched', () async {
      await own('source', <int>[commonTag, artist]);
      final gateway = _RecordingGateway(<Comic>[]);

      final result = await buildUseCase(gateway).execute('source');

      expect(result.searchedTag?.slug, 'kataokasan');
      expect(result.failed, isFalse);
    });

    test('reports unavailable when the comic has no known tags', () async {
      await own('bare', const <int>[]);
      final gateway = _RecordingGateway(<Comic>[]);

      final result = await buildUseCase(gateway).execute('bare');

      expect(result.failed, isTrue);
      expect(gateway.requests, isEmpty, reason: 'nothing to ask about');
    });
  });
}

/// Records the URIs it was asked for, so "one request per call" can be
/// asserted directly — a later change to one request per tag would otherwise
/// go unnoticed.
class _RecordingGateway implements NhentaiGateway {
  _RecordingGateway(this._results);

  final List<Comic> _results;
  final List<Uri> requests = <Uri>[];

  @override
  Future<ComicSearchResponse> searchComics(Uri uri) async {
    requests.add(uri);
    return ComicSearchResponse(result: _results, numPages: 1);
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
