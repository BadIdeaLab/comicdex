/// Minimum delay after any network-hitting attempt in a batch, to avoid
/// bursting `loadComicDetail` calls.
const Duration networkThrottleDelay = Duration(milliseconds: 1000);

/// Stop after this many consecutive failures — repeated failures in a row
/// suggest a systemic problem (e.g. the network or API is down), and
/// continuing to hammer it for the remaining items is more likely to make
/// things worse than to succeed.
const int maxConsecutiveNetworkFailures = 3;

/// How a batch ended.
class ThrottledBatchOutcome {
  const ThrottledBatchOutcome({
    required this.processedCount,
    required this.failedCount,
    required this.stoppedEarly,
  });

  /// Items actually attempted, which is fewer than the list when the batch
  /// stopped early.
  final int processedCount;
  final int failedCount;

  /// True when [maxConsecutiveNetworkFailures] was reached, leaving the rest
  /// of the list untouched.
  final bool stoppedEarly;
}

/// Runs [step] over [items] one at a time, throttled, giving up after too
/// many failures in a row.
///
/// Both of the app's batch operations — enqueueing a multi-select of
/// favourites, and scanning every completed download for repairs — ran this
/// same loop with their own copy of it. Two copies means the throttle can be
/// tuned in one and forgotten in the other, and the forgotten one is what
/// goes and hammers the site.
///
/// [step] returns whether the item hit the network: only then is the throttle
/// applied, since an item that was already intact cost nothing. Anything
/// [step] throws counts as a failure that did hit the network, and is
/// swallowed — a batch reports its failures rather than stopping on the
/// first one. Counting what succeeded is the caller's job, because only the
/// caller knows what its outcomes mean.
///
/// [shouldStop] is checked before each item, for a caller that can be
/// disposed mid-batch.
Future<ThrottledBatchOutcome> runThrottledBatch<T>({
  required List<T> items,
  required Future<bool> Function(T item) step,
  void Function(int processed, int total)? onProgress,
  bool Function()? shouldStop,
  Duration throttle = networkThrottleDelay,
  int maxConsecutiveFailures = maxConsecutiveNetworkFailures,
  Future<void> Function(Duration duration)? sleep,
}) async {
  final wait = sleep ?? (duration) => Future<void>.delayed(duration);
  final total = items.length;

  var failedCount = 0;
  var consecutiveFailures = 0;
  var processedCount = 0;

  for (final item in items) {
    if (shouldStop?.call() ?? false) break;

    var hitNetwork = false;
    try {
      hitNetwork = await step(item);
      consecutiveFailures = 0;
    } catch (_) {
      failedCount += 1;
      hitNetwork = true;
      consecutiveFailures += 1;
    }
    processedCount += 1;
    onProgress?.call(processedCount, total);

    if (consecutiveFailures >= maxConsecutiveFailures) break;
    if (hitNetwork && processedCount < total) {
      await wait(throttle);
    }
  }

  return ThrottledBatchOutcome(
    processedCount: processedCount,
    failedCount: failedCount,
    stoppedEarly: consecutiveFailures >= maxConsecutiveFailures,
  );
}
