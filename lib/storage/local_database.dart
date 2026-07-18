import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

part 'local_database.g.dart';

typedef DatabasePathResolver = Future<String> Function();

class AppOptions extends Table {
  @override
  String get tableName => 'Options';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get value => text()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => <Set<Column<Object>>>[
    <Column<Object>>{name},
  ];
}

class Comics extends Table {
  @override
  String get tableName => 'Comic';

  TextColumn get id => text()();
  TextColumn get mid => text()();
  TextColumn get title => text()();
  TextColumn get images => text()();
  IntColumn get pages => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class Collections extends Table {
  @override
  String get tableName => 'Collection';

  TextColumn get name => text()();
  TextColumn get comicid => text()();
  TextColumn get dateCreated => text().named('dateCreated')();

  /// Position in the remote favorites list (0 = most recently favorited).
  /// Only populated for the `favorite` collection; null for all others.
  IntColumn get favoriteRank => integer().named('favorite_rank').nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{name, comicid};
}

class SearchHistories extends Table {
  @override
  String get tableName => 'SearchHistory';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get query => text()();
  TextColumn get createdAt => text()
      .named('created_at')
      .customConstraint('NOT NULL DEFAULT CURRENT_TIMESTAMP')();
}

class DownloadJobs extends Table {
  @override
  String get tableName => 'DownloadJob';

  TextColumn get comicId => text().named('comic_id')();
  TextColumn get mediaId => text().named('media_id')();
  TextColumn get title => text()();
  TextColumn get thumbnailPath => text().named('thumbnail_path').nullable()();
  TextColumn get status => text()();
  IntColumn get totalPages => integer().named('total_pages')();
  IntColumn get completedPages =>
      integer().named('completed_pages').withDefault(const Constant(0))();
  IntColumn get nextPageNumber =>
      integer().named('next_page_number').withDefault(const Constant(1))();
  TextColumn get requestedAt => text().named('requested_at')();
  TextColumn get startedAt => text().named('started_at').nullable()();
  TextColumn get updatedAt => text().named('updated_at')();
  TextColumn get completedAt => text().named('completed_at').nullable()();
  TextColumn get lastError => text().named('last_error').nullable()();
  IntColumn get retryCount =>
      integer().named('retry_count').withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{comicId};
}

class DownloadJobPages extends Table {
  @override
  String get tableName => 'DownloadJobPage';

  TextColumn get comicId => text().named('comic_id')();
  TextColumn get mediaId => text().named('media_id')();
  IntColumn get pageNumber => integer().named('page_number')();
  TextColumn get remotePath => text().named('remote_path')();
  TextColumn get sourceServer => text().named('source_server').nullable()();
  TextColumn get localPath => text().named('local_path').nullable()();
  TextColumn get storedFormat => text().named('stored_format').nullable()();
  IntColumn get byteSize => integer().named('byte_size').nullable()();
  TextColumn get status => text()();
  TextColumn get downloadedAt => text().named('downloaded_at').nullable()();
  TextColumn get lastError => text().named('last_error').nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{comicId, pageNumber};
}

class DownloadedComics extends Table {
  @override
  String get tableName => 'DownloadedComic';

  TextColumn get comicId => text().named('comic_id')();
  TextColumn get mediaId => text().named('media_id')();
  TextColumn get titleEnglish => text().named('title_english').nullable()();
  TextColumn get titleJapanese => text().named('title_japanese').nullable()();
  TextColumn get titlePretty => text().named('title_pretty').nullable()();
  TextColumn get coverLocalPath =>
      text().named('cover_local_path').nullable()();
  TextColumn get rootDirectoryPath => text().named('root_directory_path')();
  IntColumn get pageCount => integer().named('page_count')();
  TextColumn get downloadedAt => text().named('downloaded_at')();
  TextColumn get lastReadAt => text().named('last_read_at').nullable()();
  IntColumn get numFavorites => integer().named('num_favorites').nullable()();
  TextColumn get tagsJson => text().named('tags_json')();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{comicId};
}

@DriftDatabase(
  tables: [
    AppOptions,
    Comics,
    Collections,
    SearchHistories,
    DownloadJobs,
    DownloadJobPages,
    DownloadedComics,
  ],
)
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase({
    QueryExecutor? executor,
    DatabasePathResolver? databasePathResolver,
  }) : _databasePathResolver = databasePathResolver ?? _defaultDatabasePath,
       super(
         executor ??
             _openConnection(databasePathResolver ?? _defaultDatabasePath),
       );

