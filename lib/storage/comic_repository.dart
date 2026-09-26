import 'package:concept_nhv/models/stored_comic.dart';
import 'package:concept_nhv/storage/local_database.dart';
import 'package:drift/drift.dart' as drift;

class ComicRepository {
  const ComicRepository({required this.localDatabase});

  final LocalDatabase localDatabase;

  /// Loads the stored rows for [comicIds], keyed by id.
  ///
  /// Ids with nothing stored are simply absent — a comic can be downloaded
  /// without ever having been cached here (see [insertComicIfAbsent]).
  Future<Map<String, StoredComic>> loadComicsByIds(Set<String> comicIds) async {
    if (comicIds.isEmpty) return const <String, StoredComic>{};
    final query = localDatabase.select(localDatabase.comics)
      ..where((table) => table.id.isIn(comicIds));
    final rows = await query.get();
    return <String, StoredComic>{
      for (final row in rows)
        row.id: StoredComic(
          id: row.id,
          mediaId: row.mid,
          title: row.title,
          serializedImages: row.images,
          pages: row.pages,
        ),
    };
  }

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

  /// Stores [comic] only if that id is not already known.
  ///
  /// Exists for the offline reading path: a comic reconstructed from a local
  /// download carries *less* metadata than one fetched from the API — no cover,
  /// no thumbnail, local file paths for pages. Letting that overwrite a stored
  /// row would strip the cover off the card in Favorites and History, and the
  /// original data would be gone for good. Inserting when nothing is stored is
  /// still needed, or History would list an id with no comic behind it.
  Future<void> insertComicIfAbsent(StoredComic comic) async {
    await localDatabase.into(localDatabase.comics).insert(
      ComicsCompanion.insert(
        id: comic.id,
        mid: comic.mediaId,
        title: comic.title,
        images: comic.serializedImages,
        pages: comic.pages,
      ),
      mode: drift.InsertMode.insertOrIgnore,
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
