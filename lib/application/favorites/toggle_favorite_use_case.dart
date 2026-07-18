import 'package:concept_nhv/application/favorites/favorite_sync_result.dart';
import 'package:concept_nhv/models/collection_type.dart';
import 'package:concept_nhv/models/comic_card_data.dart';
import 'package:concept_nhv/services/nhentai_auth_service.dart';
import 'package:concept_nhv/services/remote_favorite_gateway.dart';
import 'package:concept_nhv/storage/collection_repository.dart';

class ToggleFavoriteUseCase {
  const ToggleFavoriteUseCase({
    required this.collectionRepository,
    required this.remoteFavoriteGateway,
    required this.authService,
  });

  final CollectionRepository collectionRepository;
  final RemoteFavoriteGateway remoteFavoriteGateway;
  final NhentaiAuthService authService;

  /// Toggles a single comic's favorite status. Calls the lightweight
  /// single-comic remote endpoint, then updates the local cache
  /// incrementally (insert/delete one row) instead of triggering a full
  /// multi-page resync — see
  /// .codex/phases/P49-lightweight-favorite-toggle.md. Use
  /// `SyncRemoteFavoritesUseCase` (the "Sync Favorites Now" button) to
  /// reconcile the full local cache against the remote source of truth.
  Future<FavoriteSyncResult> execute({
    required ComicCardData comic,
    required bool isFavorite,
  }) async {
    final isValid = await authService.validateStoredApiKey();
    if (!isValid) {
      return FavoriteSyncResult(
        favoriteIds: await _loadCachedFavoriteIds(),
        isAuthenticated: false,
        lastSyncAt: null,
        success: false,
        errorMessage: 'Valid API key required to edit favorites.',
      );
    }

    try {
      if (isFavorite) {
        await remoteFavoriteGateway.removeRemoteFavorite(comic.id);
        await collectionRepository.removeComicFromCollection(
          collectionType: CollectionType.favorite,
          comicId: comic.id,
        );
      } else {
        await remoteFavoriteGateway.addRemoteFavorite(comic.id);
        await collectionRepository.upsertComicAndAddToCollection(
          collectionType: CollectionType.favorite,
          comic: comic.toStoredComic(),
        );
      }
      return FavoriteSyncResult(
        favoriteIds: await _loadCachedFavoriteIds(),
        isAuthenticated: true,
        lastSyncAt: null,
        success: true,
      );
    } on RemoteFavoriteAuthException catch (error) {
      return FavoriteSyncResult(
        favoriteIds: await _loadCachedFavoriteIds(),
        isAuthenticated: false,
        lastSyncAt: null,
        success: false,
        errorMessage: error.message,
      );
    } catch (_) {
      return FavoriteSyncResult(
        favoriteIds: await _loadCachedFavoriteIds(),
        isAuthenticated: true,
        lastSyncAt: null,
        success: false,
        errorMessage: 'Failed to update API favorite.',
      );
    }
  }

  Future<Set<String>> _loadCachedFavoriteIds() {
    return collectionRepository.loadCollectedComicIds(
      CollectionType.favorite,
    );
  }
}
