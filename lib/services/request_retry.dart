import 'package:dio/dio.dart';

/// Shared retry policy for requests to nhentai's API, used by the home feed,
/// `RemoteFavoriteGateway` (favorites sync) and `DownloadManagerModel` (batch
/// download enqueue). See .codex/phases/P89-transient-server-errors.md.
const int requestMaxAttempts = 3;

/// Backoff for 429: the server is telling us to slow down, and a quick retry
/// makes that worse. See
/// .codex/phases/P57-favorites-multiselect-download-throttle.md.
const List<Duration> rateLimitBackoffs = <Duration>[
  Duration(seconds: 30),
  Duration(seconds: 60),
  Duration(seconds: 120),
];

/// Backoff for a server that is momentarily unavailable — a gateway timeout
/// is not a punishment, just an upstream that was slow, so waiting half a
/// minute to try again helps nobody.
const List<Duration> transientBackoffs = <Duration>[
  Duration(seconds: 1),
  Duration(seconds: 3),
  Duration(seconds: 6),
];

bool isRateLimited(DioException error) => error.response?.statusCode == 429;

/// Whether [error] is worth trying again shortly.
///
/// Deliberately excludes [DioExceptionType.connectionError]: with no network
/// there is nothing to retry, and retrying would delay telling the user that
/// for ten seconds. Permanent answers (403, 404) are excluded for the same
/// reason — they will say the same thing next time.
bool isTransientFailure(DioException error) {
  final status = error.response?.statusCode;
  if (status != null) {
    return status == 502 || status == 503 || status == 504;
  }
  return switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => true,
    _ => false,
  };
}

/// Runs [request], retrying up to [requestMaxAttempts] times.
///
/// The two failures wait very differently: 429 backs off for minutes, a 5xx
/// or a timeout for seconds. [onRateLimit] is invoked with the wait before
/// each rate-limited retry, so a long pause can be shown rather than looking
/// like a hang; the short waits need no such warning.
/// [sleep] exists so tests can assert *how long* each failure waits without
/// actually waiting: the difference between a 1-second and a 30-second
/// backoff is the whole point of this function, and counting attempts would
/// not catch the two being swapped.
Future<T> withRequestRetry<T>(
  Future<T> Function() request, {
  void Function(Duration retryIn)? onRateLimit,
  Future<void> Function(Duration duration)? sleep,
}) async {
  final wait = sleep ?? (duration) => Future<void>.delayed(duration);
  for (var attempt = 0; attempt < requestMaxAttempts; attempt++) {
    try {
      return await request();
    } on DioException catch (error) {
      if (attempt + 1 >= requestMaxAttempts) rethrow;

      if (isRateLimited(error)) {
        final backoff =
            retryAfterDelay(error.response) ?? rateLimitBackoffs[attempt];
        onRateLimit?.call(backoff);
        await wait(backoff);
        continue;
      }

      if (isTransientFailure(error)) {
        await wait(transientBackoffs[attempt]);
        continue;
      }

      rethrow;
    }
  }
  throw StateError('unreachable');
}

/// Parses the `Retry-After` header (in seconds) from [response], adding a
/// 1-second safety margin. Returns null if the header is absent or invalid.
Duration? retryAfterDelay(Response<dynamic>? response) {
  final header = response?.headers.value('retry-after');
  if (header == null) return null;
  final seconds = int.tryParse(header.trim());
  if (seconds == null || seconds <= 0) return null;
  return Duration(seconds: seconds + 1);
}
