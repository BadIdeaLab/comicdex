import 'package:concept_nhv/application/downloads/throttled_batch.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('runThrottledBatch', () {
    late List<Duration> waits;

    Future<void> recordWait(Duration duration) async => waits.add(duration);

    setUp(() => waits = <Duration>[]);

    test('throttles only after an item that hit the network', () async {
      // An already-intact comic is a pure local check. Waiting a second for
      // it would make a repair scan of a healthy library take minutes.
      final outcome = await runThrottledBatch<bool>(
        items: <bool>[true, false, true],
        step: (hitNetwork) async => hitNetwork,
        sleep: recordWait,
      );

      expect(waits, <Duration>[networkThrottleDelay]);
      expect(outcome.processedCount, 3);
      expect(outcome.failedCount, 0);
      expect(outcome.stoppedEarly, isFalse);
    });

    test('never throttles after the last item', () async {
      // Nothing follows it, so the wait is pure delay in front of the user.
      await runThrottledBatch<int>(
        items: <int>[1],
        step: (_) async => true,
        sleep: recordWait,
      );

      expect(waits, isEmpty);
    });

    test('stops after enough consecutive failures', () async {
      final attempted = <int>[];

      final outcome = await runThrottledBatch<int>(
        items: <int>[1, 2, 3, 4, 5],
        step: (item) async {
          attempted.add(item);
          throw StateError('down');
        },
        sleep: recordWait,
      );

      expect(attempted, <int>[1, 2, 3]);
      expect(outcome.failedCount, 3);
      expect(outcome.processedCount, 3);
      expect(outcome.stoppedEarly, isTrue);
    });

    test('a success resets the run of failures', () async {
      // Otherwise a library with scattered bad comics would stop on the
      // third one however far apart they were.
      final outcome = await runThrottledBatch<bool>(
        items: <bool>[false, false, true, false, false],
        step: (succeeds) async {
          if (!succeeds) throw StateError('down');
          return true;
        },
        sleep: recordWait,
      );

      expect(outcome.processedCount, 5);
      expect(outcome.failedCount, 4);
      expect(outcome.stoppedEarly, isFalse);
    });

    test('reports progress once per attempted item', () async {
      final progress = <(int, int)>[];

      await runThrottledBatch<int>(
        items: <int>[1, 2],
        step: (_) async => false,
        onProgress: (processed, total) => progress.add((processed, total)),
        sleep: recordWait,
      );

      expect(progress, <(int, int)>[(1, 2), (2, 2)]);
    });

    test('shouldStop is checked before each item, not after', () async {
      final attempted = <int>[];
      var stop = false;

      final outcome = await runThrottledBatch<int>(
        items: <int>[1, 2, 3],
        step: (item) async {
          attempted.add(item);
          stop = true;
          return false;
        },
        shouldStop: () => stop,
        sleep: recordWait,
      );

      expect(attempted, <int>[1]);
      expect(
        outcome.stoppedEarly,
        isFalse,
        reason: 'a disposed caller is not a failing server',
      );
    });

    test('an empty list does nothing and reports nothing', () async {
      final outcome = await runThrottledBatch<int>(
        items: const <int>[],
        step: (_) async => true,
        sleep: recordWait,
      );

      expect(outcome.processedCount, 0);
      expect(outcome.stoppedEarly, isFalse);
      expect(waits, isEmpty);
    });
  });
}
