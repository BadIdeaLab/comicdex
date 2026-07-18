import 'package:concept_nhv/models/collected_comic.dart';
import 'package:concept_nhv/models/collection_summary.dart';
import 'package:concept_nhv/models/collection_type.dart';
import 'package:concept_nhv/models/comic_card_data.dart';
import 'package:concept_nhv/models/stored_comic.dart';
import 'package:concept_nhv/storage/local_database.dart';
import 'package:drift/drift.dart' as drift;

class CollectionRepository {
  const CollectionRepository({required this.localDatabase});

  final LocalDatabase localDatabase;

  Future<int> addComicToCollection({
    required CollectionType collectionType,
    required String comicId,
    String? dateCreated,
  }) async {
    return localDatabase
        .into(localDatabase.collections)
        .insert(
          CollectionsCompanion.insert(
            name: collectionType.storageName,
            comicid: comicId,
            dateCreated: dateCreated ?? DateTime.now().toIso8601String(),
          ),
          mode: drift.InsertMode.insertOrReplace,
        );
  }

  Future<int> removeComicFromCollection({
    required CollectionType collectionType,
    required String comicId,
  }) async {
    final statement = localDatabase.delete(localDatabase.collections)
      ..where((table) {
        return table.name.equals(collectionType.storageName) &
            table.comicid.equals(comicId);
      });
    return statement.go();
  }

  /// Incrementally adds a single comic to a collection without touching any
  /// other rows — upserts [comic] into the `comics` table (so it survives the
  /// join in [loadCollectionComics]) and inserts a `collections` row with
  /// [favoriteRank] `-1` so it sorts ahead of comics written by a full
  /// [replaceCollectionCache] sync (which ranks from `0`). Used by
  /// `ToggleFavoriteUseCase` to avoid a full remote resync for a single
  /// favorite toggle (see .codex/phases/P49-lightweight-favorite-toggle.md).
  Future<void> upsertComicAndAddToCollection({
    required CollectionType collectionType,
    required StoredComic comic,
  }) async {
    await localDatabase.transaction(() async {
      await localDatabase
          .into(localDatabase.comics)
          .insert(
            ComicsCompanion.insert(
              id: comic.id,
              mid: comic.mediaId,
              title: comic.title,
              images: comic.serializedImages,
              pages: comic.pages,
            ),
            mode: drift.InsertMode.insertOrReplace,
          );
      await localDatabase
          .into(localDatabase.collections)
          .insert(
            CollectionsCompanion.insert(
              name: collectionType.storageName,
              comicid: comic.id,
              dateCreated: DateTime.now().toIso8601String(),
              favoriteRank: const drift.Value(-1),
            ),
            mode: drift.InsertMode.insertOrReplace,
          );
    });
  }

  Future<List<CollectedComic>> loadCollectionComics(
    CollectionType collectionType,
  ) async {
    final rows = await _loadCollectionJoinRows(collectionType: collectionType);
    return rows
        .where((row) => row.readTableOrNull(localDatabase.comics) != null)
        .map(_mapCollectedComic)
        .toList();
  }

  Future<Set<String>> loadCollectedComicIds(
    CollectionType collectionType,
  ) async {
    final query = localDatabase.select(localDatabase.collections)
      ..where((table) => table.name.equals(collectionType.storageName));
    final rows = await query.get();
    return rows.map((row) => row.comicid).toSet();
  }

  Future<List<CollectionSummary>> loadCollectionSummaries() async {
    final allCollections = await _loadAllCollectedComics();
    final grouped = <CollectionType, List<CollectedComic>>{
      for (final type in CollectionType.values) type: <CollectedComic>[],
    };

    for (final comic in allCollections) {
      final type = CollectionType.fromStorageName(comic.collectionName);
      if (type != null) {
        grouped[type]!.add(comic);
      }
    }

    return CollectionType.values.map((type) {
      final entries = grouped[type]!;
      if (entries.isEmpty) {
        return ComicCardData.placeholderSummary(
          collectionName: type.displayName,
        );
      }

      final firstComic = ComicCardData.fromStoredComic(entries.first.comic);
      return CollectionSummary(
        collectionName: type.displayName,
        collectedCount: entries.length,
        thumbnailUrl: firstComic.thumbnailUrl,
        thumbnailWidth: firstComic.thumbnailWidth,
        thumbnailHeight: firstComic.thumbnailHeight,
      );
    }).toList();
  }

  Future<List<CollectedComic>> _loadAllCollectedComics() async {
    final rows = await _loadCollectionJoinRows();
    return rows
        .where((row) => row.readTableOrNull(localDatabase.comics) != null)
        .map(_mapCollectedComic)
        .toList();
  }

  Future<void> replaceCollectionCache({
    required CollectionType collectionType,
    required Iterable<StoredComic> comics,
  }) async {
    final now = DateTime.now().toIso8601String();
    final comicsList = comics.toList();
    await localDatabase.transaction(() async {
      final deleteStatement = localDatabase.delete(localDatabase.collections)
        ..where((table) => table.name.equals(collectionType.storageName));
      await deleteStatement.go();

      await localDatabase.batch((batch) {
        for (var i = 0; i < comicsList.length; i++) {
          final comic = comicsList[i];
          batch.insert(
            localDatabase.comics,
            ComicsCompanion.insert(
              id: comic.id,
              mid: comic.mediaId,
              title: comic.title,
              images: comic.serializedImages,
              pages: comic.pages,
            ),
            mode: drift.InsertMode.insertOrReplace,
          );
          batch.insert(
            localDatabase.collections,
            CollectionsCompanion.insert(
              name: collectionType.storageName,
              comicid: comic.id,
              dateCreated: now,
              favoriteRank: drift.Value(i),
            ),
            mode: drift.InsertMode.insertOrReplace,
          );
        }
      });
    });
  }

  Future<List<drift.TypedResult>> _loadCollectionJoinRows({
    CollectionType? collectionType,
  }) {
    final collectionQuery = localDatabase.select(localDatabase.collections);
    if (collectionType != null) {
      collectionQuery.where(
        (table) => table.name.equals(collectionType.storageName),
      );
    }
    collectionQuery.orderBy([
      // Rows with favoriteRank (favorites) sort before rows without (0 < 1).
      (table) => drift.OrderingTerm.asc(table.favoriteRank.isNull()),
      // Within favorites: lower rank = more recently favorited = first.
      (table) => drift.OrderingTerm.asc(table.favoriteRank),
      // For non-favorites (favoriteRank IS NULL): sort by dateCreated desc.
      (table) => drift.OrderingTerm.desc(table.dateCreated),
    ]);

    return collectionQuery.join([
      drift.leftOuterJoin(
        localDatabase.comics,
        localDatabase.comics.id.equalsExp(localDatabase.collections.comicid),
      ),
    ]).get();
  }

  CollectedComic _mapCollectedComic(drift.TypedResult row) {
    final collection = row.readTable(localDatabase.collections);
    final comic = row.readTable(localDatabase.comics);
    return CollectedComic(
      collectionName: collection.name,
      comicId: collection.comicid,
      dateCreated: DateTime.parse(collection.dateCreated),
      comic: StoredComic(
        id: comic.id,
        mediaId: comic.mid,
        title: comic.title,
        serializedImages: comic.images,
        pages: comic.pages,
      ),
    );
  }
}
