import 'package:concept_nhv/application/downloads/throttled_batch.dart';
import 'package:concept_nhv/application/search/blocked_tags_repository.dart';
import 'package:concept_nhv/application/tracking/tracking_cooldown.dart';
import 'package:concept_nhv/models/comic.dart';
import 'package:concept_nhv/services/local_tag_catalog_service.dart';
import 'package:concept_nhv/services/nhentai_api_client.dart';
import 'package:concept_nhv/services/request_retry.dart';
import 'package:concept_nhv/services/search_query_builder.dart';
import 'package:concept_nhv/storage/local_database.dart' show TrackedArtist;
import 'package:concept_nhv/storage/tracked_artist_repository.dart';
import 'package:concept_nhv/storage/tracking_state_store.dart';
import 'package:dio/dio.dart';

/// What one run did.
class TrackingCheckResult {
  const TrackingCheckResult({
    required this.checkedCount,
    required this.failedCount,
    required this.artistsWithNewWork,
    required this.skipped,
    required this.rateLimited,
  });

  /// The run never started, because the cooldown said so.
  const TrackingCheckResult.skipped()
    : checkedCount = 0,
      failedCount = 0,
      artistsWithNewWork = 0,
      skipped = true,
      rateLimited = false;

  final int checkedCount;
  final int failedCount;
  final int artistsWithNewWork;
  final bool skipped;

  /// The site asked us to slow down, so the run stopped where it was.
  final bool rateLimited;
}

/// Asks the site whether any tracked artist has published since last time.
///
/// Sends at most [kTrackedArtistsPerRun] requests per run, no more often than
/// [kTrackingRunInterval], and stops entirely when the site says to. See
/// .codex/phases/P97-artist-update-tracking.md.
class CheckTrackedArtistsUseCase {
  const CheckTrackedArtistsUseCase({
    required this.trackedArtistRepository,
    required this.trackingStateStore,
    required this.nhentaiGateway,
    required this.localTagCatalogService,
    required this.blockedTagsRepository,
    required this.searchQueryBuilder,
    this.now = DateTime.now,
    this.batchSleep,
  });

  final TrackedArtistRepository trackedArtistRepository;
  final TrackingStateStore trackingStateStore;
  final NhentaiGateway nhentaiGateway;
  final LocalTagCatalogService localTagCatalogService;
  final BlockedTagsRepository blockedTagsRepository;
  final SearchQueryBuilder searchQueryBuilder;

  /// Injected so the cooldown can be tested. Every rule here is about time,
  /// and none of them can be tested by actually waiting.
  final DateTime Function() now;

  /// Injected so tests do not sit through the between-request throttle.
  final Future<void> Function(Duration duration)? batchSleep;

  /// [manual] is a pull-to-refresh: it overrules our own pacing, but never a
  /// cooldown the site imposed.
  Future<TrackingCheckResult> execute({bool manual = false}) async {
    final cooldown = await trackingStateStore.load();
    if (!cooldown.canStartRun(now: now(), manual: manual)) {
      return const TrackingCheckResult.skipped();
    }

    final artists = await trackedArtistRepository.loadStalest();
    if (artists.isEmpty) {
      // Nothing to ask about is not a reason to make the next run wait.
      return const TrackingCheckResult.skipped();
    }

    final blocked = (await blockedTagsRepository.loadBlockedTags()).toSet();
    var withNewWork = 0;
    DioException? rateLimitError;

    final batch = await runThrottledBatch<TrackedArtist>(
      items: artists,
      sleep: batchSleep,
      // Checked before each item, so the one that was rate-limited is the
      // last request this run sends.
      shouldStop: () => rateLimitError != null,
      step: (artist) async {
        try {
          final newCount = await _checkOne(artist, blocked: blocked);
          if (newCount > 0) withNewWork += 1;
        } on DioException catch (error) {
          if (isRateLimited(error)) rateLimitError = error;
          rethrow;
        }
        return true;
      },
    );

    await trackingStateStore.save(
      rateLimitError != null
          ? TrackingCooldown.afterRateLimit(
              now(),
              retryAfter: retryAfterDelay(rateLimitError!.response),
            )
          : TrackingCooldown.afterRun(now()),
    );

    return TrackingCheckResult(
      checkedCount: batch.processedCount,
      failedCount: batch.failedCount,
      artistsWithNewWork: withNewWork,
      skipped: false,
      rateLimited: rateLimitError != null,
    );
  }

  /// One request, and the number of works it found beyond the watermark.
  Future<int> _checkOne(
    TrackedArtist artist, {
    required Set<String> blocked,
  }) async {
    final entry = localTagCatalogService.entryById(artist.tagId);
    if (entry == null) {
      // The catalog cannot name this id, so there is no query to send. Record
      // the attempt anyway: leaving `lastCheckedAt` null would put this
      // artist at the front of every future run, for ever.
      await trackedArtistRepository.recordCheck(
        tagId: artist.tagId,
        checkedAt: now(),
        newCount: artist.newCount,
      );
      return 0;
    }

    final response = await nhentaiGateway.searchComics(
      searchQueryBuilder.buildSearchUri(
        userQuery: entry.query,
        page: 1,
        blockedTagQueries: blocked.toList(growable: false),
      ),
    );

    final newCount = countNewerThan(
      response.result,
      watermark: artist.lastSeenUploadDate,
    );
    await trackedArtistRepository.recordCheck(
      tagId: artist.tagId,
      checkedAt: now(),
      newCount: newCount,
    );
    return newCount;
  }
}

/// How many of [comics] were uploaded after [watermark].
///
/// Deliberately does not assume the results are newest-first: it compares
/// every one rather than stopping at the first older entry. If the site's
/// default ordering is recency — which it appears to be, though this build
/// has not been able to reach the site to confirm it — the answer is the
/// same either way. If it is not, the worst case is that a new work is
/// noticed once it reaches the first page, and there is no case where
/// something is announced that is not new.
int countNewerThan(Iterable<Comic> comics, {required int? watermark}) {
  if (watermark == null) {
    // Nothing is known yet, so nothing can be called new — announcing the
    // artist's whole back catalogue is the one outcome that is certainly
    // wrong.
    return 0;
  }
  var count = 0;
  for (final comic in comics) {
    final uploadDate = comic.uploadDate;
    if (uploadDate != null && uploadDate > watermark) count += 1;
  }
  return count;
}

/// The newest upload time in [comics], for seeding a watermark.
int? newestUploadDate(Iterable<Comic> comics) {
  int? newest;
  for (final comic in comics) {
    final uploadDate = comic.uploadDate;
    if (uploadDate == null) continue;
    if (newest == null || uploadDate > newest) newest = uploadDate;
  }
  return newest;
}
