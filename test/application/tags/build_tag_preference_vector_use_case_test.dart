import 'package:concept_nhv/application/tags/build_tag_preference_vector_use_case.dart';
import 'package:concept_nhv/application/tags/load_tag_preferences_use_case.dart';
import 'package:concept_nhv/application/tags/tag_preference_vector.dart';
import 'package:concept_nhv/models/collection_type.dart';
import 'package:concept_nhv/models/local_tag_catalog_entry.dart';
import 'package:concept_nhv/models/tag_catalog_type.dart';
import 'package:concept_nhv/services/local_tag_catalog_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_support/fakes/fake_blocked_tags_repository.dart';
import '../../test_support/storage/sqlite_test_harness.dart';

void main() {
  group('TagPreferenceVector', () {
    const vector = TagPreferenceVector(
      weights: <int, double>{1: 1.0, 2: 1.0, 3: 0.2},
      goldThreshold: 0.9,
      platinumThreshold: 1.3,
    );

    test('averages the matched weights, dampened by their count', () {
      // 1.2 / sqrt(2), not 1.2.
      expect(vector.scoreComic(<int>[1, 3]), closeTo(0.849, 0.001));
    });

    test('hitting more of the ranking still scores higher', () {
      expect(
        vector.scoreComic(<int>[1, 2]),
        greaterThan(vector.scoreComic(<int>[1])),
      );
    });

    test('a pile of ordinary tags cannot beat a few strong ones', () {
      // The failure that took this design down on the real library:
      // anthologies carry dozens of tags and swamped everything the user
      // actually reads.
      final many = TagPreferenceVector(
        weights: <int, double>{
          for (var id = 10; id < 50; id++) id: 0.2,
          1: 1.0,
          2: 1.0,
        },
        goldThreshold: 0.9,
        platinumThreshold: 1.3,
      );
      final anthology = <int>[for (var id = 10; id < 50; id++) id];

      expect(
        many.scoreComic(<int>[1, 2]),
        greaterThan(many.scoreComic(anthology)),
      );
    });

    test('tags outside the ranking neither add nor dilute', () {
      // Language and group ids are not part of the taste model, so they must
      // not count toward the divisor either.
      expect(vector.scoreComic(<int>[1, 999]), closeTo(1.0, 1e-9));
    });

    test('counts a repeated tag once', () {
      expect(vector.scoreComic(<int>[2, 2, 2]), closeTo(1.0, 1e-9));
    });

    test('scores a comic with no tag ids as zero, with no badge', () {
      expect(vector.scoreComic(const <int>[]), 0);
      expect(vector.tierFor(const <int>[]), PreferenceTier.none);
    });

    test('awards each tier at its threshold', () {
      expect(vector.tierFor(<int>[1, 2]), PreferenceTier.platinum);
      expect(vector.tierFor(<int>[1]), PreferenceTier.gold);
      expect(vector.tierFor(<int>[3]), PreferenceTier.none);
    });

    test('awards nothing while the thresholds are unknown', () {
      const unranked = TagPreferenceVector(
        weights: <int, double>{1: 1.0},
        goldThreshold: null,
        platinumThreshold: null,
      );
      expect(unranked.canRank, isFalse);
      expect(unranked.tierFor(<int>[1]), PreferenceTier.none);
    });

    test('the best of a mediocre batch still gets no badge', () {
      // Thresholds come from the whole library, so a page whose best comic is
      // ordinary must come back bare. A per-page threshold would hand this
      // batch a platinum badge for being the least bad.
      final tiers = <PreferenceTier>[
        for (final tagIds in <List<int>>[
          <int>[3],
          <int>[3, 999],
          <int>[3, 3],
        ])
          vector.tierFor(tagIds),
      ];
      expect(tiers, everyElement(PreferenceTier.none));
    });
  });

  group('BuildTagPreferenceVectorUseCase', () {
    late SqliteTestHarness harness;
    late FakeBlockedTagsRepository blockedTags;

    // A spread of site-wide counts, which is what makes the affinities span
    // orders of magnitude the way the real catalog does.
    const ubiquitousTag = 100;
    const rareTag = 119;

    /// Sits *below* the ubiquitous tag in affinity, so the ubiquitous one is
    /// not the floor of the range. Without it a log scale maps the ubiquitous
    /// tag to exactly zero and the test passes for the wrong reason — on the
    /// real library it sat at 0.34, well above the floor.
    const floorTag = 99;

    final catalog = <LocalTagCatalogEntry>[
      const LocalTagCatalogEntry(
        id: floorTag,
        type: TagCatalogType.tag,
        name: 'floor',
        slug: 'floor',
        count: 500000,
      ),
      const LocalTagCatalogEntry(
        id: ubiquitousTag,
        type: TagCatalogType.tag,
        name: 'ubiquitous',
        slug: 'ubiquitous',
        count: 200000,
      ),
      for (var i = 1; i <= 19; i++)
        LocalTagCatalogEntry(
          id: ubiquitousTag + i,
          type: TagCatalogType.tag,
          name: 'tag$i',
          slug: 'tag$i',
          // 100000 down to about 40: a long tail, like the real catalog.
          count: (100000 / (i * i)).round() + 1,
        ),
    ];

    BuildTagPreferenceVectorUseCase buildUseCase() {
      return BuildTagPreferenceVectorUseCase(
        loadTagPreferencesUseCase: LoadTagPreferencesUseCase(
          comicTagRepository: harness.comicTagRepository,
          localTagCatalogService: LocalTagCatalogService.fromEntries(catalog),
          blockedTagsRepository: blockedTags,
        ),
        comicTagRepository: harness.comicTagRepository,
      );
    }

    Future<void> favorite(String comicId, List<int> tagIds) async {
      await harness.comicTagRepository.replaceTagIds(comicId, tagIds);
      await harness.collectionRepository.addComicToCollection(
        collectionType: CollectionType.favorite,
        comicId: comicId,
      );
    }

    /// Every catalog tag on at least three comics, so the whole spread is
    /// eligible for ranking.
    Future<void> seedLibrary({int comics = 60}) async {
      for (var i = 0; i < comics; i++) {
        await favorite('c$i', <int>[
          ubiquitousTag,
          if (i < 3) floorTag,
          for (var t = 1; t <= 19; t++)
            if (i % t == 0) ubiquitousTag + t,
        ]);
      }
    }

    setUp(() async {
      harness = SqliteTestHarness();
      await harness.initialize();
      blockedTags = FakeBlockedTagsRepository();
    });

    tearDown(() async {
      await harness.dispose();
    });

    test('keeps a ubiquitous tag near zero', () async {
      await seedLibrary();

      final vector = await buildUseCase().execute();

      // The whole reason for ranking by affinity: a tag on 200k galleries
      // site-wide says nothing about taste, whatever its share of the
      // library. Log-normalizing put this at 0.34 on the real library and
      // the badges went to whatever carried the most tags.
      expect(vector.weights[ubiquitousTag], lessThan(0.1));
    });

    test('preserves the ranking order and caps the top at one', () async {
      await seedLibrary();

      final vector = await buildUseCase().execute();
      final rarest = vector.weights[rareTag]!;

      expect(rarest, 1.0);
      expect(rarest, greaterThan(vector.weights[ubiquitousTag]!));
      expect(vector.weights.values, everyElement(lessThanOrEqualTo(1.0)));
    });

    test('leaves out tags too thin to rank', () async {
      await seedLibrary();
      // Two comics only, under the ranking's minimum of three.
      await favorite('thin-1', <int>[ubiquitousTag, 999]);
      await favorite('thin-2', <int>[ubiquitousTag, 999]);

      final vector = await buildUseCase().execute();

      expect(vector.weights.containsKey(999), isFalse);
    });

    test('withholds thresholds until the library is big enough', () async {
      await seedLibrary(comics: 20);

      final vector = await buildUseCase().execute();

      expect(vector.weights, isNotEmpty);
      expect(vector.canRank, isFalse);
    });

    test('uses thresholds calibrated against the home feed', () async {
      await seedLibrary();

      final vector = await buildUseCase().execute();

      expect(vector.canRank, isTrue);
      // Fixed, not cut from this library: thresholds taken from the kept
      // library put the bar at 0.72, which nothing on the open site reached,
      // and the home feed showed no badge at all.
      expect(
        vector.goldThreshold,
        BuildTagPreferenceVectorUseCase.goldThreshold,
      );
      expect(
        vector.platinumThreshold,
        BuildTagPreferenceVectorUseCase.platinumThreshold,
      );
    });

    test('scores a rare tag above a ubiquitous one', () async {
      await seedLibrary();

      final vector = await buildUseCase().execute();

      expect(
        vector.scoreComic(<int>[rareTag]),
        greaterThan(vector.scoreComic(<int>[ubiquitousTag])),
      );
    });
  });
}
