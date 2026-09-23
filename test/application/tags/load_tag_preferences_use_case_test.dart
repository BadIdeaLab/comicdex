import 'package:concept_nhv/application/tags/load_tag_preferences_use_case.dart';
import 'package:concept_nhv/models/collection_type.dart';
import 'package:concept_nhv/models/local_tag_catalog_entry.dart';
import 'package:concept_nhv/models/tag_catalog_type.dart';
import 'package:concept_nhv/models/tag_preference_entry.dart';
import 'package:concept_nhv/services/local_tag_catalog_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_support/fakes/fake_blocked_tags_repository.dart';
import '../../test_support/fixtures/sample_comic.dart';
import '../../test_support/storage/sqlite_test_harness.dart';

void main() {
  group('LoadTagPreferencesUseCase', () {
    late SqliteTestHarness harness;
    late FakeBlockedTagsRepository blockedTags;

    LocalTagCatalogEntry entry(
      int id,
      String slug, {
      TagCatalogType type = TagCatalogType.tag,
      int count = 100,
    }) => LocalTagCatalogEntry(
      id: id,
      type: type,
      name: slug,
      slug: slug,
      count: count,
    );

    LoadTagPreferencesUseCase buildUseCase(List<LocalTagCatalogEntry> entries) {
      return LoadTagPreferencesUseCase(
        comicTagRepository: harness.comicTagRepository,
        localTagCatalogService: LocalTagCatalogService.fromEntries(entries),
        blockedTagsRepository: blockedTags,
      );
    }

    Future<void> favorite(String comicId, List<int> tagIds) async {
      await harness.comicTagRepository.replaceTagIds(comicId, tagIds);
      await harness.collectionRepository.addComicToCollection(
        collectionType: CollectionType.favorite,
        comicId: comicId,
      );
    }

    Future<void> download(String comicId, List<int> tagIds) async {
      await harness.downloadedLibraryRepository.saveDownloadedComic(
        comic: sampleComic(
          id: comicId,
        ).copyWith(tags: const [], tagIds: tagIds),
        rootDirectoryPath: '/downloads/$comicId',
        coverLocalPath: null,
      );
      await harness.comicTagRepository.replaceTagIds(comicId, tagIds);
    }

    setUp(() async {
      harness = SqliteTestHarness();
      await harness.initialize();
      blockedTags = FakeBlockedTagsRepository();
    });

    tearDown(() async {
      await harness.dispose();
    });

    test('counts a favorited and downloaded comic once', () async {
      for (final id in <String>['1', '2', '3']) {
        await favorite(id, <int>[10]);
        await download(id, <int>[10]);
      }

      final result = await buildUseCase(<LocalTagCatalogEntry>[
        entry(10, 'kept'),
      ]).execute();

      final tag = result[TagCatalogType.tag]!.single;
      expect(tag.comicCount, 3);
      expect(tag.favoriteCount, 3);
      expect(tag.downloadedCount, 3);
    });

    test('counts comics that are only downloaded or only favorited', () async {
      await favorite('1', <int>[10]);
      await favorite('2', <int>[10]);
      await download('3', <int>[10]);

      final result = await buildUseCase(<LocalTagCatalogEntry>[
        entry(10, 'kept'),
      ]).execute();

      expect(result[TagCatalogType.tag]!.single.comicCount, 3);
    });

    test(
      'drops tags below the minimum, blocked tags and unknown ids',
      () async {
        for (final id in <String>['1', '2', '3']) {
          await favorite(id, <int>[10, 20, 30, 40]);
        }
        await favorite('4', <int>[50]); // only one comic: below the minimum
        await blockedTags.saveBlockedTags(<String>["tag:blocked"]);

        final result = await buildUseCase(<LocalTagCatalogEntry>[
          entry(10, 'kept'),
          entry(20, 'blocked'),
          entry(30, 'english', type: TagCatalogType.language),
          entry(50, 'rare'),
          // 40 is deliberately absent: a group/category id the catalog omits.
        ]).execute();

        expect(result[TagCatalogType.tag]!.map((e) => e.tag.slug), <String>[
          'kept',
        ]);
        expect(result.containsKey(TagCatalogType.language), isFalse);
      },
    );

    test('a tiny sample no longer outranks a well-evidenced tag', () async {
      // "niche" is on 3 comics out of 40 site-wide; "liked" is on 20 out of
      // 400. Raw lift ties them at 0.05 — the point estimate says nothing
      // about how little evidence the first one has.
      for (var i = 0; i < 20; i++) {
        await favorite('$i', i < 3 ? <int>[10, 20] : <int>[20]);
      }

      final result = await buildUseCase(<LocalTagCatalogEntry>[
        entry(10, 'niche', count: 40),
        entry(20, 'liked', count: 400),
      ]).execute(sort: TagPreferenceSort.affinity);

      expect(result[TagCatalogType.tag]!.map((e) => e.tag.slug), <String>[
        'liked',
        'niche',
      ]);
    });

    test('a tag that barely exists site-wide needs more evidence', () async {
      // 3 of a tag with 5 galleries site-wide vs 20 of one with 400: the raw
      // ratio puts the first far ahead purely because its divisor is tiny.
      for (var i = 0; i < 20; i++) {
        await favorite('$i', i < 3 ? <int>[10, 20] : <int>[20]);
      }

      final result = await buildUseCase(<LocalTagCatalogEntry>[
        entry(10, 'barely-exists', count: 5),
        entry(20, 'liked', count: 400),
      ]).execute(sort: TagPreferenceSort.affinity);

      expect(result[TagCatalogType.tag]!.map((e) => e.tag.slug), <String>[
        'liked',
        'barely-exists',
      ]);
    });

    test('but keeping most of a rare tag still ranks it first', () async {
      // Same rare tag, now the user kept 5 of its 5.
      for (var i = 0; i < 20; i++) {
        await favorite('$i', i < 5 ? <int>[10, 20] : <int>[20]);
      }

      final result = await buildUseCase(<LocalTagCatalogEntry>[
        entry(10, 'barely-exists', count: 5),
        entry(20, 'liked', count: 400),
      ]).execute(sort: TagPreferenceSort.affinity);

      expect(result[TagCatalogType.tag]!.first.tag.slug, 'barely-exists');
    });

    test('sorts by comic count, then by affinity when asked', () async {
      // "common" is on more comics, but "niche" is far rarer site-wide.
      for (final id in <String>['1', '2', '3', '4']) {
        await favorite(id, <int>[10]);
      }
      for (final id in <String>['1', '2', '3']) {
        await harness.comicTagRepository.replaceTagIds(id, <int>[10, 20]);
      }

      final useCase = buildUseCase(<LocalTagCatalogEntry>[
        entry(10, 'common', count: 100000),
        entry(20, 'niche', count: 40),
      ]);

      expect(
        (await useCase.execute()).values.first.map((e) => e.tag.slug),
        <String>['common', 'niche'],
      );
      expect(
        (await useCase.execute(
          sort: TagPreferenceSort.affinity,
        )).values.first.map((e) => e.tag.slug),
        <String>['niche', 'common'],
      );
    });

    test('groups entries by type', () async {
      for (final id in <String>['1', '2', '3']) {
        await favorite(id, <int>[10, 60]);
      }

      final result = await buildUseCase(<LocalTagCatalogEntry>[
        entry(10, 'kept'),
        entry(60, 'artist-a', type: TagCatalogType.artist),
      ]).execute();

      expect(result[TagCatalogType.tag]!.single.tag.slug, 'kept');
      expect(result[TagCatalogType.artist]!.single.tag.slug, 'artist-a');
      expect(result[TagCatalogType.parody], isEmpty);
    });
  });

  group('wilsonLowerBound', () {
    test('is zero without evidence', () {
      expect(LoadTagPreferencesUseCase.wilsonLowerBound(0, 650), 0);
      expect(LoadTagPreferencesUseCase.wilsonLowerBound(5, 0), 0);
    });

    test('discounts a small sample far more than a large one', () {
      // Same observed share (10%), 100x the evidence.
      final small = LoadTagPreferencesUseCase.wilsonLowerBound(1, 10);
      final large = LoadTagPreferencesUseCase.wilsonLowerBound(100, 1000);

      expect(small, lessThan(0.1));
      expect(large, lessThan(0.1));
      expect(large, greaterThan(small));
    });

    test('approaches the observed share as evidence grows', () {
      final bound = LoadTagPreferencesUseCase.wilsonLowerBound(1000, 10000);

      expect(bound, greaterThan(0.09));
      expect(bound, lessThan(0.1));
    });
  });
}
