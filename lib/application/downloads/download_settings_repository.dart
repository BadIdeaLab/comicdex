abstract class DownloadSettingsRepository {
  static const bool defaultAutoResumeEnabled = true;
  static const int defaultPageIntervalMs = 500;
  static const int minPageIntervalMs = 0;
  static const int maxPageIntervalMs = 3000;

  Future<bool> loadAutoResumeEnabled();

  Future<void> saveAutoResumeEnabled(bool enabled);

  Future<int> loadPageIntervalMs();

  Future<void> savePageIntervalMs(int milliseconds);
}
