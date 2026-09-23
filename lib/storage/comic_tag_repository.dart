import 'package:concept_nhv/models/collection_type.dart';
import 'package:concept_nhv/models/tag_assignment.dart';
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

  /// Kept comics that carry at least one tag id — the numerator of the tag
  /// coverage shown on the analysis page (P81). Without it a ranking built
  /// from half the library would look like one built from all of it.
  Future<int> loadTaggedKeptComicCount() async {
    final row = await localDatabase
        .customSelect(
          'SELECT COUNT(*) AS tagged FROM ('
          'SELECT DISTINCT t.comic_id FROM ComicTagId t WHERE t.comic_id IN ('
          'SELECT comicid FROM Collection WHERE name = ?1 '
          'UNION SELECT comic_id FROM DownloadedComic'
          ')'
          ')',
          variables: <drift.Variable<Object>>[
            drift.Variable.withString(CollectionType.favorite.storageName),
          ],
          readsFrom: <drift.ResultSetImplementation<dynamic, dynamic>>{
            localDatabase.comicTagIds,
            localDatabase.collections,
            localDatabase.downloadedComics,
          },
        )
        .getSingle();
    return row.read<int>('tagged');
  }

  /// Every (comic, tag) assignment among kept comics, limited to tags that
  /// appear on at least [minimumTagComics] of them (P83).
  ///
  /// The caller counts pairs and triples from this in Dart: a SQL self-join
  /// gives pairs cheaply but triples need the same rows again, and one dump
  /// of ~13k rows keeps a single source of truth for both.
  Future<List<TagAssignment>> loadKeptTagAssignments({
    int minimumTagComics = 3,
  }) async {
    final rows = await localDatabase
        .customSelect(
          'WITH kept AS ('
          'SELECT comicid AS comic_id FROM Collection WHERE name = ?1 '
          'UNION SELECT comic_id FROM DownloadedComic'
          '), tagged AS ('
          'SELECT t.comic_id, t.tag_id FROM ComicTagId t '
          'JOIN kept k ON k.comic_id = t.comic_id'
          '), frequent AS ('
          'SELECT tag_id FROM tagged GROUP BY tag_id HAVING COUNT(*) >= ?2'
          ') '
          'SELECT tagged.comic_id, tagged.tag_id FROM tagged '
          'JOIN frequent f ON f.tag_id = tagged.tag_id',
          variables: <drift.Variable<Object>>[
            drift.Variable.withString(CollectionType.favorite.storageName),
            drift.Variable.withInt(minimumTagComics),
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
          (row) => TagAssignment(
            comicId: row.read<String>('comic_id'),
            tagId: row.read<int>('tag_id'),
          ),
        )
        .toList(growable: false);
  }

  /// Comic ids carrying [tagId] — the exact filter behind "search in
  /// favorites" (P80). Favorites hold no tag *names* locally, only these
  /// ids, so matching by id is both the only option and the precise one.
  Future<Set<String>> loadComicIdsWithTag(int tagId) async {
    final query = localDatabase.select(localDatabase.comicTagIds)
      ..where((table) => table.tagId.equals(tagId));
    final rows = await query.get();
    return rows.map((row) => row.comicId).toSet();
  }

  /// How many comics the user kept: favorited or downloaded, counted once
  /// when both. The sample size behind every tag's share (P79).
  Future<int> loadKeptComicCount() async {
    final row = await localDatabase
        .customSelect(
          'SELECT COUNT(*) AS kept FROM ('
          'SELECT comicid AS comic_id FROM Collection WHERE name = ?1 '
          'UNION '
          'SELECT comic_id FROM DownloadedComic'
          ')',
          variables: <drift.Variable<Object>>[
            drift.Variable.withString(CollectionType.favorite.storageName),
          ],
          readsFrom: <drift.ResultSetImplementation<dynamic, dynamic>>{
            localDatabase.collections,
            localDatabase.downloadedComics,
          },
        )
        .getSingle();
    return row.read<int>('kept');
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
