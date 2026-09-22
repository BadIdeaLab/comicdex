import 'dart:io';

import 'package:concept_nhv/storage/local_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDirectory;
  late File databaseFile;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('migration_test');
    databaseFile = File('${tempDirectory.path}/app.db');
  });

  tearDown(() async {
    await tempDirectory.delete(recursive: true);
  });

  LocalDatabase open() => LocalDatabase(
    executor: DatabaseConnection(
      NativeDatabase(databaseFile),
      closeStreamsSynchronously: true,
    ),
  );

  Future<void> insertDownloaded(
    LocalDatabase database,
    String comicId,
    String tagsJson,
  ) {
    return database.customStatement(
      'INSERT INTO DownloadedComic '
      '(comic_id, media_id, root_directory_path, page_count, downloaded_at, tags_json) '
      "VALUES (?, 'm', 'r', 1, '2026-01-01', ?)",
      <Object>[comicId, tagsJson],
    );
  }

  /// Rewinds a freshly created database to what schema 9 looked like: no
  /// ComicTagId table, user_version 9. Everything else is unchanged by P76.
  Future<void> rewindToSchema9(LocalDatabase database) async {
    await database.customStatement('DROP INDEX idx_comic_tag_id_tag');
    await database.customStatement('DROP TABLE ComicTagId');
    await database.customStatement('PRAGMA user_version = 9');
  }

  test('upgrading from 9 copies downloaded tag ids into ComicTagId', () async {
    final v9 = open();
    await v9.initialize();
    await insertDownloaded(
      v9,
      '100',
      '[{"id":2937,"type":"tag","name":"big breasts"},'
          '{"id":12227,"type":"language","name":"english"}]',
    );
    await insertDownloaded(v9, '200', '[{"id":null,"name":"no id"}]');
    await insertDownloaded(v9, '300', 'not json');
    await rewindToSchema9(v9);
    await v9.close();

    final upgraded = open();
    await upgraded.initialize();
    final rows = await upgraded
        .customSelect(
          'SELECT comic_id, tag_id FROM ComicTagId ORDER BY comic_id, tag_id',
        )
        .get();
    final index = await upgraded
        .customSelect(
          "SELECT name FROM sqlite_master WHERE name = 'idx_comic_tag_id_tag'",
        )
        .get();
    await upgraded.close();

    expect(
      rows.map((r) => '${r.read<String>('comic_id')}:${r.read<int>('tag_id')}'),
      <String>['100:2937', '100:12227'],
    );
    expect(index, hasLength(1));
  });
}
