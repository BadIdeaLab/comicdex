enum DownloadsSortMode {
  latestDownloaded('Latest Downloaded'),
  lastRead('Last Read'),
  mostFavorited('Most Favorited'),
  title('Title'),
  author('Author'),

  /// Ranked by how well the comic's tags match the user's taste (P84).
  /// Local data only, so unlike the home tab there is no pagination to make
  /// the order misleading.
  preference('Preference');

  const DownloadsSortMode(this.label);

  final String label;
}

enum DownloadsSortDirection {
  descending('Descending'),
  ascending('Ascending');

  const DownloadsSortDirection(this.label);

  final String label;
}
