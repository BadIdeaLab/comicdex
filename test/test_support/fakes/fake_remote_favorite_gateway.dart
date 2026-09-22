import 'dart:async';

import 'package:concept_nhv/models/comic.dart';
import 'package:concept_nhv/services/remote_favorite_gateway.dart';

import '../fixtures/sample_comic.dart';

class FakeRemoteFavoriteGateway implements RemoteFavoriteGateway {
  List<Comic> remoteFavorites = <Comic>[];
  final List<String> addedComicIds = <String>[];
  final List<String> removedComicIds = <String>[];
  bool throwAuthException = false;

  /// Number of times [loadRemoteFavorites] (the paginated listing endpoint)
  /// was called — used to assert that a lightweight single-favorite toggle
  /// never triggers a full resync.
  int loadCallCount = 0;

  /// When set, [loadRemoteFavorites] awaits this before returning — lets
  /// tests simulate a slow/never-completing remote sync to assert that
  /// callers (e.g. CollectionPageCoordinator.load) don't block on it.
  Completer<void>? hangCompleter;

  /// Page size for [loadRemoteFavoritePage]; [remoteFavorites] is read as
  /// newest-first, the way the real endpoint orders it.
  int pageSize = 25;

  /// When true, [loadRemoteFavoritePage] reports no `total`.
  bool omitTotal = false;

  /// Pages requested through [loadRemoteFavoritePage], in order.
  final List<int> requestedPages = <int>[];

  @override
  Future<void> addRemoteFavorite(String comicId) async {
    addedComicIds.add(comicId);
    if (remoteFavorites.every((comic) => comic.id != comicId)) {
      remoteFavorites = <Comic>[...remoteFavorites, sampleComic(id: comicId)];
    }
  }

  @override
  Future<List<Comic>> loadRemoteFavorites({
    void Function(int page, int totalPages)? onProgress,
    void Function(Duration retryIn)? onRateLimit,
  }) async {
    loadCallCount += 1;
    if (hangCompleter != null) {
      await hangCompleter!.future;
    }
    if (throwAuthException) {
      throw const RemoteFavoriteAuthException(
        'API key expired or invalid. Showing cached favorites.',
      );
    }
    return List<Comic>.from(remoteFavorites);
  }

  @override
  Future<RemoteFavoritePage> loadRemoteFavoritePage(
    int page, {
    void Function(Duration retryIn)? onRateLimit,
  }) async {
    requestedPages.add(page);
    if (hangCompleter != null) {
      await hangCompleter!.future;
    }
    if (throwAuthException) {
      throw const RemoteFavoriteAuthException(
        'API key expired or invalid. Showing cached favorites.',
      );
    }
    final start = (page - 1) * pageSize;
    final end = (start + pageSize).clamp(0, remoteFavorites.length);
    return RemoteFavoritePage(
      comics: start >= remoteFavorites.length
          ? const <Comic>[]
          : remoteFavorites.sublist(start, end),
      numPages: remoteFavorites.isEmpty
          ? 1
          : (remoteFavorites.length / pageSize).ceil(),
      total: omitTotal ? null : remoteFavorites.length,
    );
  }

  @override
  Future<void> removeRemoteFavorite(String comicId) async {
    removedComicIds.add(comicId);
    remoteFavorites =
        remoteFavorites.where((comic) => comic.id != comicId).toList();
  }
}
