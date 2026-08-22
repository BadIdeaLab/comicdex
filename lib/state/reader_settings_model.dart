import 'package:concept_nhv/application/reader/reader_settings_repository.dart';
import 'package:flutter/foundation.dart';

/// Reader preferences that outlive any one reading session.
///
/// App-scoped on purpose: the Settings screen edits these while no reader
/// exists, so they cannot live on the per-screen session state. Everything
/// here is small, rarely written, and read by at most a handful of widgets —
/// which is what makes it safe to broadcast app-wide.
class ReaderSettingsModel extends ChangeNotifier {
  ReaderSettingsModel({required this.readerSettingsRepository});

  final ReaderSettingsRepository readerSettingsRepository;

  int _prefetchPageCount = ReaderSettingsRepository.defaultPrefetchPageCount;
  ReadingDirection _readingDirection =
      ReaderSettingsRepository.defaultReadingDirection;
  double _tapZoneRatio = ReaderSettingsRepository.defaultTapZoneRatio;

  /// How many pages before and after the current page to pre-cache.
  int get prefetchPageCount => _prefetchPageCount;

  ReadingDirection get readingDirection => _readingDirection;
  double get tapZoneRatio => _tapZoneRatio;

  /// Loads persisted reader preferences. Call once after construction.
  Future<void> loadSettings() async {
    _prefetchPageCount = await readerSettingsRepository.loadPrefetchPageCount();
    _readingDirection = await readerSettingsRepository.loadReadingDirection();
    _tapZoneRatio = await readerSettingsRepository.loadTapZoneRatio();
    notifyListeners();
  }

  /// Updates and persists [count] as the new prefetch page count.
  Future<void> savePrefetchPageCount(int count) async {
    _prefetchPageCount = count;
    await readerSettingsRepository.savePrefetchPageCount(count);
    notifyListeners();
  }

  Future<void> saveReadingDirection(ReadingDirection direction) async {
    _readingDirection = direction;
    await readerSettingsRepository.saveReadingDirection(direction);
    notifyListeners();
  }

  Future<void> saveTapZoneRatio(double ratio) async {
    _tapZoneRatio = ratio;
    await readerSettingsRepository.saveTapZoneRatio(ratio);
    notifyListeners();
  }
}
