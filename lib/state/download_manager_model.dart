import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:concept_nhv/application/downloads/download_settings_repository.dart';
import 'package:concept_nhv/models/comic.dart';
import 'package:concept_nhv/models/comic_card_data.dart';
import 'package:concept_nhv/models/comic_images.dart';
import 'package:concept_nhv/models/comic_title.dart';
import 'package:concept_nhv/models/download_list_item_snapshot.dart';
import 'package:concept_nhv/models/download_job_snapshot.dart';
import 'package:concept_nhv/models/download_job_status.dart';
import 'package:concept_nhv/models/download_page_snapshot.dart';
import 'package:concept_nhv/models/download_page_status.dart';
import 'package:concept_nhv/models/download_request.dart';
import 'package:concept_nhv/models/downloaded_comic_snapshot.dart';
import 'package:concept_nhv/models/downloads_sort_mode.dart';
import 'package:concept_nhv/services/download_asset_store.dart';
import 'package:concept_nhv/services/image_compression_service.dart';
import 'package:concept_nhv/services/nhentai_api_client.dart';
import 'package:concept_nhv/services/nhentai_cdn_config_service.dart';
import 'package:concept_nhv/services/remote_asset_fetcher.dart';
import 'package:concept_nhv/services/rate_limit_retry.dart';
import 'package:concept_nhv/storage/download_queue_repository.dart';
import 'package:concept_nhv/storage/downloaded_library_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;

/// Extensions Flutter's built-in Skia codec can reliably decode via
/// `Image.file`/`Image.memory`. Anything outside this set (heif/avif/tiff/
/// unknown) is still transcoded to WebP so the reader never gets stuck on
/// an undecodable local file.
const _skiaSafeExtensions = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'};

class DownloadManagerModel extends ChangeNotifier with WidgetsBindingObserver {
  DownloadManagerModel({
    required this.nhentaiGateway,
    required this.cdnConfigService,
    required this.downloadQueueRepository,
    required this.downloadedLibraryRepository,
    required this.downloadSettingsRepository,
    required this.downloadAssetStore,
    required this.imageCompressionService,
    required this.remoteAssetFetcher,
  });

  final NhentaiGateway nhentaiGateway;
  final NhentaiCdnConfigService cdnConfigService;
  final DownloadQueueRepository downloadQueueRepository;
  final DownloadedLibraryRepository downloadedLibraryRepository;
  final DownloadSettingsRepository downloadSettingsRepository;
  final DownloadAssetStore downloadAssetStore;
  final ImageCompressionService imageCompressionService;
  final RemoteAssetFetcher remoteAssetFetcher;

  static const int completedPageSize = 30;

  List<DownloadJobSnapshot> _jobs = const <DownloadJobSnapshot>[];
  List<DownloadListItemSnapshot> _downloadItems =
      const <DownloadListItemSnapshot>[];
  DownloadsSortMode _downloadsSortMode = DownloadsSortMode.latestDownloaded;
  DownloadsSortDirection _downloadsSortDirection =
      DownloadsSortDirection.descending;
  int _completedPage = 1;
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _isRefreshing = false;
  bool _isDisposed = false;
  final Set<String> _mutatingComicIds = <String>{};

  List<DownloadJobSnapshot> get jobs => _jobs;
  List<DownloadListItemSnapshot> get downloadItems => _downloadItems;
  DownloadsSortMode get downloadsSortMode => _downloadsSortMode;
  DownloadsSortDirection get downloadsSortDirection =>
      _downloadsSortDirection;
  int get completedPage => _completedPage;
  bool get isRefreshing => _isRefreshing;
  bool isMutating(String comicId) => _mutatingComicIds.contains(comicId);

  void setCompletedPage(int page) {
    if (_completedPage == page) return;
    _completedPage = page;
    notifyListeners();
  }

  void resetCompletedPage() {
    if (_completedPage == 1) return;
    _completedPage = 1;
    notifyListeners();
  }

