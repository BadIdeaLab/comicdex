import 'package:concept_nhv/application/tags/load_tag_cooccurrence_use_case.dart';
import 'package:concept_nhv/models/collection_type.dart';
import 'package:concept_nhv/models/local_tag_catalog_entry.dart';
import 'package:concept_nhv/models/tag_catalog_type.dart';
import 'package:concept_nhv/models/tag_preference_entry.dart';
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
      List<LocalTagCatalogEntry> entries, {
      double tripleGainFactor = 1.1,
    }) {
      return LoadTagCooccurrenceUseCase(
        comicTagRepository: harness.comicTagRepository,
        localTagCatalogService: LocalTagCatalogService.fromEntries(entries),
        blockedTagsRepository: blockedTags,
        tripleGainFactor: tripleGainFactor,
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

    test(
      'ranks a tightly bound pair above one that co-occurs by chance',
      () async {
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

        // The top combination is built on the pair that always travels
        // together; "everywhere" may ride along as a third member, but the
        // loose pairing of "everywhere" with "common" must not outrank it.
        final top = result.first.members.map((m) => m.slug).toSet();
        expect(top.containsAll(<String>{'a', 'b'}), isTrue);
        expect(result.first.comicCount, 8);
        expect(result.first.lift, greaterThan(1));
        final looseRank = result.indexWhere(
          (c) => c.members.map((m) => m.slug).toSet().containsAll(<String>{
            'everywhere',
            'common',
          }),
        );
        expect(looseRank, isNot(0));
      },
    );

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
        result.map((c) => c.members.map((m) => m.slug).join('+')),
        <String>['a+c'],
      );
    });

    test(
      'excludes languages, blocked tags and ids the catalog omits',
      () async {
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
          result.map((c) => c.members.map((m) => m.slug).join('+')),
          <String>['a+b'],
        );
      },
    );

    test('drops pairs that only reflect how the site is organised', () async {
      // 10 tag, 11 parody, 12 its character, 13 the artist, 14 a group whose
      // name matches the artist's.
      for (var i = 0; i < 6; i++) {
        await keep('comic-$i', <int>[10, 11, 12, 13, 14]);
      }

      final result = await buildUseCase(<LocalTagCatalogEntry>[
        entry(10, 'schoolgirl'),
        entry(11, 'some-series', type: TagCatalogType.parody),
        entry(12, 'some-character', type: TagCatalogType.character),
        entry(13, 'artist-name', type: TagCatalogType.artist),
        entry(14, 'artist-name-2', type: TagCatalogType.artist),
      ]).execute();

      final labels = result
          .map((c) => c.members.map((m) => m.slug).join('+'))
          .toSet();
      // Kept: content tag paired with who/what made or stars in it.
      expect(labels, <String>{
        'schoolgirl+some-series',
        'schoolgirl+some-character',
        'schoolgirl+artist-name',
        'schoolgirl+artist-name-2',
      });
      // Dropped: parody with its own character, artist with the parody, and
      // the two artists whose slugs contain one another.
      expect(
        labels.any((l) => l.contains('some-series+some-character')),
        isFalse,
      );
      expect(
        labels.any((l) => l.contains('artist-name+artist-name-2')),
        isFalse,
      );
    });

    test(
      'surfaces a three-tag combination that always travels together',
      () async {
        for (var i = 0; i < 8; i++) {
          await keep('trio-$i', <int>[10, 11, 12]);
        }
        // Padding so the trio is not simply everything in the library.
        for (var i = 0; i < 20; i++) {
          await keep('other-$i', <int>[30, 40]);
        }

        final result = await buildUseCase(<LocalTagCatalogEntry>[
          entry(10, 'a'),
          entry(11, 'b'),
          entry(12, 'c'),
          entry(30, 'x'),
          entry(40, 'y'),
        ]).execute();

        expect(
          result.any(
            (c) =>
                c.members.length == 3 &&
                c.members.map((m) => m.slug).toSet().containsAll(<String>{
                  'a',
                  'b',
                  'c',
                }),
          ),
          isTrue,
        );
      },
    );

    test(
      'a triple whose pair is below the support floor never appears',
      () async {
        // a+b only on 3 comics, so no triple containing it can reach 5 either.
        for (var i = 0; i < 3; i++) {
          await keep('rare-$i', <int>[10, 11, 12]);
        }
        for (var i = 0; i < 8; i++) {
          await keep('common-$i', <int>[12, 30]);
        }

        final result = await buildUseCase(<LocalTagCatalogEntry>[
          entry(10, 'a'),
          entry(11, 'b'),
          entry(12, 'c'),
          entry(30, 'x'),
        ]).execute();

        expect(result.every((c) => c.members.length == 2), isTrue);
      },
    );

    test('a third tag that adds nothing is left out', () async {
      // c rides along on every a+b comic, but a+b already explains them, so
      // the triple's lift cannot clear the pair's by the required margin.
      for (var i = 0; i < 8; i++) {
        await keep('pair-$i', <int>[10, 11, 12]);
      }
      for (var i = 0; i < 8; i++) {
        await keep('carrier-$i', <int>[12, 30]);
      }

      final result = await buildUseCase(<LocalTagCatalogEntry>[
        entry(10, 'a'),
        entry(11, 'b'),
        entry(12, 'carrier'),
        entry(30, 'x'),
      ], tripleGainFactor: 1.5).execute();

      final triples = result.where((c) => c.members.length == 3);
      expect(triples, isEmpty);
    });

    test('ignores tags on comics that were never kept', () async {
      for (var i = 0; i < 6; i++) {
        await harness.comicTagRepository.replaceTagIds('seen-$i', <int>[
          10,
          11,
        ]);
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

    test(
      'sorting by count surfaces the combinations kept most often',
      () async {
        // "everywhere" is on 20 of 26 comics, so lift caps near 1.3 for it and
        // it can never top a lift-ranked list — the reason the two sorts exist.
        for (var i = 0; i < 20; i++) {
          await keep('common-$i', <int>[10, 20]);
        }
        for (var i = 0; i < 6; i++) {
          await keep('rare-$i', <int>[30, 40]);
        }

        final useCase = buildUseCase(<LocalTagCatalogEntry>[
          entry(10, 'everywhere'),
          entry(20, 'also-common'),
          entry(30, 'niche-a'),
          entry(40, 'niche-b'),
        ]);

        final byLift = await useCase.execute();
        final byCount = await useCase.execute(sort: TagPreferenceSort.count);

        expect(byLift.first.members.map((m) => m.slug).toSet(), <String>{
          'niche-a',
          'niche-b',
        });
        expect(byCount.first.members.map((m) => m.slug).toSet(), <String>{
          'everywhere',
          'also-common',
        });
      },
    );

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
