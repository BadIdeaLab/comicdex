class FavoriteSyncResult {
  const FavoriteSyncResult({
    required this.favoriteIds,
    required this.isAuthenticated,
    required this.lastSyncAt,
    required this.success,
    this.errorMessage,
  });

  final Set<String> favoriteIds;
  final bool isAuthenticated;
  final DateTime? lastSyncAt;
  final bool success;
  final String? errorMessage;
}