  final DatabasePathResolver _databasePathResolver;

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (Migrator migrator, int from, int to) async {
      if (from < 2) {
        await customStatement(
          'CREATE TABLE IF NOT EXISTS Options(id INTEGER PRIMARY KEY, name TEXT NOT NULL, value TEXT NOT NULL)',
        );
      }
      if (from < 3) {
        await customStatement('DROP TABLE IF EXISTS Options');
        await customStatement(
          'CREATE TABLE Options(id INTEGER PRIMARY KEY, name TEXT NOT NULL UNIQUE, value TEXT NOT NULL)',
        );
      }
      if (from < 4) {
        await customStatement(
          'CREATE TABLE IF NOT EXISTS SearchHistory(id INTEGER PRIMARY KEY, query TEXT NOT NULL, created_at DATETIME DEFAULT CURRENT_TIMESTAMP)',
        );
      }
      if (from < 5) {
        await customStatement(
          'CREATE TABLE IF NOT EXISTS DownloadJob('
          'comic_id TEXT PRIMARY KEY, '
          'media_id TEXT NOT NULL, '
          'title TEXT NOT NULL, '
          'status TEXT NOT NULL, '
          'total_pages INTEGER NOT NULL, '
          'completed_pages INTEGER NOT NULL DEFAULT 0, '
          'next_page_number INTEGER NOT NULL DEFAULT 1, '
          'requested_at TEXT NOT NULL, '
          'started_at TEXT, '
          'updated_at TEXT NOT NULL, '
          'completed_at TEXT, '
          'last_error TEXT, '
          'retry_count INTEGER NOT NULL DEFAULT 0'
          ')',
        );
        await customStatement(
          'CREATE TABLE IF NOT EXISTS DownloadJobPage('
          'comic_id TEXT NOT NULL, '
          'page_number INTEGER NOT NULL, '
          'remote_path TEXT NOT NULL, '
          'source_server TEXT, '
          'local_path TEXT, '
          'stored_format TEXT, '
          'byte_size INTEGER, '
          'status TEXT NOT NULL, '
          'downloaded_at TEXT, '
          'last_error TEXT, '
          'PRIMARY KEY (comic_id, page_number)'
          ')',
        );
        await customStatement(
          'CREATE TABLE IF NOT EXISTS DownloadedComic('
          'comic_id TEXT PRIMARY KEY, '
          'media_id TEXT NOT NULL, '
          'title_english TEXT, '
          'title_japanese TEXT, '
          'title_pretty TEXT, '
          'cover_local_path TEXT, '
          'root_directory_path TEXT NOT NULL, '
          'page_count INTEGER NOT NULL, '
          'downloaded_at TEXT NOT NULL, '
          'last_read_at TEXT, '
          'num_favorites INTEGER, '
          'tags_json TEXT NOT NULL'
          ')',
        );
      }
      if (from < 6) {
        await customStatement(
          'ALTER TABLE DownloadJobPage ADD COLUMN media_id TEXT NOT NULL DEFAULT \'\'',
        );
        await customStatement(
          'UPDATE DownloadJobPage '
          'SET media_id = COALESCE(('
          'SELECT media_id FROM DownloadJob '
          'WHERE DownloadJob.comic_id = DownloadJobPage.comic_id'
          "), '') "
          'WHERE media_id = \'\'',
        );
      }
      if (from < 7) {
        await customStatement(
          'ALTER TABLE DownloadJob ADD COLUMN thumbnail_path TEXT',
        );
      }
      if (from < 8) {
        await customStatement(
          'ALTER TABLE DownloadedComic ADD COLUMN num_favorites INTEGER',
        );
      }
      if (from < 9) {
        await customStatement(
          'ALTER TABLE Collection ADD COLUMN favorite_rank INTEGER',
        );
      }
    },
  );

  Future<void> initialize() async {
    await customSelect('SELECT 1').get();
  }

  Future<void> resetForTesting() => close();

  Future<String> resolveDatabasePath() => _databasePathResolver();

  static QueryExecutor _openConnection(
    DatabasePathResolver databasePathResolver,
  ) {
    return LazyDatabase(() async {
      final path = await databasePathResolver();
      final file = File(path);
      final temporaryDirectory = await getTemporaryDirectory();
      sqlite3.tempDirectory = temporaryDirectory.path;
      return NativeDatabase.createInBackground(file);
    });
  }

  static Future<String> _defaultDatabasePath() async {
    if (kIsWeb) {
      throw UnsupportedError('LocalDatabase is not supported on web.');
    }

    if (Platform.isIOS) {
      return p.join((await getLibraryDirectory()).path, 'database.db');
    }

    final supportDirectory = await getApplicationSupportDirectory();
    final databasesDirectory = Directory(
      p.join(supportDirectory.parent.path, 'databases'),
    );
    await databasesDirectory.create(recursive: true);
    return p.join(databasesDirectory.path, 'database.db');
  }
}
