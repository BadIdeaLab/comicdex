// Manual benchmark for the P81 co-occurrence query at the real library size.
// Not named *_test.dart on purpose — run it explicitly:
//   flutter test test/manual/tag_pair_benchmark.dart
import 'package:concept_nhv/models/collection_type.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_support/storage/sqlite_test_harness.dart';

void main() {
  test('co-occurrence query at 650 comics x 20 tags', () async {
    final harness = SqliteTestHarness();
    await harness.initialize();
    addTearDown(harness.dispose);

    // 650 kept comics, 20 tags each drawn from a 400-tag vocabulary — close
    // to a real library, where a few tags are everywhere and most are rare.
    for (var comic = 0; comic < 650; comic++) {
      final tagIds = <int>{
        for (var i = 0; i < 20; i++) (comic * 7 + i * 13) % 400,
      };
      await harness.comicTagRepository.replaceTagIds('$comic', tagIds);
      await harness.collectionRepository.addComicToCollection(
        collectionType: CollectionType.favorite,
        comicId: '$comic',
      );
    }

    final stopwatch = Stopwatch()..start();
    final pairs = await harness.comicTagRepository.loadTagPairCounts();
    stopwatch.stop();

    // ignore: avoid_print
    print(
      'loadTagPairCounts: ${pairs.length} pairs in ${stopwatch.elapsedMilliseconds} ms',
    );
    expect(pairs, isNotEmpty);
  });
}
