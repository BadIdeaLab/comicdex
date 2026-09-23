import 'package:concept_nhv/models/collection_type.dart';
import 'package:concept_nhv/models/comic.dart';
import 'package:concept_nhv/models/stored_comic.dart';
import 'package:concept_nhv/storage/collection_repository.dart';
import 'package:concept_nhv/storage/comic_repository.dart';
import 'package:concept_nhv/storage/comic_tag_repository.dart';

class OpenComicUseCase {
  const OpenComicUseCase({
    required this.comicRepository,
    required this.collectionRepository,
    required this.comicTagRepository,
  });

  final ComicRepository comicRepository;
  final CollectionRepository collectionRepository;
  final ComicTagRepository comicTagRepository;

  /// Records that [comic] was opened.
  ///
  /// Set [isDegradedMetadata] when [comic] was rebuilt from a local download
  /// rather than fetched from the API. Such a comic has no cover and no
  /// thumbnail, so storing it over an existing row would leave Favorites and
  /// History showing a card with no image — permanently, since the API version
  /// is not fetched again. It is still stored when nothing is known about the
  /// id yet, otherwise History would reference a comic that does not exist.
  ///
  /// Tag ids are stored either way: a comic rebuilt from a download still
  /// carries its full tag list, so it is no worse a source for them.
  Future<void> execute(Comic comic, {bool isDegradedMetadata = false}) async {
    final stored = StoredComic.fromComic(comic);
    if (isDegradedMetadata) {
      await comicRepository.insertComicIfAbsent(stored);
    } else {
      await comicRepository.upsertComic(stored);
    }
    await comicTagRepository.replaceTagIds(comic.id, comic.effectiveTagIds);
    await collectionRepository.addComicToCollection(
      collectionType: CollectionType.history,
      comicId: comic.id,
      incrementReadCount: true,
    );
  }
}
