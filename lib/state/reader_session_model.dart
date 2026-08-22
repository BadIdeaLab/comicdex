import 'package:concept_nhv/application/reader/load_comic_detail_use_case.dart';
import 'package:concept_nhv/application/reader/load_offline_comic_use_case.dart';
import 'package:concept_nhv/application/reader/open_comic_use_case.dart';
import 'package:concept_nhv/application/reader/reader_progress_repository.dart';
import 'package:concept_nhv/application/reader/reader_settings_repository.dart';
import 'package:concept_nhv/models/comic.dart';
import 'package:concept_nhv/storage/downloaded_library_repository.dart';
import 'package:flutter/material.dart';

/// Why a reading session could not start.
enum ReaderLoadFailure {
  /// The offline entry point was used for a comic with no completed download.
  notDownloaded,

  /// The detail request failed — no network, rate limited, unknown id.
  loadFailed,
}

enum ReaderLoadState { loading, ready, failed }

/// State for **one** open comic, owned by the reader screen that shows it.
///
/// Screen-scoped rather than app-scoped, and that is the whole point: the
/// [PageController] below can only ever be attached to one `PageView`, so an
/// app-scoped instance broke outright the moment two reader routes existed
/// (see P65). Tying its lifetime to the screen makes that structurally
/// impossible, and means nothing outside the reader can be woken by a page
/// turn.
class ReaderSessionModel extends ChangeNotifier {
  ReaderSessionModel({
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
  int _currentPage = 1;
  bool _showControls = false;
  ReaderLoadState _loadState = ReaderLoadState.loading;
  ReaderLoadFailure? _failure;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  Comic? get currentComic => _currentComic;

  ReaderLoadState get loadState => _loadState;
  bool get isReady => _loadState == ReaderLoadState.ready;

  /// Set only while [loadState] is [ReaderLoadState.failed].
  ReaderLoadFailure? get failure => _failure;

  /// 1-indexed current page number.
  int get currentPage => _currentPage;

  int get totalPages => _currentComic?.numPages ?? 0;

  /// Favorites count of the current comic, or null if not yet loaded.
  int? get numFavorites => _currentComic?.numFavorites;

  /// Whether the bottom controls overlay should be visible.
  bool get showControls => _showControls;

  // ---------------------------------------------------------------------------
  // Comic loading
  // ---------------------------------------------------------------------------

  /// Loads [comicId] and moves to [ReaderLoadState.ready] or
  /// [ReaderLoadState.failed].
  ///
  /// **Local first**: a comic that is already downloaded is read from disk, so
  /// opening it costs no request and works with no connection at all. Only a
  /// comic with no completed download falls through to the API.
  ///
  /// [offline] makes that strict — local or nothing. The Downloads tab uses it
  /// because that list promises an on-device library: quietly pulling a whole
  /// comic over a metered connection from there would be a surprise, and a
  /// download that cannot be read locally is a broken download, not a cue to
  /// re-fetch it.
  ///
  /// Never throws: the screen has nowhere to hand an exception, and an
  /// unhandled one would leave it spinning forever with no way out.
  Future<void> open({required String comicId, bool offline = false}) async {
    _loadState = ReaderLoadState.loading;
    _failure = null;
    notifyListeners();

    try {
      if (await loadOfflineComic(comicId)) {
        _loadState = ReaderLoadState.ready;
        notifyListeners();
        return;
      }
      if (offline) {
        _fail(ReaderLoadFailure.notDownloaded);
        return;
      }
      await loadComicDetail(comicId);
      _loadState = ReaderLoadState.ready;
      notifyListeners();
    } catch (_) {
      _fail(ReaderLoadFailure.loadFailed);
    }
  }

  void _fail(ReaderLoadFailure failure) {
    _currentComic = null;
    _failure = failure;
    _loadState = ReaderLoadState.failed;
    notifyListeners();
  }

  Future<void> loadComicDetail(String comicId) async {
    await openComic(await loadComicDetailUseCase.execute(comicId));
  }

  /// Opens a completed download in the reader using locally stored page files.
  ///
  /// Reconstructs a [Comic] from the local DB without making any network
  /// requests. Returns false if no completed download record is found.
  Future<bool> loadOfflineComic(String comicId) async {
    final comic = await loadOfflineComicUseCase.execute(comicId);
    if (comic == null) return false;
    await openComic(comic, isDegradedMetadata: true);
    return true;
  }

  Future<void> openComic(Comic comic, {bool isDegradedMetadata = false}) async {
    _currentComic = comic;
    _currentPage = 1;
    _showControls = false;
    await openComicUseCase.execute(
      comic,
      isDegradedMetadata: isDegradedMetadata,
    );
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

  /// Jumps [pageController] to the given 1-indexed [page].
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

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
