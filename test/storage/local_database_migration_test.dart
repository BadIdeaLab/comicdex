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
  /// ComicTagId table, no Collection.read_count, no TrackedArtist,
  /// user_version 9.
  Future<void> rewindToSchema9(LocalDatabase database) async {
    await database.customStatement('DROP INDEX idx_comic_tag_id_tag');
    await database.customStatement('DROP TABLE ComicTagId');
    await database.customStatement('DROP TABLE TrackedArtist');
    await database.customStatement(
      'ALTER TABLE Collection DROP COLUMN read_count',
    );
    await database.customStatement('PRAGMA user_version = 9');
  }

  /// Schema 11 — everything but TrackedArtist.
  Future<void> rewindToSchema11(LocalDatabase database) async {
    await database.customStatement('DROP TABLE TrackedArtist');
    await database.customStatement('PRAGMA user_version = 11');
  }

  test(
    'upgrading from 9 adds read_count, defaulting existing rows to 0',
    () async {
      final v9 = open();
      await v9.initialize();
      await v9.customStatement(
        "INSERT INTO Collection (name, comicid, dateCreated) "
        "VALUES ('History', '1', '2026-01-01')",
      );
      await rewindToSchema9(v9);
      await v9.close();

      final upgraded = open();
      await upgraded.initialize();
      final row = await upgraded
          .customSelect('SELECT read_count FROM Collection')
          .getSingle();
      await upgraded.close();

      expect(row.read<int>('read_count'), 0);
    },
  );

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

  test(
    'upgrading from 11 adds TrackedArtist, leaving other rows alone',
    () async {
      final v11 = open();
      await v11.initialize();
      await v11.customStatement(
        "INSERT INTO Collection (name, comicid, dateCreated) "
        "VALUES ('Favorite', '1', '2026-01-01')",
      );
      await rewindToSchema11(v11);
      await v11.close();

      final upgraded = open();
      await upgraded.initialize();
      // Writing through the table is the check that matters: a table that
      // exists but whose columns do not match what drift generated would pass
      // a sqlite_master lookup and fail on the first insert, on a device.
      await upgraded.customStatement(
        'INSERT INTO TrackedArtist (tag_id, last_seen_upload_date) VALUES (20, 1700)',
      );
      final tracked = await upgraded
          .customSelect('SELECT tag_id, new_count FROM TrackedArtist')
          .getSingle();
      final kept = await upgraded
          .customSelect('SELECT comicid FROM Collection')
          .getSingle();
      await upgraded.close();

      expect(tracked.read<int>('tag_id'), 20);
      expect(
        tracked.read<int>('new_count'),
        0,
        reason: 'a fresh row has nothing new in it yet',
      );
      expect(kept.read<String>('comicid'), '1');
    },
  );

  test('a database created from scratch has TrackedArtist too', () async {
    // onCreate and onUpgrade are separate paths, and a table added only to
    // the second one works for every existing install and for nobody new.
    final fresh = open();
    await fresh.initialize();
    final table = await fresh
        .customSelect(
          "SELECT name FROM sqlite_master WHERE name = 'TrackedArtist'",
        )
        .get();
    await fresh.close();

    expect(table, hasLength(1));
  });
}
