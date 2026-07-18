import 'package:concept_nhv/application/reader/reader_settings_repository.dart';
import 'package:concept_nhv/storage/options_store.dart';

/// SQLite-backed implementation of [ReaderSettingsRepository] using [OptionsStore].
class ReaderSettingsStore implements ReaderSettingsRepository {
  const ReaderSettingsStore({required this.optionsStore});

  final OptionsStore optionsStore;

  static const String _prefetchPageCountKey = 'reader_prefetchPageCount';
  static const String _lastSeenPagePrefix = 'reader_lastSeenPage_';
  static const String _readingDirectionKey = 'reader_readingDirection';
  static const String _tapZoneRatioKey = 'reader_tapZoneRatio';

  @override
  Future<int> loadPrefetchPageCount() async {
    final raw = await optionsStore.loadOption(_prefetchPageCountKey);
    if (raw.isEmpty) return ReaderSettingsRepository.defaultPrefetchPageCount;
    final parsed = int.tryParse(raw);
    if (parsed == null) return ReaderSettingsRepository.defaultPrefetchPageCount;
    return parsed.clamp(
      ReaderSettingsRepository.minPrefetchPageCount,
      ReaderSettingsRepository.maxPrefetchPageCount,
    );
  }

  @override
  Future<void> savePrefetchPageCount(int count) {
    final clamped = count.clamp(
      ReaderSettingsRepository.minPrefetchPageCount,
      ReaderSettingsRepository.maxPrefetchPageCount,
    );
    return optionsStore.saveOption(_prefetchPageCountKey, clamped.toString());
  }

  @override
  Future<int?> loadLastSeenPage(String comicId) async {
    final raw = await optionsStore.loadOption('$_lastSeenPagePrefix$comicId');
    if (raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  @override
  Future<void> saveLastSeenPage(String comicId, int page) {
    return optionsStore.saveOption('$_lastSeenPagePrefix$comicId', page.toString());
  }

  @override
  Future<ReadingDirection> loadReadingDirection() async {
    final raw = await optionsStore.loadOption(_readingDirectionKey);
    return raw == 'rtl' ? ReadingDirection.rtl : ReadingDirection.ltr;
  }

  @override
  Future<void> saveReadingDirection(ReadingDirection direction) {
    return optionsStore.saveOption(_readingDirectionKey, direction.name);
  }

  @override
  Future<double> loadTapZoneRatio() async {
    final raw = await optionsStore.loadOption(_tapZoneRatioKey);
    if (raw.isEmpty) return ReaderSettingsRepository.defaultTapZoneRatio;
    final parsed = double.tryParse(raw);
    if (parsed == null) return ReaderSettingsRepository.defaultTapZoneRatio;
    return parsed.clamp(
      ReaderSettingsRepository.minTapZoneRatio,
      ReaderSettingsRepository.maxTapZoneRatio,
    );
  }

  @override
  Future<void> saveTapZoneRatio(double ratio) {
    final clamped = ratio.clamp(
      ReaderSettingsRepository.minTapZoneRatio,
      ReaderSettingsRepository.maxTapZoneRatio,
    );
    return optionsStore.saveOption(_tapZoneRatioKey, clamped.toString());
  }
}
