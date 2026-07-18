import 'package:concept_nhv/models/collection_type.dart';
import 'package:concept_nhv/models/comic_card_data.dart';
import 'package:concept_nhv/storage/collection_repository.dart';

class LoadCollectionComicsUseCase {
  const LoadCollectionComicsUseCase({required this.collectionRepository});

  final CollectionRepository collectionRepository;

  Future<List<ComicCardData>> execute(CollectionType collectionType) async {
    final records = await collectionRepository.loadCollectionComics(collectionType);
    return records
        .map((record) => ComicCardData.fromStoredComic(record.comic))
        .toList();
  }
}
