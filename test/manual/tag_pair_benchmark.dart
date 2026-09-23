// Manual benchmark for the P81/P83 combination pass at the real library size.
// Not named *_test.dart on purpose — run it explicitly:
//   flutter test test/manual/tag_pair_benchmark.dart
import 'package:concept_nhv/application/tags/load_tag_cooccurrence_use_case.dart';
import 'package:concept_nhv/models/collection_type.dart';
import 'package:concept_nhv/models/local_tag_catalog_entry.dart';
import 'package:concept_nhv/models/tag_catalog_type.dart';
import 'package:concept_nhv/services/local_tag_catalog_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_support/fakes/fake_blocked_tags_repository.dart';
import '../test_support/storage/sqlite_test_harness.dart';

void main() {
  test('tag combinations at 650 comics x 20 tags', () async {
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

    final useCase = LoadTagCooccurrenceUseCase(
      comicTagRepository: harness.comicTagRepository,
      localTagCatalogService:
          LocalTagCatalogService.fromEntries(<LocalTagCatalogEntry>[
            for (var id = 0; id < 400; id++)
              LocalTagCatalogEntry(
                id: id,
                type: TagCatalogType.tag,
                name: 'tag-$id',
                slug: 'tag-$id',
                count: 1000,
              ),
          ]),
      blockedTagsRepository: FakeBlockedTagsRepository(),
    );

    final stopwatch = Stopwatch()..start();
    final combinations = await useCase.execute();
    stopwatch.stop();

    // ignore: avoid_print
    print(
      'combinations: ${combinations.length} shown in '
      '${stopwatch.elapsedMilliseconds} ms',
    );
    expect(combinations, isNotEmpty);
  });
}
