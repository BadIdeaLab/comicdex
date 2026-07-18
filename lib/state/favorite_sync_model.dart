import 'dart:async';
import 'dart:collection';

import 'package:concept_nhv/application/favorites/clear_favorite_auth_use_case.dart';
import 'package:concept_nhv/application/favorites/initialize_favorites_use_case.dart';
import 'package:concept_nhv/application/favorites/save_api_key_use_case.dart';
import 'package:concept_nhv/application/favorites/sync_remote_favorites_use_case.dart';
import 'package:concept_nhv/application/favorites/toggle_favorite_use_case.dart';
import 'package:concept_nhv/models/comic_card_data.dart';
import 'package:flutter/material.dart';

class FavoriteSyncModel extends ChangeNotifier {
  FavoriteSyncModel({
    required this.initializeFavoritesUseCase,
    required this.saveApiKeyUseCase,
    required this.clearFavoriteAuthUseCase,
    required this.syncRemoteFavoritesUseCase,
    required this.toggleFavoriteUseCase,
  });

  final InitializeFavoritesUseCase initializeFavoritesUseCase;
  final SaveApiKeyUseCase saveApiKeyUseCase;
  final ClearFavoriteAuthUseCase clearFavoriteAuthUseCase;
  final SyncRemoteFavoritesUseCase syncRemoteFavoritesUseCase;
  final ToggleFavoriteUseCase toggleFavoriteUseCase;

  final Set<String> _favoriteIds = <String>{};
  final Set<String> _mutatingIds = <String>{};
  bool _isSyncing = false;
  bool _isAuthenticated = false;
  bool _initialized = false;
  String? _syncError;
  DateTime? _lastSyncAt;
  int? _syncPage;
  int? _syncTotalPages;
  DateTime? _syncRetryDeadline;
  Timer? _syncRetryTimer;

  Set<String> get favoriteIds => UnmodifiableSetView<String>(_favoriteIds);
  bool get isSyncing => _isSyncing;
  bool get isAuthenticated => _isAuthenticated;
  bool get isInitialized => _initialized;
  String? get syncError => _syncError;
  DateTime? get lastSyncAt => _lastSyncAt;
  int? get syncPage => _syncPage;
  int? get syncTotalPages => _syncTotalPages;
  DateTime? get syncRetryDeadline => _syncRetryDeadline;
  bool get hasCachedFavorites => _favoriteIds.isNotEmpty;

  bool isFavorite(String comicId) => _favoriteIds.contains(comicId);

  bool isMutating(String comicId) => _mutatingIds.contains(comicId);

  Future<void> initialize() async {
    final snapshot = await initializeFavoritesUseCase.execute();
    _favoriteIds
      ..clear()
      ..addAll(snapshot.favoriteIds);
    _isAuthenticated = snapshot.isAuthenticated;
    _lastSyncAt = snapshot.lastSyncAt;
    _initialized = true;
    notifyListeners();
  }

  Future<bool> syncFavorites() async {
    if (_isSyncing) {
      return false;
    }

    _isSyncing = true;
    _syncError = null;
    _syncPage = null;
    _syncTotalPages = null;
    _syncRetryDeadline = null;
    notifyListeners();

    try {
      final result = await syncRemoteFavoritesUseCase.execute(
        onProgress: (page, totalPages) {
          _syncPage = page;
          _syncTotalPages = totalPages;
          _clearRetryCountdown();
          notifyListeners();
        },
        onRateLimit: (retryIn) {
          _startRetryCountdown(retryIn);
        },
      );
      _favoriteIds
        ..clear()
        ..addAll(result.favoriteIds);
      _isAuthenticated = result.isAuthenticated;
      _lastSyncAt = result.lastSyncAt ?? _lastSyncAt;
      _syncError = result.errorMessage;
      return result.success;
    } finally {
      _isSyncing = false;
      _syncPage = null;
      _syncTotalPages = null;
      _clearRetryCountdown();
      notifyListeners();
    }
  }

  void _startRetryCountdown(Duration retryIn) {
    _syncRetryDeadline = DateTime.now().add(retryIn);
    _syncRetryTimer?.cancel();
    _syncRetryTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
      if (_syncRetryDeadline != null &&
          DateTime.now().isAfter(_syncRetryDeadline!)) {
        _clearRetryCountdown();
      }
    });
    notifyListeners();
  }

  void _clearRetryCountdown() {
    _syncRetryTimer?.cancel();
    _syncRetryTimer = null;
    _syncRetryDeadline = null;
  }

  @override
  void dispose() {
    _syncRetryTimer?.cancel();
    super.dispose();
  }

  Future<void> saveAndValidateApiKey(String apiKey) async {
    await saveApiKeyUseCase.execute(apiKey);
    await initialize();
  }

  Future<bool> toggleFavorite(ComicCardData comic) async {
    if (_mutatingIds.contains(comic.id)) {
      return false;
    }

    _mutatingIds.add(comic.id);
    _syncError = null;
    notifyListeners();

    try {
      final result = await toggleFavoriteUseCase.execute(
        comic: comic,
        isFavorite: isFavorite(comic.id),
      );
      _favoriteIds
        ..clear()
        ..addAll(result.favoriteIds);
      _isAuthenticated = result.isAuthenticated;
      _lastSyncAt = result.lastSyncAt ?? _lastSyncAt;
      _syncError = result.errorMessage;
      return result.success;
    } finally {
      _mutatingIds.remove(comic.id);
      notifyListeners();
    }
  }

  Future<void> clearApiKey() async {
    await clearFavoriteAuthUseCase.execute();
    _isAuthenticated = false;
    _lastSyncAt = null;
    _syncError = null;
    notifyListeners();
  }
}
