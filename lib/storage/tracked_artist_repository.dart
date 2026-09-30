import 'package:concept_nhv/application/tracking/tracking_cooldown.dart';
import 'package:concept_nhv/storage/local_database.dart';
import 'package:drift/drift.dart' as drift;

/// Reads and writes [TrackedArtists].
///
/// See .codex/phases/P97-artist-update-tracking.md.
class TrackedArtistRepository {
  const TrackedArtistRepository({required this.localDatabase});

  final LocalDatabase localDatabase;

  Future<List<TrackedArtist>> loadAll() {
    return localDatabase.select(localDatabase.trackedArtists).get();
  }

  Future<bool> isTracked(int tagId) async {
    final row =
        await (localDatabase.select(localDatabase.trackedArtists)
              ..where((table) => table.tagId.equals(tagId)))
            .getSingleOrNull();
    return row != null;
  }

  /// Starts tracking [tagId] from [lastSeenUploadDate].
  ///
  /// The caller passes the artist's current newest upload time, so the first
  /// check reports nothing. Passing null means "everything from here is new",
  /// which is only right when nothing is known about the artist yet.
  ///
  /// Re-tracking an artist keeps the existing row rather than resetting the
  /// watermark: un-tracking and re-tracking should not replay works the user
  /// has already been shown.
  Future<void> track(int tagId, {int? lastSeenUploadDate}) {
    return localDatabase
        .into(localDatabase.trackedArtists)
        .insert(
          TrackedArtistsCompanion.insert(
            tagId: drift.Value<int>(tagId),
            lastSeenUploadDate: drift.Value<int?>(lastSeenUploadDate),
          ),
          onConflict: drift.DoNothing(),
        );
  }

  Future<void> untrack(int tagId) {
    return (localDatabase.delete(
      localDatabase.trackedArtists,
    )..where((table) => table.tagId.equals(tagId))).go();
  }

  /// The artists a run should ask about: the ones checked longest ago, never
  /// more than [limit] of them.
  ///
  /// Nulls first, so an artist just added is asked about before one checked
  /// an hour ago.
  Future<List<TrackedArtist>> loadStalest({
    int limit = kTrackedArtistsPerRun,
  }) {
    return (localDatabase.select(localDatabase.trackedArtists)
          ..orderBy(<drift.OrderClauseGenerator<$TrackedArtistsTable>>[
            (table) => drift.OrderingTerm(
              expression: table.lastCheckedAt,
              mode: drift.OrderingMode.asc,
              nulls: drift.NullsOrder.first,
            ),
          ])
          ..limit(limit))
        .get();
  }

  /// Records what a check found.
  ///
  /// [newCount] is stored rather than added to: it is how many works sit
  /// beyond the watermark right now, and the watermark has not moved yet.
  Future<void> recordCheck({
    required int tagId,
    required DateTime checkedAt,
    required int newCount,
  }) {
    return (localDatabase.update(
      localDatabase.trackedArtists,
    )..where((table) => table.tagId.equals(tagId))).write(
      TrackedArtistsCompanion(
        lastCheckedAt: drift.Value<DateTime>(checkedAt),
        newCount: drift.Value<int>(newCount),
      ),
    );
  }

  /// Moves the watermark up and clears the count, once the user has seen what
  /// was found.
  ///
  /// The watermark becomes [seenAt] rather than a specific gallery's upload
  /// time, because the user is looking at that artist's results right now:
  /// everything uploaded before this moment has been put in front of them.
  ///
  /// The cost, which is the same one the count already carries: a search only
  /// reads its first page, so an artist who published more than a page's
  /// worth between two checks has the overflow marked seen along with the
  /// rest. Both numbers come from that one page, so neither is more right
  /// than the other.
  Future<void> markSeen({required int tagId, required DateTime seenAt}) {
    return (localDatabase.update(
      localDatabase.trackedArtists,
    )..where((table) => table.tagId.equals(tagId))).write(
      TrackedArtistsCompanion(
        lastSeenUploadDate: drift.Value<int>(
          seenAt.toUtc().millisecondsSinceEpoch ~/ 1000,
        ),
        newCount: const drift.Value<int>(0),
      ),
    );
  }

  /// Sets the watermark of an artist that has never had one.
  ///
  /// Tracking starts with no watermark on purpose — pressing "track" must not
  /// become a network request that can fail — so the first check is what
  /// establishes where "new" begins.
  Future<void> seedWatermark({required int tagId, required int uploadDate}) {
    return (localDatabase.update(localDatabase.trackedArtists)..where(
          (table) =>
              table.tagId.equals(tagId) & table.lastSeenUploadDate.isNull(),
        ))
        .write(
          TrackedArtistsCompanion(
            lastSeenUploadDate: drift.Value<int>(uploadDate),
          ),
        );
  }
}
