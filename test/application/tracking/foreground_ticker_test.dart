import 'package:concept_nhv/application/tracking/foreground_ticker.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ForegroundTicker', () {
    late int ticks;
    late ForegroundTicker ticker;

    setUp(() => ticks = 0);

    /// Disposed inside the test body rather than in `tearDown`: the framework
    /// checks for pending timers before tear-downs run, so a ticker still
    /// ticking fails the test it belongs to with an unrelated message.
    ForegroundTicker build({
      Duration interval = const Duration(milliseconds: 20),
    }) {
      ticker = ForegroundTicker(
        onTick: () async => ticks += 1,
        interval: interval,
      );
      addTearDown(ticker.dispose);
      return ticker;
    }

    void sendLifecycle(AppLifecycleState state) {
      WidgetsBinding.instance.handleAppLifecycleStateChanged(state);
    }

    testWidgets('ticks while the app is in front', (tester) async {
      build().start();

      await tester.pump(const Duration(milliseconds: 70));

      expect(ticks, greaterThanOrEqualTo(3));
      ticker.dispose();
    });

    testWidgets('stops when the app goes away', (tester) async {
      // A timer still running in the background is background polling, which
      // this phase deliberately does not do — and which the platform would
      // kill on its own schedule, making the behaviour unpredictable.
      build().start();
      await tester.pump(const Duration(milliseconds: 30));
      final before = ticks;

      sendLifecycle(AppLifecycleState.paused);
      await tester.pump(const Duration(milliseconds: 100));

      expect(ticker.isTicking, isFalse);
      expect(ticks, before, reason: 'not one more tick while away');
    });

    testWidgets('resumes when the app comes back', (tester) async {
      build().start();
      sendLifecycle(AppLifecycleState.paused);
      await tester.pump(const Duration(milliseconds: 50));
      final whileAway = ticks;

      sendLifecycle(AppLifecycleState.resumed);
      await tester.pump(const Duration(milliseconds: 70));

      expect(ticks, greaterThan(whileAway));
      ticker.dispose();
    });

    testWidgets('starting twice does not double the rate', (tester) async {
      // Two timers would double the request rate while looking like one
      // ticker, and nothing downstream would report it.
      final started = build()..start();
      started.start();

      await tester.pump(const Duration(milliseconds: 70));

      expect(ticks, lessThanOrEqualTo(4));
      ticker.dispose();
    });

    testWidgets('a disposed ticker stops', (tester) async {
      build().start();
      await tester.pump(const Duration(milliseconds: 30));
      final before = ticks;

      ticker.dispose();
      await tester.pump(const Duration(milliseconds: 100));

      expect(ticks, before);
    });
  });
}
