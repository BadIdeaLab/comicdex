import 'package:concept_nhv/models/collection_type.dart';
import 'package:concept_nhv/models/comic.dart';
import 'package:concept_nhv/models/stored_comic.dart';
import 'package:concept_nhv/storage/collection_repository.dart';
import 'package:concept_nhv/storage/comic_repository.dart';

class OpenComicUseCase {
  const OpenComicUseCase({
    required this.comicRepository,
    required this.collectionRepository,
  });

  final ComicRepository comicRepository;
  final CollectionRepository collectionRepository;

  /// Records that [comic] was opened.
  ///
  /// Set [isDegradedMetadata] when [comic] was rebuilt from a local download
  /// rather than fetched from the API. Such a comic has no cover and no
  /// thumbnail, so storing it over an existing row would leave Favorites and
  /// History showing a card with no image — permanently, since the API version
  /// is not fetched again. It is still stored when nothing is known about the
  /// id yet, otherwise History would reference a comic that does not exist.
  Future<void> execute(Comic comic, {bool isDegradedMetadata = false}) async {
    final stored = StoredComic.fromComic(comic);
    if (isDegradedMetadata) {
      await comicRepository.insertComicIfAbsent(stored);
    } else {
      await comicRepository.upsertComic(stored);
    }
    await collectionRepository.addComicToCollection(
      collectionType: CollectionType.history,
      comicId: comic.id,
    );
  }
}
