import 'dart:convert';

import 'package:concept_nhv/models/comic.dart' as model;
import 'package:concept_nhv/models/comic_tag.dart';
import 'package:concept_nhv/models/downloaded_comic_snapshot.dart';
import 'package:concept_nhv/storage/local_database.dart';
import 'package:drift/drift.dart' as drift;

class DownloadedLibraryRepository {
  const DownloadedLibraryRepository({required this.localDatabase});

  final LocalDatabase localDatabase;

  Future<void> saveDownloadedComic({
    required model.Comic comic,
    required String rootDirectoryPath,
    required String? coverLocalPath,
    DateTime? downloadedAt,
  }) async {
    final timestamp = downloadedAt ?? DateTime.now();
    await localDatabase.into(localDatabase.downloadedComics).insert(
      DownloadedComicsCompanion.insert(
        comicId: comic.id,
        mediaId: comic.mediaId,
        titleEnglish: drift.Value(comic.title.english),
        titleJapanese: drift.Value(comic.title.japanese),
        titlePretty: drift.Value(comic.title.pretty),
        coverLocalPath: drift.Value(coverLocalPath),
        rootDirectoryPath: rootDirectoryPath,
        pageCount: comic.numPages,
        downloadedAt: timestamp.toIso8601String(),
        lastReadAt: const drift.Value.absent(),
        numFavorites: drift.Value(comic.numFavorites),
        tagsJson: jsonEncode(
          comic.tags
              .map(
                (tag) => <String, dynamic>{
                  'id': tag.id,
                  'type': tag.type,
                  'name': tag.name,
                  'url': tag.url,
                  'count': tag.count,
                },
              )
              .toList(growable: false),
        ),
      ),
      mode: drift.InsertMode.insertOrReplace,
    );
  }

  Future<void> deleteDownloadedComic(String comicId) async {
    final statement = localDatabase.delete(localDatabase.downloadedComics)
      ..where((table) => table.comicId.equals(comicId));
    await statement.go();
  }

  Future<void> saveLastReadAt(String comicId, DateTime timestamp) async {
    final updateStatement = localDatabase.update(localDatabase.downloadedComics)
      ..where((table) => table.comicId.equals(comicId));
    await updateStatement.write(
      DownloadedComicsCompanion(
        lastReadAt: drift.Value(timestamp.toIso8601String()),
      ),
    );
  }

  Future<void> updateCoverLocalPath(String comicId, String? coverLocalPath) async {
    final updateStatement = localDatabase.update(localDatabase.downloadedComics)
      ..where((table) => table.comicId.equals(comicId));
    await updateStatement.write(
      DownloadedComicsCompanion(coverLocalPath: drift.Value(coverLocalPath)),
    );
  }

  Future<String?> loadCoverLocalPath(String comicId) async {
    final query = localDatabase.select(localDatabase.downloadedComics)
      ..where((table) => table.comicId.equals(comicId))
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row?.coverLocalPath;
  }

  Future<List<DownloadedComicSnapshot>> loadDownloadedComics() async {
    final query = localDatabase.select(localDatabase.downloadedComics)
      ..orderBy([(table) => drift.OrderingTerm.desc(table.downloadedAt)]);
    final rows = await query.get();
    return rows.map(_mapDownloadedComic).toList(growable: false);
  }

  DownloadedComicSnapshot _mapDownloadedComic(DownloadedComic row) {
    return DownloadedComicSnapshot(
      comicId: row.comicId,
      mediaId: row.mediaId,
      title: row.titlePretty ?? row.titleEnglish ?? row.titleJapanese ?? row.comicId,
      coverLocalPath: row.coverLocalPath,
      rootDirectoryPath: row.rootDirectoryPath,
      pageCount: row.pageCount,
      downloadedAt: DateTime.parse(row.downloadedAt),
      lastReadAt: row.lastReadAt == null ? null : DateTime.parse(row.lastReadAt!),
      numFavorites: row.numFavorites,
      tags: _parseTags(row.tagsJson),
    );
  }

  List<ComicTag> _parseTags(String serializedTags) {
    try {
      final decoded = jsonDecode(serializedTags);
      if (decoded is! List<Object?>) {
        return const <ComicTag>[];
      }
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(ComicTag.fromJson)
          .toList(growable: false);
    } on FormatException {
      return const <ComicTag>[];
    }
  }
}
