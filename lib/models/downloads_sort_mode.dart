enum DownloadsSortMode {
  latestDownloaded('Latest Downloaded'),
  lastRead('Last Read'),
  mostFavorited('Most Favorited'),
  title('Title'),
  author('Author');

  const DownloadsSortMode(this.label);

  final String label;
}

enum DownloadsSortDirection {
  descending('Descending'),
  ascending('Ascending');

  const DownloadsSortDirection(this.label);

  final String label;
}
