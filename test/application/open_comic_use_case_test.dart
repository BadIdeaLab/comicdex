import 'package:concept_nhv/application/reader/open_comic_use_case.dart';
import 'package:concept_nhv/models/collection_type.dart';
import 'package:concept_nhv/models/comic.dart';
import 'package:concept_nhv/models/stored_comic.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_support/fixtures/sample_comic.dart';
import '../test_support/storage/sqlite_test_harness.dart';

void main() {
  group('OpenComicUseCase tag ids', () {
    late SqliteTestHarness harness;
    late OpenComicUseCase useCase;

    setUp(() async {
      harness = SqliteTestHarness();
      await harness.initialize();
      useCase = OpenComicUseCase(
        comicRepository: harness.comicRepository,
        collectionRepository: harness.collectionRepository,
        comicTagRepository: harness.comicTagRepository,
      );
    });

    tearDown(() async {
      await harness.dispose();
    });

    test('records the tag ids of an opened comic alongside history', () async {
      await useCase.execute(sampleComic(id: '5'));

      expect(await harness.comicTagRepository.loadTagIds('5'), <int>{1});
      expect(
        await harness.collectionRepository.loadCollectedComicIds(
          CollectionType.history,
        ),
        <String>{'5'},
      );
    });

    // Degraded metadata (rebuilt from a download) must not overwrite the
    // stored comic row, but its tag list is complete and still gets stored.
    test(
      'records tag ids even for degraded metadata over a stored comic',
      () async {
        await harness.comicRepository.upsertComic(
          StoredComic.fromComic(sampleComic(id: '5')),
        );

        await useCase.execute(sampleComic(id: '5'), isDegradedMetadata: true);

        expect(await harness.comicTagRepository.loadTagIds('5'), <int>{1});
      },
    );

    test('counts each open and keeps the history timestamp fresh', () async {
      await useCase.execute(sampleComic(id: '5'));
      await useCase.execute(sampleComic(id: '5'));
      await useCase.execute(sampleComic(id: '5'));

      final row = await harness.localDatabase
          .customSelect(
            "SELECT read_count, dateCreated FROM Collection "
            "WHERE name = 'History' AND comicid = '5'",
          )
          .getSingle();
      expect(row.read<int>('read_count'), 3);
      expect(
        DateTime.parse(
          row.read<String>('dateCreated'),
        ).isAfter(DateTime.now().subtract(const Duration(minutes: 1))),
        isTrue,
      );
    });

    test('a comic without tags leaves previously stored ids alone', () async {
      await harness.comicTagRepository.replaceTagIds('5', <int>[2937]);

      await useCase.execute(sampleComic(id: '5').copyWith(tags: const []));

      expect(await harness.comicTagRepository.loadTagIds('5'), <int>{2937});
    });
  });

  group('Comic.effectiveTagIds', () {
    test('prefers bare tagIds from listings', () {
      final comic = sampleComic().copyWith(tagIds: <int>[2937]);

      expect(comic.effectiveTagIds, <int>[2937]);
    });

    test('falls back to the ids inside detail tags', () {
      expect(sampleComic().effectiveTagIds, <int>[1]);
    });
  });
}
