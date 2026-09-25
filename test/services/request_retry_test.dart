import 'package:concept_nhv/services/request_retry.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _status(int code, {Map<String, List<String>>? headers}) {
  final requestOptions = RequestOptions(path: '/');
  return DioException(
    requestOptions: requestOptions,
    response: Response<dynamic>(
      requestOptions: requestOptions,
      statusCode: code,
      headers: headers == null ? null : Headers.fromMap(headers),
    ),
    type: DioExceptionType.badResponse,
  );
}

DioException _type(DioExceptionType type) {
  return DioException(requestOptions: RequestOptions(path: '/'), type: type);
}

void main() {
  group('withRequestRetry', () {
    late List<Duration> waited;

    setUp(() => waited = <Duration>[]);

    Future<T> run<T>(Future<T> Function() request) {
      return withRequestRetry<T>(
        request,
        sleep: (duration) async => waited.add(duration),
      );
    }

    test('returns what the successful retry produced', () async {
      // Not merely "it retried": the caller has to receive the second
      // attempt's answer.
      var attempts = 0;
      final value = await run<String>(() async {
        attempts++;
        if (attempts == 1) throw _status(504);
        return 'ok';
      });

      expect(value, 'ok');
      expect(attempts, 2);
    });

    test('waits seconds for a gateway timeout, not minutes', () async {
      // The whole point of the change: counting retries would not notice the
      // two backoff tables being swapped.
      await expectLater(
        run<String>(() async => throw _status(504)),
        throwsA(isA<DioException>()),
      );

      expect(waited, <Duration>[
        const Duration(seconds: 1),
        const Duration(seconds: 3),
      ]);
    });

    test('waits minutes when rate limited', () async {
      await expectLater(
        run<String>(() async => throw _status(429)),
        throwsA(isA<DioException>()),
      );

      expect(waited, <Duration>[
        const Duration(seconds: 30),
        const Duration(seconds: 60),
      ]);
    });

    test('prefers the Retry-After header over the backoff table', () async {
      await expectLater(
        run<String>(
          () async => throw _status(
            429,
            headers: <String, List<String>>{
              'retry-after': <String>['5'],
            },
          ),
        ),
        throwsA(isA<DioException>()),
      );

      expect(waited.first, const Duration(seconds: 6));
    });

    test('announces only the long waits', () async {
      final announced = <Duration>[];
      await expectLater(
        withRequestRetry<String>(
          () async => throw _status(504),
          onRateLimit: announced.add,
          sleep: (_) async {},
        ),
        throwsA(isA<DioException>()),
      );

      // A one-second pause needs no warning; a two-minute one does.
      expect(announced, isEmpty);
    });

    test('gives up after three attempts', () async {
      var attempts = 0;
      await expectLater(
        run<String>(() async {
          attempts++;
          throw _status(504);
        }),
        throwsA(isA<DioException>()),
      );

      expect(attempts, requestMaxAttempts);
    });

    test('does not retry an answer that will not change', () async {
      for (final code in <int>[403, 404]) {
        var attempts = 0;
        await expectLater(
          run<String>(() async {
            attempts++;
            throw _status(code);
          }),
          throwsA(isA<DioException>()),
        );
        expect(attempts, 1, reason: '$code says the same thing next time');
      }
    });

    test('does not retry when there is no network', () async {
      // Nothing to retry, and retrying would delay saying so.
      var attempts = 0;
      await expectLater(
        run<String>(() async {
          attempts++;
          throw _type(DioExceptionType.connectionError);
        }),
        throwsA(isA<DioException>()),
      );

      expect(attempts, 1);
      expect(waited, isEmpty);
    });
  });

  group('failure classification', () {
    test('treats gateway failures as transient', () {
      for (final code in <int>[502, 503, 504]) {
        expect(isTransientFailure(_status(code)), isTrue, reason: '$code');
      }
    });

    test('treats timeouts as transient', () {
      for (final type in <DioExceptionType>[
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        expect(isTransientFailure(_type(type)), isTrue, reason: '$type');
      }
    });

    test('keeps rate limiting separate from a struggling server', () {
      expect(isRateLimited(_status(429)), isTrue);
      expect(isTransientFailure(_status(429)), isFalse);
      expect(isRateLimited(_status(504)), isFalse);
    });

    test('does not treat a permanent answer as transient', () {
      for (final code in <int>[400, 403, 404, 410]) {
        expect(isTransientFailure(_status(code)), isFalse, reason: '$code');
      }
    });
  });

  group('retryAfterDelay', () {
    test('adds a safety margin to the header', () {
      final delay = retryAfterDelay(
        _status(
          429,
          headers: <String, List<String>>{
            'retry-after': <String>['20'],
          },
        ).response,
      );
      expect(delay, const Duration(seconds: 21));
    });

    test('ignores an absent or unusable header', () {
      expect(retryAfterDelay(_status(429).response), isNull);
      expect(
        retryAfterDelay(
          _status(
            429,
            headers: <String, List<String>>{
              'retry-after': <String>['soon'],
            },
          ).response,
        ),
        isNull,
      );
    });
  });
}
