import 'package:concept_nhv/application/downloads/download_settings_repository.dart';
import 'package:concept_nhv/storage/options_store.dart';

class DownloadSettingsStore implements DownloadSettingsRepository {
  const DownloadSettingsStore({required this.optionsStore});

  final OptionsStore optionsStore;

  static const String _autoResumeKey = 'download_auto_resume_enabled';
  static const String _pageIntervalKey = 'download_page_interval_ms';

  @override
  Future<bool> loadAutoResumeEnabled() async {
    final raw = await optionsStore.loadOption(_autoResumeKey);
    if (raw.isEmpty) {
      return DownloadSettingsRepository.defaultAutoResumeEnabled;
    }
    return raw.toLowerCase() == 'true';
  }

  @override
  Future<void> saveAutoResumeEnabled(bool enabled) {
    return optionsStore.saveOption(_autoResumeKey, enabled.toString());
  }

  @override
  Future<int> loadPageIntervalMs() async {
    final raw = await optionsStore.loadOption(_pageIntervalKey);
    final parsed = int.tryParse(raw);
    if (parsed == null) {
      return DownloadSettingsRepository.defaultPageIntervalMs;
    }
    return parsed.clamp(
      DownloadSettingsRepository.minPageIntervalMs,
      DownloadSettingsRepository.maxPageIntervalMs,
    );
  }

  @override
  Future<void> savePageIntervalMs(int milliseconds) {
    final clamped = milliseconds.clamp(
      DownloadSettingsRepository.minPageIntervalMs,
      DownloadSettingsRepository.maxPageIntervalMs,
    );
    return optionsStore.saveOption(_pageIntervalKey, clamped.toString());
  }
}
