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

    // Regression: the old insertOrReplace blanked every column it did not
    // pass, so re-adding a favorite dropped its rank to NULL (last place).
    test('adding an existing favorite keeps its rank and read count', () async {
      await harness.collectionRepository.replaceCollectionCache(
        collectionType: CollectionType.favorite,
        comics: <StoredComic>[
          _storedComic(id: 'a', mediaId: 'm', title: 'A'),
          _storedComic(id: 'b', mediaId: 'm', title: 'B'),
        ],
      );

      await harness.collectionRepository.addComicToCollection(
        collectionType: CollectionType.favorite,
        comicId: 'b',
      );

      final row = await harness.localDatabase
          .customSelect(
            "SELECT favorite_rank FROM Collection "
            "WHERE name = 'Favorite' AND comicid = 'b'",
          )
          .getSingle();
      expect(row.read<int?>('favorite_rank'), 1);
      expect(
        await harness.collectionRepository.loadFavoriteIdsInOrder(),
        <String>['a', 'b'],
      );
    });

    group('mergeFavoritePrefix', () {
      StoredComic comic(String id) => _storedComic(
        id: id,
        mediaId: 'm$id',
        title: 'Comic $id',
        serializedImages: '{}',
        pages: 1,
      );

      Future<void> seedFavorites(List<String> ids) {
        return harness.collectionRepository.replaceCollectionCache(
          collectionType: CollectionType.favorite,
          comics: ids.map(comic),
        );
      }

      test('puts new favorites first and keeps the rest in order', () async {
        await seedFavorites(<String>['a', 'b', 'c']);

        await harness.collectionRepository.mergeFavoritePrefix(<StoredComic>[
          comic('x'),
          comic('y'),
          comic('a'),
        ]);

        expect(
          await harness.collectionRepository.loadFavoriteIdsInOrder(),
          <String>['x', 'y', 'a', 'b', 'c'],
        );
        final loaded = await harness.collectionRepository.loadCollectionComics(
          CollectionType.favorite,
        );
        expect(loaded.first.comic.title, 'Comic x');
      });

      test('moves a re-favorited old comic to the front', () async {
        await seedFavorites(<String>['a', 'b', 'c']);

        await harness.collectionRepository.mergeFavoritePrefix(<StoredComic>[
          comic('c'),
          comic('a'),
          comic('b'),
        ]);

        expect(
          await harness.collectionRepository.loadFavoriteIdsInOrder(),
          <String>['c', 'a', 'b'],
        );
      });

      test('normalizes in-app toggles (rank -1) and removes nothing', () async {
        await seedFavorites(<String>['a', 'b']);
        await harness.collectionRepository.upsertComicAndAddToCollection(
          collectionType: CollectionType.favorite,
          comic: comic('t'),
        );

        await harness.collectionRepository.mergeFavoritePrefix(<StoredComic>[
          comic('t'),
          comic('a'),
        ]);

        expect(
          await harness.collectionRepository.loadFavoriteIdsInOrder(),
          <String>['t', 'a', 'b'],
        );
        final ranks = await harness.localDatabase
            .customSelect(
              "SELECT favorite_rank FROM Collection WHERE name = 'Favorite' "
              'ORDER BY favorite_rank',
            )
            .get();
        expect(ranks.map((r) => r.read<int>('favorite_rank')), <int>[0, 1, 2]);
      });

      test('leaves other collections untouched', () async {
        await seedFavorites(<String>['a']);
        await harness.collectionRepository.addComicToCollection(
          collectionType: CollectionType.history,
          comicId: 'a',
        );

        await harness.collectionRepository.mergeFavoritePrefix(<StoredComic>[
          comic('x'),
        ]);

        expect(
          await harness.collectionRepository.loadCollectedComicIds(
            CollectionType.history,
          ),
          <String>{'a'},
        );
      });
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
