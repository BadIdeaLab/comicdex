import 'package:concept_nhv/models/collection_type.dart';
import 'package:concept_nhv/models/tag_source_count.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_support/fixtures/sample_comic.dart';

import '../test_support/storage/sqlite_test_harness.dart';

void main() {
  group('ComicTagRepository', () {
    late SqliteTestHarness harness;

    setUp(() async {
      harness = SqliteTestHarness();
      await harness.initialize();
    });

    tearDown(() async {
      await harness.dispose();
    });

    test('stores tag ids for a comic', () async {
      await harness.comicTagRepository.replaceTagIds('1', <int>[2937, 12227]);

      expect(await harness.comicTagRepository.loadTagIds('1'), <int>{
        2937,
        12227,
      });
    });

    test('replaces the previous tag ids instead of merging', () async {
      await harness.comicTagRepository.replaceTagIds('1', <int>[2937, 12227]);
      await harness.comicTagRepository.replaceTagIds('1', <int>[35762]);

      expect(await harness.comicTagRepository.loadTagIds('1'), <int>{35762});
    });

    // The rule the whole table exists for: a source without tags must never
    // erase what a richer source stored.
    test('an empty list leaves existing tag ids untouched', () async {
      await harness.comicTagRepository.replaceTagIds('1', <int>[2937]);
      await harness.comicTagRepository.replaceTagIds('1', const <int>[]);

      expect(await harness.comicTagRepository.loadTagIds('1'), <int>{2937});
    });

    test(
      'batch replaces only the comics it names and skips empty ones',
      () async {
        await harness.comicTagRepository.replaceTagIds('1', <int>[1]);
        await harness.comicTagRepository.replaceTagIds('2', <int>[2]);
        await harness.comicTagRepository.replaceTagIds('3', <int>[3]);

        await harness.comicTagRepository.replaceTagIdsForComics(
          <String, Iterable<int>>{
            '1': <int>[10, 11],
            '2': const <int>[],
          },
        );

        expect(await harness.comicTagRepository.loadTagIds('1'), <int>{10, 11});
        expect(await harness.comicTagRepository.loadTagIds('2'), <int>{2});
        expect(await harness.comicTagRepository.loadTagIds('3'), <int>{3});
      },
    );

    test('duplicate ids in the input are stored once', () async {
      await harness.comicTagRepository.replaceTagIds('1', <int>[5, 5, 6]);

      expect(await harness.comicTagRepository.loadTagIds('1'), <int>{5, 6});
    });

    group('loadTagSourceCounts', () {
      Future<void> addTo(CollectionType type, String comicId) {
        return harness.collectionRepository.addComicToCollection(
          collectionType: type,
          comicId: comicId,
        );
      }

      Map<int, String> summarize(List<TagSourceCount> counts) => <int, String>{
        for (final c in counts)
          c.tagId:
              'f${c.favoriteCount} d${c.downloadedCount} h${c.historyCount}',
      };

      test('counts each comic once per source it belongs to', () async {
        // Comic A: favorite + history. Comic B: favorite only.
        // Comic C: downloaded only (sampleComic carries tag id 1).
        await harness.comicTagRepository.replaceTagIds('A', <int>[100, 200]);
        await harness.comicTagRepository.replaceTagIds('B', <int>[100]);
        await addTo(CollectionType.favorite, 'A');
        await addTo(CollectionType.history, 'A');
        await addTo(CollectionType.favorite, 'B');
        await harness.downloadedLibraryRepository.saveDownloadedComic(
          comic: sampleComic(id: 'C'),
          rootDirectoryPath: '/downloads/C',
          coverLocalPath: null,
        );

        expect(
          summarize(await harness.comicTagRepository.loadTagSourceCounts()),
          <int, String>{100: 'f2 d0 h1', 200: 'f1 d0 h1', 1: 'f0 d1 h0'},
        );
      });

      test('ignores tag rows of comics that left every source', () async {
        await harness.comicTagRepository.replaceTagIds('A', <int>[100]);
        await addTo(CollectionType.favorite, 'A');
        await harness.collectionRepository.removeComicFromCollection(
          collectionType: CollectionType.favorite,
          comicId: 'A',
        );

        expect(await harness.comicTagRepository.loadTagSourceCounts(), isEmpty);
      });

      test('the Next collection does not count as any source', () async {
        await harness.comicTagRepository.replaceTagIds('A', <int>[100]);
        await addTo(CollectionType.next, 'A');

        expect(await harness.comicTagRepository.loadTagSourceCounts(), isEmpty);
      });
    });
  });
}
