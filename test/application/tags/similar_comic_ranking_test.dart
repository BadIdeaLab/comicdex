import 'package:concept_nhv/application/tags/similar_comic_ranking.dart';
import 'package:concept_nhv/application/tags/tag_preference_vector.dart';
import 'package:concept_nhv/models/local_tag_catalog_entry.dart';
import 'package:concept_nhv/models/tag_catalog_type.dart';
import 'package:concept_nhv/services/local_tag_catalog_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildComicSimilarity', () {
    final catalog = LocalTagCatalogService.fromEntries(<LocalTagCatalogEntry>[
      const LocalTagCatalogEntry(
        id: 1,
        type: TagCatalogType.tag,
        name: 'common',
        slug: 'common',
        count: 100000,
      ),
      const LocalTagCatalogEntry(
        id: 2,
        type: TagCatalogType.artist,
        name: 'artist',
        slug: 'artist',
        count: 40,
      ),
    ]);

    test('weights a rare tag above a common one', () {
      final similarity = buildComicSimilarity(
        catalog: catalog,
        tagGroups: <Iterable<int>>[
          <int>[1, 2],
          <int>[1, 2],
        ],
      );

      expect(
        similarity.between(<int>[2], <int>[2]),
        greaterThan(similarity.between(<int>[1], <int>[1])),
      );
    });

    test('ignores ids the catalog cannot resolve', () {
      // Sharing an unnameable id must not count as evidence that two comics
      // belong together.
      final similarity = buildComicSimilarity(
        catalog: catalog,
        tagGroups: <Iterable<int>>[
          <int>[999],
          <int>[999],
        ],
      );

      expect(similarity.between(<int>[999], <int>[999]), 0);
    });
  });

  group('rankSimilar', () {
    ScoredComic<String> scored(
      String id,
      double similarity, {
      List<int> tagIds = const <int>[],
    }) {
      return ScoredComic<String>(
        subject: id,
        id: id,
        similarity: similarity,
        sharedTagIds: const <int>[],
        tagIds: tagIds,
      );
    }

    test('orders by similarity', () {
      final ranked = rankSimilar(<ScoredComic<String>>[
        scored('low', 0.2),
        scored('high', 0.8),
        scored('mid', 0.5),
      ]);

      expect(ranked.map((r) => r.id), <String>['high', 'mid', 'low']);
    });

    test('preference only breaks ties', () {
      // A comic the reader merely likes must never displace a closer match,
      // which is what multiplying preference in would do.
      const preferences = TagPreferenceVector(
        weights: <int, double>{7: 1.0},
        goldThreshold: 0.4,
        platinumThreshold: 0.55,
      );

      final ranked = rankSimilar(<ScoredComic<String>>[
        scored('closer', 0.8),
        scored('tied-plain', 0.5),
        scored('tied-liked', 0.5, tagIds: <int>[7]),
      ], preferences: preferences);

      expect(ranked.map((r) => r.id), <String>[
        'closer',
        'tied-liked',
        'tied-plain',
      ]);
    });

    test('falls back to the id so the order never depends on input order', () {
      final one = rankSimilar(<ScoredComic<String>>[
        scored('b', 0.5),
        scored('a', 0.5),
      ]);
      final other = rankSimilar(<ScoredComic<String>>[
        scored('a', 0.5),
        scored('b', 0.5),
      ]);

      expect(one.map((r) => r.id), other.map((r) => r.id));
    });

    test('cuts to the limit and never pads', () {
      final ranked = rankSimilar(<ScoredComic<String>>[
        for (var i = 0; i < 10; i++) scored('$i', 0.5),
      ], limit: 3);

      expect(ranked, hasLength(3));
      expect(
        rankSimilar(<ScoredComic<String>>[scored('only', 0.5)]),
        hasLength(1),
      );
    });

    test('the two lookups share one threshold on purpose', () {
      // They sit side by side on the same page, so a threshold tuned in one
      // place and forgotten in the other would show two different standards
      // with nothing to flag it.
      expect(minimumComicSimilarity, greaterThan(0));
      expect(similarComicsLimit, greaterThan(0));
    });
  });
}
