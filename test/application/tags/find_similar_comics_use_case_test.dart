import 'package:concept_nhv/application/tags/find_similar_comics_use_case.dart';
import 'package:concept_nhv/application/tags/tag_preference_vector.dart';
import 'package:concept_nhv/models/collection_type.dart';
import 'package:concept_nhv/models/local_tag_catalog_entry.dart';
import 'package:concept_nhv/models/stored_comic.dart';
import 'package:concept_nhv/models/tag_catalog_type.dart';
import 'package:concept_nhv/services/local_tag_catalog_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_support/storage/sqlite_test_harness.dart';

void main() {
  group('FindSimilarComicsUseCase', () {
    late SqliteTestHarness harness;

    // Site-wide counts: 1 is everywhere, 20+ are specific artists.
    const commonTag = 1;
    const midTag = 2;
    const artistA = 20;
    const artistB = 21;
    const artistC = 22;

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
      for (final id in <int>[artistA, artistB, artistC])
        LocalTagCatalogEntry(
          id: id,
          type: TagCatalogType.artist,
          name: 'artist$id',
          slug: 'artist$id',
          count: 40,
        ),
    ];

    FindSimilarComicsUseCase buildUseCase({
      int limit = 6,
      double minimumSimilarity = 0.15,
    }) {
      return FindSimilarComicsUseCase(
        comicTagRepository: harness.comicTagRepository,
        comicRepository: harness.comicRepository,
        localTagCatalogService: LocalTagCatalogService.fromEntries(catalog),
        limit: limit,
        minimumSimilarity: minimumSimilarity,
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
    });

    tearDown(() async {
      await harness.dispose();
    });

    test('prefers the comic sharing a rare tag', () async {
      await keep('source', <int>[commonTag, artistA]);
      await keep('same-artist', <int>[artistA, midTag]);
      await keep('same-common-tag', <int>[commonTag, midTag]);

      final results = await buildUseCase().execute('source');

      expect(results.first.comic.id, 'same-artist');
    });

    test('leaves the comic itself out', () async {
      await keep('source', <int>[artistA, midTag]);
      await keep('other', <int>[artistA, midTag]);

      final results = await buildUseCase().execute('source');

      expect(results.map((r) => r.comic.id), isNot(contains('source')));
    });

    test('a comic carrying everything does not win by default', () async {
      // The P84 trap: an anthology shares a tag with almost anything, so
      // without normalising it takes every top spot.
      await keep('source', <int>[artistA, artistB]);
      await keep('focused', <int>[artistA, artistB]);
      await keep('anthology', <int>[
        commonTag,
        midTag,
        artistA,
        artistB,
        artistC,
      ]);

      final results = await buildUseCase().execute('source');

      expect(results.first.comic.id, 'focused');
    });

    test('says which tags it matched on', () async {
      await keep('source', <int>[commonTag, artistA]);
      await keep('other', <int>[commonTag, artistA]);

      final results = await buildUseCase().execute('source');

      expect(
        results.single.sharedTagIds.first,
        artistA,
        reason: 'the common tag explains nothing',
      );
    });

    test('shows fewer rather than padding to the limit', () async {
      await keep('source', <int>[artistA, midTag]);
      await keep('close', <int>[artistA, midTag]);
      for (var i = 0; i < 8; i++) {
        await keep('unrelated$i', <int>[commonTag]);
      }

      final results = await buildUseCase().execute('source');

      expect(results, hasLength(1));
    });

    test('returns nothing when nothing clears the bar', () async {
      await keep('source', <int>[artistA]);
      await keep('unrelated', <int>[commonTag, midTag]);

      final results = await buildUseCase().execute('source');

      expect(results, isEmpty);
    });

    test('returns nothing when the comic has no tags', () async {
      await keep('bare', const <int>[]);
      await keep('other', <int>[artistA]);

      expect(await buildUseCase().execute('bare'), isEmpty);
    });

    test('honours the limit', () async {
      await keep('source', <int>[artistA, artistB]);
      for (var i = 0; i < 5; i++) {
        await keep('match$i', <int>[artistA, artistB]);
      }

      final results = await buildUseCase(limit: 3).execute('source');

      expect(results, hasLength(3));
    });

    test('breaks ties by preference, not by multiplying it in', () async {
      // Two equally similar comics: the one the user leans toward comes
      // first, but it could never displace a *more* similar comic.
      await keep('source', <int>[artistA, midTag]);
      await keep('plain', <int>[artistA, midTag]);
      await keep('preferred', <int>[artistA, midTag, artistC]);

      const preferences = TagPreferenceVector(
        weights: <int, double>{artistC: 1.0},
        goldThreshold: 0.4,
        platinumThreshold: 0.55,
      );

      final results = await buildUseCase().execute(
        'source',
        preferences: preferences,
      );

      // 'plain' is the closer match, so preference must not overturn it.
      expect(results.first.comic.id, 'plain');
      expect(results.map((r) => r.comic.id), contains('preferred'));
    });
  });
}
