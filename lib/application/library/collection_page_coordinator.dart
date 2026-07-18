import 'dart:async';

import 'package:concept_nhv/models/collection_type.dart';
import 'package:concept_nhv/models/comic_card_data.dart';
import 'package:concept_nhv/state/comic_feed_model.dart';
import 'package:concept_nhv/state/favorite_sync_model.dart';

import 'load_collection_comics_use_case.dart';

class CollectionPageCoordinator {
  const CollectionPageCoordinator({
    required this.loadCollectionComicsUseCase,
    required this.favoriteSyncModel,
    required this.feedModel,
  });

  final LoadCollectionComicsUseCase loadCollectionComicsUseCase;
  final FavoriteSyncModel favoriteSyncModel;
  final ComicFeedModel feedModel;

  /// Loads locally cached comics for [collectionType] immediately, without
  /// waiting on a remote favorites resync. For [CollectionType.favorite], a
  /// full sync (`SyncRemoteFavoritesUseCase`, the same one "Sync Favorites
  /// Now" triggers) is kicked off in the background instead of being
  /// awaited — see .codex/phases/P53-nonblocking-favorite-list-sync.md.
  /// Blocking here on a multi-page sync meant the Favorite screen could sit
  /// blank for minutes when the sync hit rate-limit backoff.
  Future<List<ComicCardData>> load(CollectionType collectionType) async {
    if (collectionType == CollectionType.favorite) {
      unawaited(_syncFavoritesInBackground());
    }
    return loadCollectionComicsUseCase.execute(collectionType);
  }

  Future<void> _syncFavoritesInBackground() async {
    final synced = await favoriteSyncModel.syncFavorites();
    if (synced) {
      feedModel.refreshCollections();
    }
  }

  Future<List<ComicCardData>> refresh(CollectionType collectionType) {
    return loadCollectionComicsUseCase.execute(collectionType);
  }
}
