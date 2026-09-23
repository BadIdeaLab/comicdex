import 'package:concept_nhv/application/tags/load_tag_coverage_use_case.dart';
import 'package:concept_nhv/models/collection_type.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_support/fixtures/sample_comic.dart';
import '../../test_support/storage/sqlite_test_harness.dart';

void main() {
  group('LoadTagCoverageUseCase', () {
    late SqliteTestHarness harness;
    late LoadTagCoverageUseCase useCase;

    setUp(() async {
      harness = SqliteTestHarness();
      await harness.initialize();
      useCase = LoadTagCoverageUseCase(
        comicTagRepository: harness.comicTagRepository,
      );
    });

    tearDown(() async {
      await harness.dispose();
    });

    test('counts kept comics and how many of them carry tags', () async {
      for (final id in <String>['1', '2', '3']) {
        await harness.collectionRepository.addComicToCollection(
          collectionType: CollectionType.favorite,
          comicId: id,
        );
      }
      await harness.comicTagRepository.replaceTagIds('1', <int>[10]);
      await harness.comicTagRepository.replaceTagIds('2', <int>[10, 20]);
      // A downloaded comic counts as kept, and it is tagged (sample tag 1).
      await harness.downloadedLibraryRepository.saveDownloadedComic(
        comic: sampleComic(id: '4'),
        rootDirectoryPath: '/downloads/4',
        coverLocalPath: null,
      );

      final coverage = await useCase.execute();

      expect(coverage.keptComics, 4);
      expect(coverage.taggedComics, 3);
      expect(coverage.ratio, 0.75);
    });

    test('a comic that is both favorited and downloaded counts once', () async {
      await harness.collectionRepository.addComicToCollection(
        collectionType: CollectionType.favorite,
        comicId: '4',
      );
      await harness.downloadedLibraryRepository.saveDownloadedComic(
        comic: sampleComic(id: '4'),
        rootDirectoryPath: '/downloads/4',
        coverLocalPath: null,
      );

      final coverage = await useCase.execute();

      expect(coverage.keptComics, 1);
      expect(coverage.taggedComics, 1);
    });

    test('nothing kept means a zero ratio rather than a crash', () async {
      final coverage = await useCase.execute();

      expect(coverage.keptComics, 0);
      expect(coverage.ratio, 0);
    });
  });
}
