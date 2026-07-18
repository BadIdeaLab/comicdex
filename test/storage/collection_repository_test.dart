import 'package:concept_nhv/models/collection_type.dart';
import 'package:concept_nhv/models/stored_comic.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_support/storage/sqlite_test_harness.dart';

void main() {
  group('CollectionRepository', () {
    late SqliteTestHarness harness;

    setUp(() async {
      harness = SqliteTestHarness();
      await harness.initialize();
    });

    tearDown(() async {
      await harness.dispose();
    });

    test('loads collection summaries from stored collection entries', () async {
      await harness.comicRepository.upsertComic(
        _storedComic(
          id: '1',
          mediaId: '9',
          title: 'Stored Comic',
          serializedImages:
              '{"pages":[{"t":"j","w":100,"h":200}],"cover":{"t":"j","w":100,"h":200},"thumbnail":{"t":"w","w":50,"h":100}}',
          pages: 1,
        ),
      );
      await harness.collectionRepository.addComicToCollection(
        collectionType: CollectionType.favorite,
        comicId: '1',
      );

      final summaries = await harness.collectionRepository
          .loadCollectionSummaries();
      final favorite = summaries.firstWhere(
        (summary) => summary.collectionName == 'Favorite',
      );

      expect(favorite.collectedCount, 1);
      expect(favorite.thumbnailUrl, contains('thumb.webp'));
    });

    test('replaceCollectionCache rewrites favorite mirror ids', () async {
      await harness.collectionRepository.replaceCollectionCache(
        collectionType: CollectionType.favorite,
        comics: <StoredComic>[
          _storedComic(id: '1', mediaId: '9', title: 'Favorite A'),
          _storedComic(id: '2', mediaId: '10', title: 'Favorite B'),
        ],
      );

      final ids = await harness.collectionRepository.loadCollectedComicIds(
        CollectionType.favorite,
      );

      expect(ids, <String>{'1', '2'});
    });

    test('replaceCollectionCache preserves remote favorite order', () async {
      await harness.collectionRepository.replaceCollectionCache(
        collectionType: CollectionType.favorite,
        comics: <StoredComic>[
          _storedComic(id: '2', mediaId: '10', title: 'Favorite B'),
          _storedComic(id: '1', mediaId: '9', title: 'Favorite A'),
        ],
      );

      final comics = await harness.collectionRepository.loadCollectionComics(
        CollectionType.favorite,
      );

      expect(
        comics.map((comic) => comic.comicId),
        orderedEquals(<String>['2', '1']),
      );
    });
  });
}

StoredComic _storedComic({
  required String id,
  required String mediaId,
  required String title,
  String serializedImages = 'jj',
  int pages = 2,
}) {
  return StoredComic(
    id: id,
    mediaId: mediaId,
    title: title,
    serializedImages: serializedImages,
    pages: pages,
  );
}
