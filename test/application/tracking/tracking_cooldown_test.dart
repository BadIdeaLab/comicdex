import 'package:concept_nhv/application/tracking/tracking_cooldown.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 9, 30, 12);

  group('TrackingCooldown', () {
    test('nothing holds back the very first run', () {
      const cooldown = TrackingCooldown.none();

      expect(cooldown.canStartRun(now: now, manual: false), isTrue);
    });

    test('a finished run holds the next one back', () {
      final cooldown = TrackingCooldown.afterRun(now);

      expect(
        cooldown.canStartRun(
          now: now.add(kTrackingRunInterval - const Duration(minutes: 1)),
          manual: false,
        ),
        isFalse,
      );
      expect(
        cooldown.canStartRun(now: now.add(kTrackingRunInterval), manual: false),
        isTrue,
      );
    });

    test('pulling to refresh overrules our own pacing', () {
      // The user is there and asking, which is the one thing our own interval
      // is guessing about.
      final cooldown = TrackingCooldown.afterRun(now);

      expect(
        cooldown.canStartRun(
          now: now.add(const Duration(minutes: 1)),
          manual: true,
        ),
        isTrue,
      );
    });

    test('pulling to refresh does not overrule the site', () {
      // The site did not ask us, so there is nothing for the user to overrule
      // — this is the one case that must hold whatever they do.
      final cooldown = TrackingCooldown.afterRateLimit(now);

      expect(
        cooldown.canStartRun(
          now: now.add(const Duration(hours: 1)),
          manual: true,
        ),
        isFalse,
      );
      expect(
        cooldown.canStartRun(
          now: now.add(kDefaultRateLimitCooldown),
          manual: true,
        ),
        isTrue,
      );
    });

    test('a Retry-After is honoured over the default', () {
      final cooldown = TrackingCooldown.afterRateLimit(
        now,
        retryAfter: const Duration(minutes: 30),
      );

      expect(
        cooldown.canStartRun(
          now: now.add(const Duration(minutes: 29)),
          manual: true,
        ),
        isFalse,
      );
      expect(
        cooldown.canStartRun(
          now: now.add(const Duration(minutes: 31)),
          manual: true,
        ),
        isTrue,
      );
    });

    test('the budget is what bounds the request rate', () {
      // Stated as a test so that changing either constant without meaning to
      // change the rate fails here rather than on the site.
      final perHour = kTrackedArtistsPerRun / kTrackingRunInterval.inHours;

      expect(perHour, lessThan(2));
    });
  });
}
