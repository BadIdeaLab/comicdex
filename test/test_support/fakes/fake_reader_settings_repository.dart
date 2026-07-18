import 'package:concept_nhv/application/reader/reader_settings_repository.dart';

/// In-memory implementation of [ReaderSettingsRepository] for use in tests.
///
/// All values are stored in-memory maps and reset between test runs via the
/// standard setUp / tearDown lifecycle.
class FakeReaderSettingsRepository implements ReaderSettingsRepository {
  int _prefetchPageCount = ReaderSettingsRepository.defaultPrefetchPageCount;
  final Map<String, int> _lastSeenPages = {};
  ReadingDirection _readingDirection = ReaderSettingsRepository.defaultReadingDirection;
  double _tapZoneRatio = ReaderSettingsRepository.defaultTapZoneRatio;

  @override
  Future<int> loadPrefetchPageCount() async => _prefetchPageCount;

  @override
  Future<void> savePrefetchPageCount(int count) async {
    _prefetchPageCount = count;
  }

  @override
  Future<int?> loadLastSeenPage(String comicId) async => _lastSeenPages[comicId];

  @override
  Future<void> saveLastSeenPage(String comicId, int page) async {
    _lastSeenPages[comicId] = page;
  }

  @override
  Future<ReadingDirection> loadReadingDirection() async => _readingDirection;

  @override
  Future<void> saveReadingDirection(ReadingDirection direction) async {
    _readingDirection = direction;
  }

  @override
  Future<double> loadTapZoneRatio() async => _tapZoneRatio;

  @override
  Future<void> saveTapZoneRatio(double ratio) async {
    _tapZoneRatio = ratio;
  }
}