  List<DownloadListItemSnapshot> get sortedDownloadItems {
    final activeItems = _downloadItems
        .where((item) => item.status != DownloadJobStatus.completed)
        .toList(growable: false)
      ..sort(_compareActiveItems);
    final completedItems = _downloadItems
        .where((item) => item.status == DownloadJobStatus.completed)
        .toList(growable: false)
      ..sort(_compareCompletedItems);
    return List<DownloadListItemSnapshot>.unmodifiable(
      <DownloadListItemSnapshot>[
        ...activeItems,
        ...completedItems,
      ],
    );
  }

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }
    _isInitialized = true;
    WidgetsBinding.instance.addObserver(this);
    await refresh();
    await _maybeAutoResume();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_maybeAutoResume());
    }
  }

  Future<void> refresh() async {
    if (_isDisposed) {
      return;
    }
    _isRefreshing = true;
    notifyListeners();
    await _syncState();
    if (_isDisposed) {
      return;
    }
    _isRefreshing = false;
    notifyListeners();
  }

  /// Reloads jobs/downloaded comics from the DB and notifies listeners,
  /// without touching [isRefreshing] — used for the per-page/per-job resyncs
  /// inside [_processJob], which fire far too often to double as a
  /// user-visible "refreshing" signal (that was flashing the app bar's
  /// loading indicator on every single page).
  Future<void> _syncState() async {
    if (_isDisposed) {
      return;
    }
    final jobs = await downloadQueueRepository.loadJobs();
    final rawDownloadedComics =
        await downloadedLibraryRepository.loadDownloadedComics();
    final downloadedComics = await _resolveCoverPaths(rawDownloadedComics);
    if (_isDisposed) {
      return;
    }
    _jobs = jobs;
    _downloadItems = _buildDownloadItems(jobs, downloadedComics);
    notifyListeners();
  }

  DownloadJobSnapshot? jobForComic(String comicId) {
    for (final job in _jobs) {
      if (job.comicId == comicId) {
        return job;
      }
    }
    return null;
  }

  void setDownloadsSortMode(DownloadsSortMode mode) {
    if (_downloadsSortMode == mode) {
      return;
    }
    _downloadsSortMode = mode;
    notifyListeners();
  }

  void setDownloadsSortDirection(DownloadsSortDirection direction) {
    if (_downloadsSortDirection == direction) {
      return;
    }
    _downloadsSortDirection = direction;
    notifyListeners();
  }

  /// Resolves each [DownloadedComicSnapshot.coverLocalPath] (stored relative
  /// to the downloads root — see .codex/phases/P51-relative-download-paths.md)
  /// to an absolute path before it reaches [DownloadListItemSnapshot] and,
  /// downstream, `Image.file`/`File` in the downloads UI.
  Future<List<DownloadedComicSnapshot>> _resolveCoverPaths(
    List<DownloadedComicSnapshot> comics,
  ) async {
    return Future.wait(comics.map((comic) async {
      final coverLocalPath = comic.coverLocalPath;
      if (coverLocalPath == null || coverLocalPath.isEmpty) {
        return comic;
      }
      return DownloadedComicSnapshot(
        comicId: comic.comicId,
        mediaId: comic.mediaId,
        title: comic.title,
        rootDirectoryPath: comic.rootDirectoryPath,
        pageCount: comic.pageCount,
        downloadedAt: comic.downloadedAt,
        tags: comic.tags,
        coverLocalPath: await downloadAssetStore.resolveAbsolutePath(
          coverLocalPath,
        ),
        lastReadAt: comic.lastReadAt,
        numFavorites: comic.numFavorites,
      );
    }));
  }

  List<DownloadListItemSnapshot> _buildDownloadItems(
    List<DownloadJobSnapshot> jobs,
    List<DownloadedComicSnapshot> downloadedComics,
  ) {
    final downloadedByComicId = <String, DownloadedComicSnapshot>{
      for (final downloadedComic in downloadedComics)
        downloadedComic.comicId: downloadedComic,
    };
    final items = <DownloadListItemSnapshot>[];
    for (final job in jobs) {
      final downloadedComic = downloadedByComicId.remove(job.comicId);
      items.add(
        DownloadListItemSnapshot.fromJob(
          job,
          downloadedComic: downloadedComic,
        ),
      );
    }
    for (final downloadedComic in downloadedByComicId.values) {
      items.add(
        DownloadListItemSnapshot.fromDownloadedComic(downloadedComic),
      );
    }
    return List<DownloadListItemSnapshot>.unmodifiable(items);
  }

  int _compareActiveItems(
    DownloadListItemSnapshot a,
    DownloadListItemSnapshot b,
  ) {
    final statusComparison = _downloadJobStatusPriority(a.status).compareTo(
      _downloadJobStatusPriority(b.status),
    );
    if (statusComparison != 0) {
      return statusComparison;
    }
    return b.requestedAt.compareTo(a.requestedAt);
  }

  int _compareCompletedItems(
    DownloadListItemSnapshot a,
    DownloadListItemSnapshot b,
  ) {
    return switch (_downloadsSortMode) {
      DownloadsSortMode.latestDownloaded => _compareByDirection(
        a.downloadedAt ?? a.updatedAt,
        b.downloadedAt ?? b.updatedAt,
      ),
      DownloadsSortMode.lastRead => _compareLastReadItems(a, b),
      DownloadsSortMode.mostFavorited => _compareMostFavoritedItems(a, b),
      DownloadsSortMode.title => _compareByDirection(
        a.title.toLowerCase(),
        b.title.toLowerCase(),
      ),
      DownloadsSortMode.author => _compareAuthorItems(a, b),
    };
  }

  int _compareAuthorItems(
    DownloadListItemSnapshot a,
    DownloadListItemSnapshot b,
  ) {
    final aAuthor = _authorName(a);
    final bAuthor = _authorName(b);
    if (aAuthor == null && bAuthor == null) {
      return _compareByDirection(a.title.toLowerCase(), b.title.toLowerCase());
    }
    if (aAuthor == null) return 1;
    if (bAuthor == null) return -1;
    return _compareByDirection(aAuthor.toLowerCase(), bAuthor.toLowerCase());
  }

  /// First `artist` tag name, falling back to the first `group` tag —
  /// this project has no dedicated author field; artist/group tags are how
  /// doujin authorship is represented (same convention used to group tags
  /// in comic_tag_bottom_sheet.dart).
  String? _authorName(DownloadListItemSnapshot item) {
    for (final tag in item.tags) {
      if (tag.type == 'artist' && (tag.name?.isNotEmpty ?? false)) {
        return tag.name;
      }
    }
    for (final tag in item.tags) {
      if (tag.type == 'group' && (tag.name?.isNotEmpty ?? false)) {
        return tag.name;
      }
    }
    return null;
  }

  int _compareLastReadItems(
    DownloadListItemSnapshot a,
    DownloadListItemSnapshot b,
  ) {
    final aTimestamp = a.lastReadAt ?? a.downloadedAt ?? a.updatedAt;
    final bTimestamp = b.lastReadAt ?? b.downloadedAt ?? b.updatedAt;
    return _compareByDirection(aTimestamp, bTimestamp);
  }

  int _compareMostFavoritedItems(
    DownloadListItemSnapshot a,
    DownloadListItemSnapshot b,
  ) {
    final aFavorites = a.numFavorites;
    final bFavorites = b.numFavorites;
    if (aFavorites == null && bFavorites == null) {
      return (b.downloadedAt ?? b.updatedAt).compareTo(
        a.downloadedAt ?? a.updatedAt,
      );
    }
    if (aFavorites == null) {
      return 1;
    }
    if (bFavorites == null) {
      return -1;
    }
    return _compareByDirection(aFavorites, bFavorites);
  }

  int _compareByDirection<T extends Comparable<T>>(T a, T b) {
    return switch (_downloadsSortDirection) {
      DownloadsSortDirection.descending => b.compareTo(a),
      DownloadsSortDirection.ascending => a.compareTo(b),
    };
  }

  int _downloadJobStatusPriority(DownloadJobStatus status) {
    return switch (status) {
      DownloadJobStatus.downloading => 0,
      DownloadJobStatus.queued => 1,
      DownloadJobStatus.failed => 2,
      DownloadJobStatus.paused => 3,
      DownloadJobStatus.completed => 4,
    };
  }

  Future<void> enqueue(DownloadRequest request) async {
    await _runMutatingJobAction(request.comicId, () async {
      final existingJob = await downloadQueueRepository.loadJob(request.comicId);
      if (existingJob != null) {
        await refresh();
        return;
      }

      final result = await nhentaiGateway.loadComicDetail(request.comicId);
      await downloadQueueRepository.upsertJobManifest(
        comic: result.comic,
        title: request.title,
      );
      await refresh();
      unawaited(_processQueue());
    });
  }

  /// Batch version of [enqueue] for multi-select flows (e.g. downloading a
  /// large batch of favorites at once). Processes [comics] sequentially with
  /// a throttling delay and 429 backoff/retry between network requests, and
  /// stops early after too many consecutive failures instead of continuing
  /// to hammer the API. Comics whose cached [ComicCardData.serializedImages]
  /// already contains the full page manifest (e.g. opened in the reader
  /// before being favorited) skip the network round trip entirely.
  Future<
      ({
        int queuedCount,
        int skippedCount,
        int failedCount,
        int totalCount,
        bool stoppedEarly,
      })> enqueueMany(
    List<ComicCardData> comics, {
    void Function(int processed, int total)? onProgress,
  }) async {
    var queuedCount = 0;
    var skippedCount = 0;
    var failedCount = 0;
    var consecutiveFailures = 0;
    var processedCount = 0;
    final total = comics.length;

    for (final comic in comics) {
      if (_isDisposed) break;
      var hitNetwork = false;
      try {
        final outcome = await _enqueueOne(comic);
        hitNetwork = outcome.hitNetwork;
        if (outcome.skipped) {
          skippedCount += 1;
        } else {
          queuedCount += 1;
        }
        consecutiveFailures = 0;
      } catch (_) {
        failedCount += 1;
        hitNetwork = true;
        consecutiveFailures += 1;
      }
      processedCount += 1;
      onProgress?.call(processedCount, total);

      if (consecutiveFailures >= _maxConsecutiveNetworkFailures) {
        break;
      }
      if (hitNetwork && processedCount < total) {
        await Future<void>.delayed(_networkThrottleDelay);
      }
    }

    unawaited(_processQueue());

    return (
      queuedCount: queuedCount,
      skippedCount: skippedCount,
      failedCount: failedCount,
      totalCount: total,
      stoppedEarly: consecutiveFailures >= _maxConsecutiveNetworkFailures,
    );
  }

  Future<({bool hitNetwork, bool skipped})> _enqueueOne(
    ComicCardData comic,
  ) async {
    ({bool hitNetwork, bool skipped})? outcome;
    await _runMutatingJobAction(comic.id, () async {
      final existingJob = await downloadQueueRepository.loadJob(comic.id);
      if (existingJob != null) {
        await refresh();
        outcome = (hitNetwork: false, skipped: true);
        return;
      }

      final localComic = _tryBuildCompleteLocalComic(comic);
      if (localComic != null) {
        await downloadQueueRepository.upsertJobManifest(
          comic: localComic,
          title: comic.title,
        );
        await refresh();
        outcome = (hitNetwork: false, skipped: false);
        return;
      }

      final detail = await _loadComicDetailWithRetry(comic.id);
      await downloadQueueRepository.upsertJobManifest(
        comic: detail.comic,
        title: comic.title,
      );
      await refresh();
      outcome = (hitNetwork: true, skipped: false);
    });
    // Another mutation was already in flight for this comic (e.g. the user
    // tapped its card's own download button mid-batch) — treat it as
    // already handled rather than as a failure.
    return outcome ?? (hitNetwork: false, skipped: true);
  }

  /// Builds a [Comic] directly from cached favorites data when the full page
  /// manifest is already present locally, so [enqueueMany] can skip the
  /// `loadComicDetail` network call for it. Returns null when the cached
  /// data is incomplete — e.g. synced from the remote favorites list, which
  /// only ever carries the thumbnail, not the per-page manifest — and a
  /// network call is required.
  Comic? _tryBuildCompleteLocalComic(ComicCardData comic) {
    if (comic.pages <= 0) return null;
    final ComicImages images;
    try {
      images = ComicImages.fromJson(
        jsonDecode(comic.serializedImages) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
    if (images.pages.length < comic.pages) return null;
    return Comic(
      id: comic.id,
      mediaId: comic.mediaId,
      title: ComicTitle(pretty: comic.title),
      images: images,
      tags: comic.tags,
      numPages: comic.pages,
      uploadDate: comic.uploadDate,
    );
  }

  Future<({Comic comic, Map<String, String>? headers})>
  _loadComicDetailWithRetry(String comicId) {
    return withRateLimitRetry(() => nhentaiGateway.loadComicDetail(comicId));
  }

  Future<void> pause(String comicId) async {
    await _runMutatingJobAction(comicId, () async {
      await downloadQueueRepository.markJobPaused(comicId);
      await refresh();
    });
  }

  Future<void> resume(String comicId) async {
    await _runMutatingJobAction(comicId, () async {
      await downloadQueueRepository.requeueJob(comicId);
      await refresh();
      unawaited(_processQueue());
    });
  }

  Future<void> retry(String comicId) async {
    await _runMutatingJobAction(comicId, () async {
      await downloadQueueRepository.requeueJob(comicId);
      await refresh();
      unawaited(_processQueue());
    });
  }

  Future<void> deleteJob(String comicId) async {
    await _runMutatingJobAction(comicId, () async {
      await downloadQueueRepository.markJobPaused(comicId);
      await downloadQueueRepository.deleteJob(comicId);
      await downloadedLibraryRepository.deleteDownloadedComic(comicId);
      await downloadAssetStore.deleteComicAssets(comicId);
      await refresh();
    });
  }

  /// Re-downloads a completed comic from scratch while preserving its library
  /// metadata (lastReadAt, tags, numFavorites).
  ///
  /// Steps:
  /// 1. Delete existing queue records and assets (library row is kept).
  /// 2. Call the API to obtain the fresh page manifest.
  /// 3. Enqueue the new job and kick the download engine.
  Future<void> reloadCompleted(String comicId) async {
    await _runMutatingJobAction(comicId, () async {
      await downloadQueueRepository.deleteQueueOnly(comicId);
      await downloadAssetStore.deleteComicAssets(comicId);

      final detail = await nhentaiGateway.loadComicDetail(comicId);
      final comic = detail.comic;
      final title = _libraryTitle(comicId) ??
          comic.title.pretty ??
          comic.title.english ??
          comic.title.japanese ??
          comicId;
      await downloadQueueRepository.upsertJobManifest(
        comic: comic,
        title: title,
      );
      await refresh();
      unawaited(_processQueue());
    });
  }

  /// Re-downloads only the pages that are missing or have zero byte size on disk.
  ///
  /// Steps:
  /// 1. Load pages from DB and verify each file.
  /// 2. Reset missing page records to pending.
  /// 3. Requeue the job and kick the download engine.
  ///
  /// If all pages are intact, this is a no-op (returns without re-queuing).
  /// Repairs missing pages and/or a missing cover for [comicId].
  ///
  /// Returns true if a repair was actually performed and verified (pages
  /// requeued and/or the cover re-downloaded), false if everything was
  /// already intact.
  ///
  /// Throws if the cover was the *only* problem and repairing it failed —
  /// callers must not treat that as success (a deferred page requeue, by
  /// contrast, is reported optimistically since its outcome isn't known
  /// synchronously, and a follow-up page repair gives the cover another
  /// chance via [_processJob]).
  Future<bool> repairCompleted(String comicId) async {
    var repaired = false;
    Object? coverFailure;
    await _runMutatingJobAction(comicId, () async {
      final pages = await downloadQueueRepository.loadPages(comicId);
      final pageLocalPaths = <int, String?>{
        for (final page in pages) page.pageNumber: page.localPath,
      };
      final missingPageNumbers = await downloadAssetStore.verifyPages(pageLocalPaths);

      final currentCoverPath = await downloadedLibraryRepository.loadCoverLocalPath(
        comicId,
      );
      final coverMissing = !await downloadAssetStore.coverExists(currentCoverPath);

      if (missingPageNumbers.isEmpty && !coverMissing) {
        return;
      }

      var coverFixed = true;
      if (coverMissing) {
        coverFixed = await _repairCover(comicId);
      }

      if (missingPageNumbers.isNotEmpty) {
        await downloadQueueRepository.resetMissingPages(comicId, missingPageNumbers);
        await downloadQueueRepository.requeueJob(comicId);
        await refresh();
        unawaited(_processQueue());
        repaired = true;
      } else if (coverFixed) {
        await refresh();
        repaired = true;
      } else {
        await refresh();
        coverFailure = StateError('Failed to repair cover for $comicId');
      }
    });
    if (coverFailure != null) {
      throw coverFailure!;
    }
    return repaired;
  }

  /// Re-fetches comic detail and re-downloads the cover for [comicId],
  /// updating the stored [DownloadedComicSnapshot.coverLocalPath] on success.
  ///
  /// Returns true only if the cover was actually verified and saved; callers
  /// must not assume success just because this was attempted.
  Future<bool> _repairCover(String comicId) async {
    try {
      final detail = await nhentaiGateway.loadComicDetail(comicId);
      final thumbnailHosts = await _loadThumbnailHosts();
      final newCoverPath = await _downloadCover(
        comicId: comicId,
        comic: detail.comic,
        thumbnailHosts: thumbnailHosts,
      );
      if (newCoverPath == null) {
        debugPrint(
          '[repairCover] $comicId: no cover path on comic detail, or all '
          'thumbnail hosts failed to return bytes.',
        );
        return false;
      }
      await downloadedLibraryRepository.updateCoverLocalPath(comicId, newCoverPath);
      return true;
    } catch (error, stackTrace) {
      debugPrint('[repairCover] $comicId failed: $error\n$stackTrace');
      return false;
    }
  }

  /// Minimum delay after any network-hitting attempt in [repairAllCompleted]
  /// or [enqueueMany], to avoid bursting `loadComicDetail` calls.
  static const Duration _networkThrottleDelay = Duration(milliseconds: 1000);

  /// Stop scanning/enqueueing after this many consecutive failures in
  /// [repairAllCompleted] or [enqueueMany] — repeated failures in a row
  /// suggest a systemic problem (e.g. the network or API is down), and
  /// continuing to hammer it for the remaining items is more likely to make
  /// things worse than to succeed.
  static const int _maxConsecutiveNetworkFailures = 3;

  /// Scans every completed download, repairing missing pages and/or covers.
  ///
  /// Returns how many of the [totalCount] completed downloads needed a
  /// repair and how many failed. Runs sequentially. Stops early —
  /// [stoppedEarly] is true — after [_maxConsecutiveNetworkFailures]
  /// consecutive failures, leaving the remaining items unscanned. A
  /// throttling delay is inserted after any item that actually triggered a
  /// network request (repaired or failed), but not after items that were
  /// already intact (pure local check, no network involved).
  Future<({int repairedCount, int failedCount, int totalCount, bool stoppedEarly})>
  repairAllCompleted({void Function(int processed, int total)? onProgress}) async {
    final completedIds = _downloadItems
        .where((item) => item.isCompletedCard)
        .map((item) => item.comicId)
        .toList(growable: false);

    var repairedCount = 0;
    var failedCount = 0;
    var consecutiveFailures = 0;
    var processedCount = 0;
    for (final comicId in completedIds) {
      var hitNetwork = false;
      try {
        if (await repairCompleted(comicId)) {
          repairedCount += 1;
          hitNetwork = true;
        }
        consecutiveFailures = 0;
      } catch (_) {
        failedCount += 1;
        hitNetwork = true;
        consecutiveFailures += 1;
      }
      processedCount += 1;
      onProgress?.call(processedCount, completedIds.length);

      if (consecutiveFailures >= _maxConsecutiveNetworkFailures) {
        break;
      }
      if (hitNetwork && processedCount < completedIds.length) {
        await Future<void>.delayed(_networkThrottleDelay);
      }
    }
    return (
      repairedCount: repairedCount,
      failedCount: failedCount,
      totalCount: completedIds.length,
      stoppedEarly: consecutiveFailures >= _maxConsecutiveNetworkFailures,
    );
  }

  /// Returns the title stored in the downloaded library for [comicId], if any.
  String? _libraryTitle(String comicId) {
    for (final item in _downloadItems) {
      if (item.comicId == comicId) {
        return item.title;
      }
    }
    return null;
  }

  Future<String?> loadCoverLocalPath(String comicId) {
    return downloadedLibraryRepository.loadCoverLocalPath(comicId);
  }

  Future<void> _maybeAutoResume() async {
    final autoResumeEnabled =
        await downloadSettingsRepository.loadAutoResumeEnabled();
    if (!autoResumeEnabled) {
      await downloadQueueRepository.pauseInterruptedJobs();
      await refresh();
      return;
    }
    await downloadQueueRepository.requeueInterruptedJobs();
    await refresh();
    unawaited(_processQueue());
  }

  Future<void> _processQueue() async {
    if (_isProcessing) {
      return;
    }
    _isProcessing = true;
    try {
      while (true) {
        final nextJob = await downloadQueueRepository.loadNextQueuedJob();
        if (nextJob == null) {
          break;
        }
        await _processJob(nextJob);
      }
    } finally {
      _isProcessing = false;
      await refresh();
    }
  }

  Future<void> _processJob(DownloadJobSnapshot job) async {
    final detail = await nhentaiGateway.loadComicDetail(job.comicId);
    final comic = detail.comic;
    final imageHosts = await _loadImageHosts();
    final pageIntervalMs = await downloadSettingsRepository.loadPageIntervalMs();

    await downloadQueueRepository.markJobDownloading(job.comicId);
    await _syncState();

    final pages = await downloadQueueRepository.loadPages(job.comicId);
    for (final page in pages) {
      if (await _shouldStopJob(job.comicId)) {
        return;
      }
      if (page.status == DownloadPageStatus.completed) {
        continue;
      }

      await downloadQueueRepository.markPageDownloading(
        comicId: job.comicId,
        pageNumber: page.pageNumber,
      );
      await _syncState();

      try {
        final downloadedPage = await _downloadAndPersistPage(
          comicId: job.comicId,
          page: page,
          imageHosts: imageHosts,
        );
        await downloadQueueRepository.markPageCompleted(
          comicId: job.comicId,
          pageNumber: page.pageNumber,
          sourceServer: downloadedPage.sourceServer,
          localPath: downloadedPage.localPath,
          storedFormat: downloadedPage.storedFormat,
          byteSize: downloadedPage.byteSize,
        );
        await _syncState();
      } catch (error) {
        await downloadQueueRepository.markPageFailed(
          comicId: job.comicId,
          pageNumber: page.pageNumber,
          error: '$error',
        );
        await _syncState();
        return;
      }

      if (pageIntervalMs > 0) {
        await Future<void>.delayed(Duration(milliseconds: pageIntervalMs));
      }
    }

    // Skip re-downloading the cover if a valid local copy already exists
    // (e.g. when this job was re-queued only to repair missing pages) —
    // otherwise a failed re-fetch here would silently overwrite a cover
    // that a prior repair already fixed.
    final existingCoverPath = await downloadedLibraryRepository.loadCoverLocalPath(
      job.comicId,
    );
    final coverLocalPath = await downloadAssetStore.coverExists(existingCoverPath)
        ? existingCoverPath
        : await _downloadCover(
            comicId: job.comicId,
            comic: comic,
            thumbnailHosts: await _loadThumbnailHosts(),
          );
    await downloadedLibraryRepository.saveDownloadedComic(
      comic: comic,
      // Relative (just the comicId) rather than an absolute path — this
      // column is never read back as a filesystem path (see P51), so it
      // must not carry a container-bound absolute value either.
      rootDirectoryPath: job.comicId,
      coverLocalPath: coverLocalPath,
    );
    await downloadQueueRepository.markJobCompleted(job.comicId);
    await _syncState();
  }

  Future<bool> _shouldStopJob(String comicId) async {
    final job = await downloadQueueRepository.loadJob(comicId);
    if (job == null) {
      return true;
    }
    return job.status == DownloadJobStatus.paused ||
        job.status == DownloadJobStatus.failed;
  }

  Future<List<String>> _loadImageHosts() async {
    try {
      await cdnConfigService.load();
    } catch (_) {}
    return cdnConfigService.imageHosts;
  }

  /// Covers (and thumbnails) are served from a different CDN host pool than
  /// full-resolution page images — using [_loadImageHosts] for covers
  /// consistently fails (e.g. connection reset) since that path doesn't
  /// exist on the page-image hosts.
  Future<List<String>> _loadThumbnailHosts() async {
    try {
      await cdnConfigService.load();
    } catch (_) {}
    return cdnConfigService.thumbnailHosts;
  }

  Future<_PersistedAsset> _downloadAndPersistPage({
    required String comicId,
    required DownloadPageSnapshot page,
    required List<String> imageHosts,
  }) async {
    Object? lastError;
    for (final host in imageHosts) {
      final url = Uri.https(host, page.remotePath).toString();
      try {
        final originalBytes = await remoteAssetFetcher.fetchBytes(url);
        final compressed = await _compressWithFallback(
          originalBytes,
          fallbackExtension: _extensionFromPath(page.remotePath),
        );
        final localPath = await downloadAssetStore.savePage(
          comicId: comicId,
          pageNumber: page.pageNumber,
          bytes: compressed.bytes,
          extension: compressed.extension,
        );
        return _PersistedAsset(
          sourceServer: host,
          localPath: localPath,
          storedFormat: compressed.extension,
          byteSize: compressed.bytes.length,
        );
      } catch (error) {
        lastError = error;
      }
    }

    throw lastError ?? StateError('Failed to download page ${page.pageNumber}');
  }

  Future<String?> _downloadCover({
    required String comicId,
    required Comic comic,
    required List<String> thumbnailHosts,
  }) async {
    final coverPath = comic.images.cover?.path;
    if (coverPath == null || coverPath.isEmpty) {
      debugPrint('[downloadCover] $comicId: comic.images.cover.path is null/empty.');
      return null;
    }

    for (final host in thumbnailHosts) {
      final url = Uri.https(host, coverPath).toString();
      try {
        final originalBytes = await remoteAssetFetcher.fetchBytes(url);
        final compressed = await _compressWithFallback(
          originalBytes,
          fallbackExtension: _extensionFromPath(coverPath),
        );
        return downloadAssetStore.saveCover(
          comicId: comicId,
          bytes: compressed.bytes,
          extension: compressed.extension,
        );
      } catch (error) {
        debugPrint('[downloadCover] $comicId: $url failed: $error');
      }
    }

    return null;
  }

  Future<_CompressedAsset> _compressWithFallback(
    Uint8List originalBytes, {
    required String fallbackExtension,
  }) async {
    final normalizedExtension = fallbackExtension.toLowerCase();
    if (_skiaSafeExtensions.contains(normalizedExtension)) {
      return _CompressedAsset(bytes: originalBytes, extension: normalizedExtension);
    }

    try {
      final compressed = await imageCompressionService.compressToWebp(
        originalBytes,
        quality: 80,
      );
      if (compressed.isNotEmpty) {
        return _CompressedAsset(bytes: compressed, extension: 'webp');
      }
    } on UnsupportedError {
      // Keep original format below.
    } catch (_) {
      // Keep original format below.
    }

    return _CompressedAsset(bytes: originalBytes, extension: normalizedExtension);
  }

  String _extensionFromPath(String path) {
    final filename = p.basename(path);
    if (!filename.contains('.')) {
      return 'bin';
    }
    final segments = filename.split('.');
    if (segments.length >= 3 && segments.last == segments[segments.length - 2]) {
      return segments.last.toLowerCase();
    }
    return segments.last.toLowerCase();
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> waitForIdle() async {
    while (_isProcessing) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  Future<void> _runMutatingJobAction(
    String comicId,
    Future<void> Function() action,
  ) async {
    if (_mutatingComicIds.contains(comicId)) {
      return;
    }
    _mutatingComicIds.add(comicId);
    notifyListeners();
    try {
      await action();
    } finally {
      _mutatingComicIds.remove(comicId);
      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }
}

class _PersistedAsset {
  const _PersistedAsset({
    required this.sourceServer,
    required this.localPath,
    required this.storedFormat,
    required this.byteSize,
  });

  final String sourceServer;
  final String localPath;
  final String storedFormat;
  final int byteSize;
}

class _CompressedAsset {
  const _CompressedAsset({required this.bytes, required this.extension});

  final Uint8List bytes;
  final String extension;
}
