import 'package:dio/dio.dart';

/// Shared 429 retry/backoff policy for any request hitting nhentai's API,
/// used by both `RemoteFavoriteGateway` (favorites sync) and
/// `DownloadManagerModel` (batch download enqueue) — see
/// .codex/phases/P57-favorites-multiselect-download-throttle.md.
const int rateLimitMaxRetries = 3;
const List<Duration> rateLimitBackoffs = <Duration>[
  Duration(seconds: 30),
  Duration(seconds: 60),
  Duration(seconds: 120),
];

/// Parses the `Retry-After` header (in seconds) from [response], adding a
/// 1-second safety margin. Returns null if the header is absent or invalid.
Duration? retryAfterDelay(Response<dynamic>? response) {
  final header = response?.headers.value('retry-after');
  if (header == null) return null;
  final seconds = int.tryParse(header.trim());
  if (seconds == null || seconds <= 0) return null;
  return Duration(seconds: seconds + 1);
}

/// Runs [request], retrying up to [rateLimitMaxRetries] times when it fails
/// with a 429 response. Waits for the `Retry-After` header when present,
/// otherwise falls back to [rateLimitBackoffs]. [onRateLimit] is invoked
/// with the wait duration before each retry.
Future<T> withRateLimitRetry<T>(
  Future<T> Function() request, {
  void Function(Duration retryIn)? onRateLimit,
}) async {
  for (var attempt = 0; attempt < rateLimitMaxRetries; attempt++) {
    try {
      return await request();
    } on DioException catch (e) {
      if (e.response?.statusCode == 429 && attempt + 1 < rateLimitMaxRetries) {
        final backoff = retryAfterDelay(e.response) ?? rateLimitBackoffs[attempt];
        onRateLimit?.call(backoff);
        await Future<void>.delayed(backoff);
        continue;
      }
      rethrow;
    }
  }
  throw StateError('unreachable');
}
