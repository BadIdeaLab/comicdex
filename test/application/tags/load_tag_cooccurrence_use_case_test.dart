import 'package:concept_nhv/application/tags/load_tag_cooccurrence_use_case.dart';
import 'package:concept_nhv/models/collection_type.dart';
import 'package:concept_nhv/models/local_tag_catalog_entry.dart';
import 'package:concept_nhv/models/tag_catalog_type.dart';
import 'package:concept_nhv/services/local_tag_catalog_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_support/fakes/fake_blocked_tags_repository.dart';
import '../../test_support/storage/sqlite_test_harness.dart';

void main() {
  group('LoadTagCooccurrenceUseCase', () {
    late SqliteTestHarness harness;
    late FakeBlockedTagsRepository blockedTags;

    LocalTagCatalogEntry entry(
      int id,
      String slug, {
      TagCatalogType type = TagCatalogType.tag,
    }) => LocalTagCatalogEntry(
      id: id,
      type: type,
      name: slug,
      slug: slug,
      count: 1000,
    );

    LoadTagCooccurrenceUseCase buildUseCase(
      List<LocalTagCatalogEntry> entries,
    ) {
      return LoadTagCooccurrenceUseCase(
        comicTagRepository: harness.comicTagRepository,
        localTagCatalogService: LocalTagCatalogService.fromEntries(entries),
        blockedTagsRepository: blockedTags,
      );
    }

    Future<void> keep(String comicId, List<int> tagIds) async {
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

    test('ranks a tightly bound pair above one that co-occurs by chance', () async {
      // 10 and 11 always travel together (8 comics). 20 is on almost
      // everything, so pairing with it says nothing.
      for (var i = 0; i < 8; i++) {
        await keep('bound-$i', <int>[10, 11, 20]);
      }
      for (var i = 0; i < 12; i++) {
        await keep('loose-$i', <int>[20, 30]);
      }
      for (var i = 0; i < 6; i++) {
        await keep('other-$i', <int>[30, 40]);
      }

      final result = await buildUseCase(<LocalTagCatalogEntry>[
        entry(10, 'a'),
        entry(11, 'b'),
        entry(20, 'everywhere'),
        entry(30, 'common'),
        entry(40, 'tail'),
      ]).execute();

      expect(
        '${result.first.first.slug}+${result.first.second.slug}',
        'a+b',
      );
      expect(result.first.comicCount, 8);
      expect(result.first.lift, greaterThan(1));
    });

    test('drops pairs below the support floor', () async {
      // Only 3 comics carry both — under the 5-comic floor.
      for (var i = 0; i < 3; i++) {
        await keep('pair-$i', <int>[10, 11]);
      }
      for (var i = 0; i < 6; i++) {
        await keep('solo-$i', <int>[10, 20]);
      }

      final result = await buildUseCase(<LocalTagCatalogEntry>[
        entry(10, 'a'),
        entry(11, 'b'),
        entry(20, 'c'),
      ]).execute();

      expect(
        result.map((pair) => '${pair.first.slug}+${pair.second.slug}'),
        <String>['a+c'],
      );
    });

    test('excludes languages, blocked tags and ids the catalog omits', () async {
      for (var i = 0; i < 6; i++) {
        await keep('comic-$i', <int>[10, 11, 12, 13, 14]);
      }
      await blockedTags.saveBlockedTags(<String>['tag:blocked']);

      final result = await buildUseCase(<LocalTagCatalogEntry>[
        entry(10, 'a'),
        entry(11, 'b'),
        entry(12, 'blocked'),
        entry(13, 'english', type: TagCatalogType.language),
        // 14 has no catalog entry at all (a group/category id).
      ]).execute();

      expect(
        result.map((pair) => '${pair.first.slug}+${pair.second.slug}'),
        <String>['a+b'],
      );
    });

    test('ignores tags on comics that were never kept', () async {
      for (var i = 0; i < 6; i++) {
        await harness.comicTagRepository.replaceTagIds('seen-$i', <int>[10, 11]);
        await harness.collectionRepository.addComicToCollection(
          collectionType: CollectionType.history,
          comicId: 'seen-$i',
        );
      }

      final result = await buildUseCase(<LocalTagCatalogEntry>[
        entry(10, 'a'),
        entry(11, 'b'),
      ]).execute();

      expect(result, isEmpty);
    });

    test('a pair is search-ready as two AND-ed tag queries', () async {
      for (var i = 0; i < 6; i++) {
        await keep('comic-$i', <int>[10, 11]);
      }

      final result = await buildUseCase(<LocalTagCatalogEntry>[
        entry(10, 'a'),
        entry(11, 'b', type: TagCatalogType.artist),
      ]).execute();

      expect(result.single.searchQueries, <String>['tag:a', 'artist:b']);
    });
  });
}
