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
}
