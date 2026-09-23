import 'package:concept_nhv/models/collection_type.dart';
import 'package:concept_nhv/models/tag_source_count.dart';
import 'package:concept_nhv/storage/local_database.dart';
import 'package:drift/drift.dart' as drift;

/// Reads and writes [ComicTagIds]. See
/// .codex/phases/P76-comic-tag-id-storage.md.
class ComicTagRepository {
  const ComicTagRepository({required this.localDatabase});

  final LocalDatabase localDatabase;

  /// Replaces the stored tag ids of [comicId] with [tagIds].
  ///
  /// An empty [tagIds] is a no-op, never a clear: callers pass whatever the
  /// comic in hand carries, and "this source had no tags" must not erase ids
  /// an earlier, richer source stored.
  Future<void> replaceTagIds(String comicId, Iterable<int> tagIds) {
    return replaceTagIdsForComics(<String, Iterable<int>>{comicId: tagIds});
  }

  /// Batch form of [replaceTagIds] — one transaction for a whole favorites
  /// sync. Entries with no tag ids are skipped the same way.
  Future<void> replaceTagIdsForComics(
    Map<String, Iterable<int>> tagIdsByComicId,
  ) async {
    final entries = <String, Set<int>>{
      for (final entry in tagIdsByComicId.entries)
        if (entry.value.isNotEmpty) entry.key: entry.value.toSet(),
    };
    if (entries.isEmpty) return;

    await localDatabase.batch((batch) {
      for (final entry in entries.entries) {
        batch.deleteWhere(
          localDatabase.comicTagIds,
          (table) => table.comicId.equals(entry.key),
        );
        batch.insertAll(
          localDatabase.comicTagIds,
          entry.value.map(
            (tagId) =>
                ComicTagIdsCompanion.insert(comicId: entry.key, tagId: tagId),
          ),
          mode: drift.InsertMode.insertOrIgnore,
        );
      }
    });
  }

  Future<Set<int>> loadTagIds(String comicId) async {
    final query = localDatabase.select(localDatabase.comicTagIds)
      ..where((table) => table.comicId.equals(comicId));
    final rows = await query.get();
    return rows.map((row) => row.tagId).toSet();
  }

  /// Per-tag comic counts across favorites, downloads and history.
  ///
  /// Membership is decided by joining through `Collection` and
  /// `DownloadedComic`, so rows left behind by a comic that has since left
  /// every source simply drop out rather than needing cleanup.
  Future<List<TagSourceCount>> loadTagSourceCounts() async {
    final rows = await localDatabase
        .customSelect(
          'SELECT t.tag_id, '
          'SUM(EXISTS(SELECT 1 FROM Collection c '
          'WHERE c.comicid = t.comic_id AND c.name = ?1) '
          'OR EXISTS(SELECT 1 FROM DownloadedComic d '
          'WHERE d.comic_id = t.comic_id)) AS collected_count, '
          'SUM(EXISTS(SELECT 1 FROM Collection c '
          'WHERE c.comicid = t.comic_id AND c.name = ?1)) AS favorite_count, '
          'SUM(EXISTS(SELECT 1 FROM DownloadedComic d '
          'WHERE d.comic_id = t.comic_id)) AS downloaded_count, '
          'SUM(EXISTS(SELECT 1 FROM Collection c '
          'WHERE c.comicid = t.comic_id AND c.name = ?2)) AS history_count '
          'FROM ComicTagId t '
          'GROUP BY t.tag_id '
          'HAVING favorite_count + downloaded_count + history_count > 0',
          variables: <drift.Variable<Object>>[
            drift.Variable.withString(CollectionType.favorite.storageName),
            drift.Variable.withString(CollectionType.history.storageName),
          ],
          readsFrom: <drift.ResultSetImplementation<dynamic, dynamic>>{
            localDatabase.comicTagIds,
            localDatabase.collections,
            localDatabase.downloadedComics,
          },
        )
        .get();
    return rows
        .map(
          (row) => TagSourceCount(
            tagId: row.read<int>('tag_id'),
            collectedCount: row.read<int>('collected_count'),
            favoriteCount: row.read<int>('favorite_count'),
            downloadedCount: row.read<int>('downloaded_count'),
            historyCount: row.read<int>('history_count'),
          ),
        )
        .toList(growable: false);
  }
}
