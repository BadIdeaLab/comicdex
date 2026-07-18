import 'package:concept_nhv/application/favorites/favorite_sync_result.dart';
import 'package:concept_nhv/models/collection_type.dart';
import 'package:concept_nhv/models/stored_comic.dart';
import 'package:concept_nhv/services/remote_favorite_gateway.dart';
import 'package:concept_nhv/storage/collection_repository.dart';
import 'package:dio/dio.dart';

class SyncRemoteFavoritesUseCase {
  const SyncRemoteFavoritesUseCase({
    required this.collectionRepository,
    required this.remoteFavoriteGateway,
  });

  final CollectionRepository collectionRepository;
  final RemoteFavoriteGateway remoteFavoriteGateway;

  Future<FavoriteSyncResult> execute({
    void Function(int page, int totalPages)? onProgress,
    void Function(Duration retryIn)? onRateLimit,
  }) async {
    try {
      final comics = await remoteFavoriteGateway.loadRemoteFavorites(
        onProgress: onProgress,
        onRateLimit: onRateLimit,
      );
      await collectionRepository.replaceCollectionCache(
        collectionType: CollectionType.favorite,
        comics: comics.map(StoredComic.fromComic),
      );
      return FavoriteSyncResult(
        favoriteIds: comics.map((comic) => comic.id).toSet(),
        isAuthenticated: true,
        lastSyncAt: DateTime.now(),
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
    } catch (e) {
      final detail = e is DioException
          ? 'HTTP ${e.response?.statusCode ?? 'network error'}'
          : e.runtimeType.toString();
      return FavoriteSyncResult(
        favoriteIds: await _loadCachedFavoriteIds(),
        isAuthenticated: true,
        lastSyncAt: null,
        success: false,
        errorMessage: 'Failed to sync favorites ($detail).',
      );
    }
  }

  Future<Set<String>> _loadCachedFavoriteIds() {
    return collectionRepository.loadCollectedComicIds(CollectionType.favorite);
  }
}
