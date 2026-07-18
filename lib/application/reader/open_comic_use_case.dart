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

  Future<void> execute(Comic comic) async {
    await comicRepository.upsertComic(StoredComic.fromComic(comic));
    await collectionRepository.addComicToCollection(
      collectionType: CollectionType.history,
      comicId: comic.id,
    );
  }
}
