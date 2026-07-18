import 'package:concept_nhv/storage/collection_repository.dart';
import 'package:concept_nhv/storage/comic_repository.dart';
import 'package:concept_nhv/storage/download_queue_repository.dart';
import 'package:concept_nhv/storage/downloaded_library_repository.dart';
import 'package:concept_nhv/storage/local_database.dart';
import 'package:concept_nhv/storage/search_history_repository.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

class SqliteTestHarness {
  late LocalDatabase localDatabase;
  late ComicRepository comicRepository;
  late CollectionRepository collectionRepository;
  late DownloadQueueRepository downloadQueueRepository;
  late DownloadedLibraryRepository downloadedLibraryRepository;
  late SearchHistoryRepository searchHistoryRepository;

  Future<void> initialize() async {
    localDatabase = LocalDatabase(
      executor: DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    await localDatabase.initialize();
    comicRepository = ComicRepository(localDatabase: localDatabase);
    collectionRepository = CollectionRepository(localDatabase: localDatabase);
    downloadQueueRepository = DownloadQueueRepository(
      localDatabase: localDatabase,
    );
    downloadedLibraryRepository = DownloadedLibraryRepository(
      localDatabase: localDatabase,
    );
    searchHistoryRepository = SearchHistoryRepository(
      localDatabase: localDatabase,
    );
  }

  Future<void> dispose() async {
    await localDatabase.resetForTesting();
  }
}
