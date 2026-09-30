/// How long after a finished run the next one may start.
const Duration kTrackingRunInterval = Duration(hours: 6);

/// How many tracked artists one run may check, oldest-checked first.
///
/// With [kTrackingRunInterval], this is the whole traffic budget:
/// `perRun / interval` = fewer than two requests an hour, however many
/// artists are tracked. Changing either constant changes that rate, which is
/// why they live together.
const int kTrackedArtistsPerRun = 10;

/// Used when a rate-limited response carries no `Retry-After`.
///
/// Hours rather than the seconds `withRequestRetry` waits: that function is
/// for a request someone is waiting on, and retrying soon is right there.
/// Nobody is waiting on an update check, so being told to slow down is
/// answered by coming back much later.
const Duration kDefaultRateLimitCooldown = Duration(hours: 2);

/// When the next check run may start, and whether the user can overrule it.
///
/// The whole cooldown is this one value plus [canStartRun]. Splitting it
/// across the model, the gateway and the use case is what would make it
/// unmaintainable — not the number of rules, of which there are two.
class TrackingCooldown {
  const TrackingCooldown({
    required this.nextRunAt,
    this.imposedByServer = false,
  });

  /// Nothing has run yet, so nothing is held back.
  const TrackingCooldown.none() : nextRunAt = null, imposedByServer = false;

  /// After a run that completed normally.
  factory TrackingCooldown.afterRun(DateTime now) {
    return TrackingCooldown(nextRunAt: now.add(kTrackingRunInterval));
  }

  /// After the site asked us to slow down.
  factory TrackingCooldown.afterRateLimit(
    DateTime now, {
    Duration? retryAfter,
  }) {
    return TrackingCooldown(
      nextRunAt: now.add(retryAfter ?? kDefaultRateLimitCooldown),
      imposedByServer: true,
    );
  }

  /// Null before the first run of all.
  final DateTime? nextRunAt;

  /// Whether [nextRunAt] came from the site rather than from our own pacing.
  ///
  /// This is the only thing in the cooldown that needs any thought, so it has
  /// a name instead of living in an `if` at the call site: pulling to refresh
  /// may overrule our own pacing, because the user is there and asking. It
  /// may not overrule the site's, because the site did not ask us.
  final bool imposedByServer;

  bool canStartRun({required DateTime now, required bool manual}) {
    final until = nextRunAt;
    if (until == null) return true;
    if (!now.isBefore(until)) return true;
    return manual && !imposedByServer;
  }
}
