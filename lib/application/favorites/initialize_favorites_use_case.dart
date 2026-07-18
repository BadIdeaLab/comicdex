import 'package:concept_nhv/application/favorites/favorite_sync_snapshot.dart';
import 'package:concept_nhv/models/collection_type.dart';
import 'package:concept_nhv/services/nhentai_auth_service.dart';
import 'package:concept_nhv/storage/collection_repository.dart';

class InitializeFavoritesUseCase {
  const InitializeFavoritesUseCase({
    required this.collectionRepository,
    required this.authService,
  });

  final CollectionRepository collectionRepository;
  final NhentaiAuthService authService;

  Future<FavoriteSyncSnapshot> execute() async {
    final favoriteIds = await collectionRepository.loadCollectedComicIds(
      CollectionType.favorite,
    );
    final credential = await authService.loadCredential();
    return FavoriteSyncSnapshot(
      favoriteIds: favoriteIds,
      isAuthenticated: !credential.isEmpty,
      lastSyncAt: credential.lastValidatedAt,
    );
  }
}
