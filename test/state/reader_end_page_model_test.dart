import 'package:concept_nhv/application/feed/search_comics_use_case.dart';
import 'package:concept_nhv/application/tags/find_similar_comics_online_use_case.dart';
import 'package:concept_nhv/application/tags/find_similar_comics_use_case.dart';
import 'package:concept_nhv/models/collection_type.dart';
import 'package:concept_nhv/models/local_tag_catalog_entry.dart';
import 'package:concept_nhv/models/stored_comic.dart';
import 'package:concept_nhv/models/tag_catalog_type.dart';
import 'package:concept_nhv/services/local_tag_catalog_service.dart';
import 'package:concept_nhv/services/search_query_builder.dart';
import 'package:concept_nhv/state/reader_end_page_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_support/fakes/fake_blocked_tags_repository.dart';
import '../test_support/fakes/fake_nhentai_gateway.dart';
import '../test_support/fixtures/sample_comic.dart';
import '../test_support/storage/sqlite_test_harness.dart';

void main() {
  group('ReaderEndPageModel', () {
    late SqliteTestHarness harness;

    const artist = 20;
    const other = 21;

    final catalog = LocalTagCatalogService.fromEntries(<LocalTagCatalogEntry>[
      const LocalTagCatalogEntry(
        id: artist,
        type: TagCatalogType.artist,
        name: 'artist',
        slug: 'artist',
        count: 40,
      ),
      const LocalTagCatalogEntry(
        id: other,
        type: TagCatalogType.tag,
        name: 'glasses',
        slug: 'glasses',
        count: 8000,
      ),
    ]);

    var preferenceReads = 0;

    ReaderEndPageModel buildModel(String comicId) {
      final gateway = FakeNhentaiGateway(detailComic: sampleComic());
      return ReaderEndPageModel(
        comicId: comicId,
        findSimilar: FindSimilarComicsUseCase(
          comicTagRepository: harness.comicTagRepository,
          comicRepository: harness.comicRepository,
          localTagCatalogService: catalog,
        ),
        findSimilarOnline: FindSimilarComicsOnlineUseCase(
          searchComicsUseCase: SearchComicsUseCase(
            nhentaiGateway: gateway,
            searchQueryBuilder: const SearchQueryBuilder(),
          ),
          comicTagRepository: harness.comicTagRepository,
          localTagCatalogService: catalog,
          blockedTagsRepository: FakeBlockedTagsRepository(),
        ),
        readPreferences: () {
          preferenceReads++;
          return null;
        },
      );
    }

    Future<void> keep(String comicId, List<int> tagIds) async {
      await harness.comicRepository.upsertComic(
        StoredComic(
          id: comicId,
          mediaId: 'm$comicId',
          title: 'Comic $comicId',
          serializedImages: '',
          pages: 20,
        ),
      );
      await harness.comicTagRepository.replaceTagIds(comicId, tagIds);
      await harness.collectionRepository.addComicToCollection(
        collectionType: CollectionType.favorite,
        comicId: comicId,
      );
    }

    setUp(() async {
      harness = SqliteTestHarness();
      await harness.initialize();
      preferenceReads = 0;
    });

    tearDown(() async {
      await harness.dispose();
    });

    test('a tagged comic gets the page even with an empty library', () async {
      // Looking on the site is most useful precisely when the library holds
      // nothing similar, and that button lives on this page.
      final model = buildModel('source');

      await model.load(hasTags: true);

      expect(model.canShowPage, isTrue);
      expect(model.similar, isEmpty);
    });

    test('an untagged comic gets no page', () async {
      // Neither half has anything to work with, so swiping past the end
      // should keep doing nothing.
      final model = buildModel('source');

      await model.load(hasTags: false);

      expect(model.canShowPage, isFalse);
    });

    test('exposes what the library holds, and notifies once', () async {
      await keep('source', <int>[artist, other]);
      await keep('sibling', <int>[artist, other]);

      final model = buildModel('source');
      var notifications = 0;
      model.addListener(() => notifications++);

      await model.load(hasTags: true);

      expect(model.similar.map((s) => s.comic.id), <String>['sibling']);
      expect(
        notifications,
        1,
        reason: 'more than one rebuilds the PageView mid-swipe',
      );
    });

    test('reads the preference vector at each lookup', () async {
      // It is built in the background and may not exist yet when the reader
      // opens, so holding the value from construction would mean never
      // seeing it.
      final model = buildModel('source');

      await model.load(hasTags: true);
      expect(preferenceReads, 1);

      await model.findOnline();
      expect(preferenceReads, 2);
    });
  });
}
