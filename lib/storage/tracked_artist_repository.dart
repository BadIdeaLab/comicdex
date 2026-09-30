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
  Future<void> markSeen({required int tagId, required int uploadDate}) {
    return (localDatabase.update(
      localDatabase.trackedArtists,
    )..where((table) => table.tagId.equals(tagId))).write(
      TrackedArtistsCompanion(
        lastSeenUploadDate: drift.Value<int>(uploadDate),
        newCount: const drift.Value<int>(0),
      ),
    );
  }
}
