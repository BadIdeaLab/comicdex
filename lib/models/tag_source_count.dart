/// How many comics carrying [tagId] sit in each source. A comic counts once
/// per source it belongs to, so one comic can add to all three.
class TagSourceCount {
  const TagSourceCount({
    required this.tagId,
    required this.collectedCount,
    required this.favoriteCount,
    required this.downloadedCount,
    required this.historyCount,
  });

  final int tagId;

  /// Comics that are favorited **or** downloaded, counted once even when
  /// they are both — the P78 ranking signal.
  final int collectedCount;
  final int favoriteCount;
  final int downloadedCount;
  final int historyCount;
}
