import 'package:concept_nhv/application/tags/comic_similarity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A catalog where tag 1 is everywhere and tag 4 is rare.
  const referenceCount = 200000;
  const siteCounts = <int, int>{
    1: 200000, // the most common tag on the site
    2: 50000,
    3: 5000,
    4: 50, // a specific artist
    5: 60,
    6: 40,
  };

  final similarity = ComicSimilarity.fromSiteCounts(
    siteCounts,
    referenceCount: referenceCount,
  );

  group('tagIdf', () {
    test('the most common tag on the site weighs nothing', () {
      expect(
        tagIdf(siteCount: referenceCount, referenceCount: referenceCount),
        0,
      );
    });

    test('rarer tags weigh more', () {
      final common = tagIdf(siteCount: 50000, referenceCount: referenceCount);
      final rare = tagIdf(siteCount: 50, referenceCount: referenceCount);
      expect(rare, greaterThan(common));
      expect(common, greaterThan(0));
    });
  });

  group('ComicSimilarity.between', () {
    test('sharing a rare tag beats sharing a common one', () {
      // The whole reason for idf: both being full colour is not a
      // relationship, both being by the same artist is.
      final viaRareTag = similarity.between(<int>[4, 2], <int>[4, 3]);
      final viaCommonTag = similarity.between(<int>[1, 2], <int>[1, 3]);

      expect(viaRareTag, greaterThan(viaCommonTag));
    });

    test('a comic is most similar to itself', () {
      final self = similarity.between(<int>[2, 3, 4], <int>[2, 3, 4]);

      expect(self, closeTo(1.0, 1e-9));
      expect(
        self,
        greaterThan(similarity.between(<int>[2, 3, 4], <int>[2, 3])),
      );
    });

    test('a comic carrying everything is not similar to everything', () {
      // An anthology collects dozens of artists, so it shares a tag with
      // almost anything. Without normalising by each side's own magnitude it
      // takes every top spot — exactly what a plain sum did in P84.
      final anthology = <int>[1, 2, 3, 4, 5, 6];
      final focused = <int>[4, 5];

      final anthologyMatch = similarity.between(focused, anthology);
      final focusedMatch = similarity.between(focused, <int>[4, 5, 3]);

      expect(focusedMatch, greaterThan(anthologyMatch));
    });

    test('no shared tags means no similarity', () {
      expect(similarity.between(<int>[2, 4], <int>[3, 5]), 0);
    });

    test('an unknown tag is not evidence of anything', () {
      // Shared only via an id the catalog cannot resolve: treating it as
      // weight zero and still counting the pair would let two comics be
      // "alike" on something nobody can name.
      expect(similarity.between(<int>[999], <int>[999]), 0);
    });

    test('the most common tag alone is not a relationship', () {
      expect(similarity.between(<int>[1], <int>[1]), 0);
    });

    test('an empty tag list scores zero', () {
      expect(similarity.between(const <int>[], <int>[4]), 0);
      expect(similarity.between(<int>[4], const <int>[]), 0);
    });

    test('never exceeds one', () {
      final values = <double>[
        similarity.between(<int>[4], <int>[4]),
        similarity.between(<int>[2, 3, 4, 5], <int>[2, 3, 4, 5]),
        similarity.between(<int>[4, 5], <int>[4, 5, 6]),
      ];
      expect(values, everyElement(lessThanOrEqualTo(1.0 + 1e-9)));
    });
  });

  group('ComicSimilarity.strongestSharedTags', () {
    test('names the rarest shared tags first', () {
      final reasons = similarity.strongestSharedTags(
        <int>[1, 2, 4],
        <int>[1, 2, 4],
      );

      expect(reasons, <int>[4, 2], reason: 'tag 1 is too common to mention');
    });

    test('leaves out tags that are not shared', () {
      expect(similarity.strongestSharedTags(<int>[4], <int>[5]), isEmpty);
    });
  });
}
