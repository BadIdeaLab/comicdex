import 'package:concept_nhv/models/collection_type.dart';
import 'package:concept_nhv/storage/collection_repository.dart';

class RemoveComicFromCollectionUseCase {
  const RemoveComicFromCollectionUseCase({
    required this.collectionRepository,
  });

  final CollectionRepository collectionRepository;

  Future<void> execute({
    required CollectionType collectionType,
    required String comicId,
  }) async {
    await collectionRepository.removeComicFromCollection(
      collectionType: collectionType,
      comicId: comicId,
    );
  }
}
