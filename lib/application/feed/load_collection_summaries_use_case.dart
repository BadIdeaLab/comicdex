import 'package:concept_nhv/models/collection_summary.dart';
import 'package:concept_nhv/storage/collection_repository.dart';

class LoadCollectionSummariesUseCase {
  const LoadCollectionSummariesUseCase({required this.collectionRepository});

  final CollectionRepository collectionRepository;

  Future<List<CollectionSummary>> execute() {
    return collectionRepository.loadCollectionSummaries();
  }
}
