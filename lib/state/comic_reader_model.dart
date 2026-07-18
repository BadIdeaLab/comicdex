import 'package:concept_nhv/application/reader/load_comic_detail_use_case.dart';
import 'package:concept_nhv/application/reader/load_offline_comic_use_case.dart';
import 'package:concept_nhv/application/reader/open_comic_use_case.dart';
import 'package:concept_nhv/application/reader/reader_progress_repository.dart';
import 'package:concept_nhv/application/reader/reader_settings_repository.dart';
import 'package:concept_nhv/models/comic.dart';
import 'package:concept_nhv/storage/downloaded_library_repository.dart';
import 'package:flutter/material.dart';

/// State model for the comic reader.
///
/// Manages the currently open comic, page-level navigation, pre-fetch settings,
/// and the visibility of the reader controls overlay.
class ComicReaderModel extends ChangeNotifier {
  ComicReaderModel({
    required this.loadComicDetailUseCase,
    required this.loadOfflineComicUseCase,
    required this.openComicUseCase,
    required this.readerProgressRepository,
    required this.readerSettingsRepository,
    required this.downloadedLibraryRepository,
  });

  final LoadComicDetailUseCase loadComicDetailUseCase;
  final LoadOfflineComicUseCase loadOfflineComicUseCase;
  final OpenComicUseCase openComicUseCase;
  final ReaderProgressRepository readerProgressRepository;
  final ReaderSettingsRepository readerSettingsRepository;
  final DownloadedLibraryRepository downloadedLibraryRepository;

  final PageController pageController = PageController();

  Comic? _currentComic;
  Map<String, String>? _currentHeaders;
  int _currentPage = 1;
  bool _showControls = false;
  int _prefetchPageCount = ReaderSettingsRepository.defaultPrefetchPageCount;
  ReadingDirection _readingDirection = ReaderSettingsRepository.defaultReadingDirection;
  double _tapZoneRatio = ReaderSettingsRepository.defaultTapZoneRatio;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  Comic? get currentComic => _currentComic;
  Map<String, String>? get currentHeaders => _currentHeaders;

  /// 1-indexed current page number.
  int get currentPage => _currentPage;

  int get totalPages => _currentComic?.numPages ?? 0;

  /// Favorites count of the current comic, or null if not yet loaded.
  int? get numFavorites => _currentComic?.numFavorites;

  /// Whether the bottom controls overlay should be visible.
  bool get showControls => _showControls;

  /// How many pages before and after the current page to pre-cache.
  int get prefetchPageCount => _prefetchPageCount;

  ReadingDirection get readingDirection => _readingDirection;
  double get tapZoneRatio => _tapZoneRatio;

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Comic loading
  // ---------------------------------------------------------------------------

  Future<void> loadComicDetail(String comicId) async {
    final result = await loadComicDetailUseCase.execute(comicId);
    _currentHeaders = result.headers;
    await openComic(result.comic);
  }

  /// Opens a completed download in the reader using locally stored page files.
  ///
  /// Reconstructs a [Comic] from the local DB without making any network
  /// requests. Returns false if no completed download record is found.
  Future<bool> loadOfflineComic(String comicId) async {
    final comic = await loadOfflineComicUseCase.execute(comicId);
    if (comic == null) return false;
    await openComic(comic);
    return true;
  }

  Future<void> openComic(Comic comic) async {
    _currentComic = comic;
    _currentPage = 1;
    _showControls = false;
    await openComicUseCase.execute(comic);
    await downloadedLibraryRepository.saveLastReadAt(comic.id, DateTime.now());
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Page navigation
  // ---------------------------------------------------------------------------

  /// Called by [PageView.onPageChanged]. Keeps [_currentPage] in sync and
  /// persists progress.
  void onPageChanged(int pageIndex, String comicId) {
    _currentPage = pageIndex + 1;
    notifyListeners();
    readerSettingsRepository.saveLastSeenPage(comicId, _currentPage);
    downloadedLibraryRepository.saveLastReadAt(comicId, DateTime.now());
  }

  /// Animates [pageController] to the given 1-indexed [page].
  void goToPage(int page) {
    if (_currentComic == null) return;
    final target = page.clamp(1, totalPages);
    pageController.jumpToPage(target - 1);
  }

  // ---------------------------------------------------------------------------
  // Controls overlay
  // ---------------------------------------------------------------------------

  void toggleControls() {
    _showControls = !_showControls;
    notifyListeners();
  }

  void showControlsOverlay() {
    if (_showControls) return;
    _showControls = true;
    notifyListeners();
  }

  void hideControls() {
    if (!_showControls) return;
    _showControls = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Progress persistence (legacy offset-based, kept for backward compat)
  // ---------------------------------------------------------------------------

  Future<void> persistLastSeenOffset(String comicId, double offset) async {
    if (offset == 0) return;
    await readerProgressRepository.saveLastSeenOffset(comicId, offset);
  }

  Future<double?> loadLastSeenOffset(String comicId) {
    return readerProgressRepository.loadLastSeenOffset(comicId);
  }

  // ---------------------------------------------------------------------------
  // Progress persistence (page-based)
  // ---------------------------------------------------------------------------

  Future<int?> loadLastSeenPage(String comicId) {
    return readerSettingsRepository.loadLastSeenPage(comicId);
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  void clearComic() {
    _currentComic = null;
    _currentHeaders = null;
    _currentPage = 1;
    _showControls = false;
    notifyListeners();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
