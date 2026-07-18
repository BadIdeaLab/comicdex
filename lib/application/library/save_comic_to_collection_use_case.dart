import 'package:concept_nhv/models/collection_type.dart';
import 'package:concept_nhv/models/comic_card_data.dart';
import 'package:concept_nhv/storage/collection_repository.dart';
import 'package:concept_nhv/storage/comic_repository.dart';

class SaveComicToCollectionUseCase {
  const SaveComicToCollectionUseCase({
    required this.comicRepository,
    required this.collectionRepository,
  });

  final ComicRepository comicRepository;
  final CollectionRepository collectionRepository;

  Future<void> execute({
    required ComicCardData comic,
    required CollectionType targetCollection,
  }) async {
    await comicRepository.upsertComic(comic.toStoredComic());
    await collectionRepository.addComicToCollection(
      collectionType: targetCollection,
      comicId: comic.id,
    );
  }
}
