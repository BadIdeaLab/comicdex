class FavoriteSyncSnapshot {
  const FavoriteSyncSnapshot({
    required this.favoriteIds,
    required this.isAuthenticated,
    required this.lastSyncAt,
  });

  final Set<String> favoriteIds;
  final bool isAuthenticated;
  final DateTime? lastSyncAt;
}
