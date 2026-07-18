import 'package:concept_nhv/models/stored_comic.dart';
import 'package:concept_nhv/storage/local_database.dart';
import 'package:drift/drift.dart' as drift;

class ComicRepository {
  const ComicRepository({required this.localDatabase});

  final LocalDatabase localDatabase;

  Future<int> upsertComic(StoredComic comic) async {
    return localDatabase.into(localDatabase.comics).insert(
      ComicsCompanion.insert(
        id: comic.id,
        mid: comic.mediaId,
        title: comic.title,
        images: comic.serializedImages,
        pages: comic.pages,
      ),
      mode: drift.InsertMode.insertOrReplace,
    );
  }

  Future<void> upsertComics(Iterable<StoredComic> comics) async {
    await localDatabase.batch((batch) {
      for (final comic in comics) {
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
      }
    });
  }
}
