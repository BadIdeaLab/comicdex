import 'package:concept_nhv/application/favorites/favorite_sync_result.dart';
import 'package:concept_nhv/models/collection_type.dart';
import 'package:concept_nhv/models/comic.dart';
import 'package:concept_nhv/models/stored_comic.dart';
import 'package:concept_nhv/services/remote_favorite_gateway.dart';
import 'package:concept_nhv/storage/collection_repository.dart';
import 'package:concept_nhv/storage/comic_tag_repository.dart';
import 'package:dio/dio.dart';

class SyncRemoteFavoritesUseCase {
  const SyncRemoteFavoritesUseCase({
    required this.collectionRepository,
    required this.comicTagRepository,
    required this.remoteFavoriteGateway,
    this.pageDelay = const Duration(seconds: 2),
  });

  final CollectionRepository collectionRepository;
  final ComicTagRepository comicTagRepository;
  final RemoteFavoriteGateway remoteFavoriteGateway;

  /// Pause between incremental pages, matching the full sync's pacing.
  final Duration pageDelay;

  /// Full sync: every page, then the local favorites are rewritten to match.
  Future<FavoriteSyncResult> execute({
    void Function(int page, int totalPages)? onProgress,
    void Function(Duration retryIn)? onRateLimit,
  }) {
    return _guard(
      () => _fullSync(onProgress: onProgress, onRateLimit: onRateLimit),
    );
  }

  /// Incremental sync (P77): walks pages newest-first and stops at the first
  /// page whose comics are all known locally, then merges that prefix in
  /// front of the local favorites. Stopping at a whole known page rather than
  /// the first known comic tolerates an old comic re-favorited elsewhere,
  /// which jumps to the top while newer favorites follow it.
  ///
  /// Merging only ever adds, so a favorite removed elsewhere leaves the local
  /// count above the remote `total`; any mismatch (or a missing `total`)
  /// falls back to a full sync.
  Future<FavoriteSyncResult> executeIncremental({
    void Function(int page, int totalPages)? onProgress,
    void Function(Duration retryIn)? onRateLimit,
  }) {
    return _guard(() async {
      final localIds = await collectionRepository.loadFavoriteIdsInOrder();
      if (localIds.isEmpty) {
        return _fullSync(onProgress: onProgress, onRateLimit: onRateLimit);
      }

      final knownIds = localIds.toSet();
      final prefix = <Comic>[];
      int? remoteTotal;
      var page = 1;
      while (true) {
        if (page > 1) {
          await Future<void>.delayed(pageDelay);
        }
        final remotePage = await remoteFavoriteGateway.loadRemoteFavoritePage(
          page,
          onRateLimit: onRateLimit,
        );
        remoteTotal = remotePage.total;
        onProgress?.call(page, remotePage.numPages);
        prefix.addAll(remotePage.comics);
        final pageAllKnown = remotePage.comics.every(
          (comic) => knownIds.contains(comic.id),
        );
        if (pageAllKnown ||
            remotePage.comics.isEmpty ||
            page >= remotePage.numPages) {
          break;
        }
        page += 1;
      }

      await collectionRepository.mergeFavoritePrefix(
        prefix.map(StoredComic.fromComic).toList(growable: false),
      );
      await _storeTagIds(prefix);

      final mergedIds = <String>{...knownIds, ...prefix.map((c) => c.id)};
      if (remoteTotal == null || mergedIds.length != remoteTotal) {
        return _fullSync(onProgress: onProgress, onRateLimit: onRateLimit);
      }
      return FavoriteSyncResult(
        favoriteIds: mergedIds,
        isAuthenticated: true,
        lastSyncAt: DateTime.now(),
        success: true,
      );
    });
  }

  Future<FavoriteSyncResult> _fullSync({
    void Function(int page, int totalPages)? onProgress,
    void Function(Duration retryIn)? onRateLimit,
  }) async {
    final comics = await remoteFavoriteGateway.loadRemoteFavorites(
      onProgress: onProgress,
      onRateLimit: onRateLimit,
    );
    await collectionRepository.replaceCollectionCache(
      collectionType: CollectionType.favorite,
      comics: comics.map(StoredComic.fromComic),
    );
    await _storeTagIds(comics);
    return FavoriteSyncResult(
      favoriteIds: comics.map((comic) => comic.id).toSet(),
      isAuthenticated: true,
      lastSyncAt: DateTime.now(),
      success: true,
    );
  }

  Future<void> _storeTagIds(List<Comic> comics) {
    return comicTagRepository.replaceTagIdsForComics(<String, List<int>>{
      for (final comic in comics) comic.id: comic.effectiveTagIds,
    });
  }

  Future<FavoriteSyncResult> _guard(
    Future<FavoriteSyncResult> Function() sync,
  ) async {
    try {
      return await sync();
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
