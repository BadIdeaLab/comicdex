abstract class DownloadSettingsRepository {
  static const bool defaultAutoResumeEnabled = true;
  static const int defaultPageIntervalMs = 500;
  static const int minPageIntervalMs = 0;
  static const int maxPageIntervalMs = 3000;
  static const bool defaultCompletedViewIsGrid = false;

  Future<bool> loadAutoResumeEnabled();

  Future<void> saveAutoResumeEnabled(bool enabled);

  Future<int> loadPageIntervalMs();

  Future<void> savePageIntervalMs(int milliseconds);

  /// Whether the completed-downloads section is shown as a grid.
  Future<bool> loadCompletedViewIsGrid();

  Future<void> saveCompletedViewIsGrid(bool isGrid);
}
