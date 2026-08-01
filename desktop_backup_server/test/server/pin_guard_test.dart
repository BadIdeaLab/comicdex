import 'package:desktop_backup_server/server/pin_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PinGuard', () {
    test('generates a 6-digit PIN', () {
      final guard = PinGuard();
      expect(guard.pin, matches(RegExp(r'^\d{6}$')));
    });

    test('accepts the correct PIN and rejects anything else', () {
      final guard = PinGuard();
      expect(
        guard.check(providedPin: guard.pin, address: '10.0.0.2'),
        PinCheckResult.ok,
      );
      expect(
        guard.check(providedPin: 'nope', address: '10.0.0.2'),
        PinCheckResult.rejected,
      );
      expect(
        guard.check(providedPin: null, address: '10.0.0.2'),
        PinCheckResult.rejected,
      );
    });

    test(
      'locks an address out after repeated failures, so a 6-digit PIN cannot '
      'simply be brute forced over the LAN',
      () {
        var now = DateTime(2026, 8, 2, 12);
        final guard = PinGuard(
          maxFailedAttempts: 3,
          lockoutDuration: const Duration(minutes: 5),
          clock: () => now,
        );

        expect(
          guard.check(providedPin: 'x', address: '10.0.0.9'),
          PinCheckResult.rejected,
        );
        expect(
          guard.check(providedPin: 'x', address: '10.0.0.9'),
          PinCheckResult.rejected,
        );
        expect(
          guard.check(providedPin: 'x', address: '10.0.0.9'),
          PinCheckResult.lockedOut,
        );

        // Even the correct PIN is refused while the lockout is active.
        expect(
          guard.check(providedPin: guard.pin, address: '10.0.0.9'),
          PinCheckResult.lockedOut,
        );
        expect(guard.lockedOutAddresses, contains('10.0.0.9'));

        // ...and works again once it expires.
        now = now.add(const Duration(minutes: 6));
        expect(
          guard.check(providedPin: guard.pin, address: '10.0.0.9'),
          PinCheckResult.ok,
        );
        expect(guard.lockedOutAddresses, isEmpty);
      },
    );

    test('lockout is per address', () {
      var now = DateTime(2026, 8, 2, 12);
      final guard = PinGuard(maxFailedAttempts: 2, clock: () => now);

      guard.check(providedPin: 'x', address: '10.0.0.1');
      expect(
        guard.check(providedPin: 'x', address: '10.0.0.1'),
        PinCheckResult.lockedOut,
      );
      expect(
        guard.check(providedPin: guard.pin, address: '10.0.0.2'),
        PinCheckResult.ok,
      );
    });

    test('a successful check clears that address\'s failure count', () {
      final guard = PinGuard(maxFailedAttempts: 3);
      guard.check(providedPin: 'x', address: '10.0.0.5');
      guard.check(providedPin: 'x', address: '10.0.0.5');
      guard.check(providedPin: guard.pin, address: '10.0.0.5');

      // Counter reset, so two more failures still do not lock out.
      expect(
        guard.check(providedPin: 'x', address: '10.0.0.5'),
        PinCheckResult.rejected,
      );
      expect(
        guard.check(providedPin: 'x', address: '10.0.0.5'),
        PinCheckResult.rejected,
      );
    });

    test('regenerate replaces the PIN and clears lockouts', () {
      final guard = PinGuard(maxFailedAttempts: 1);
      final original = guard.pin;
      guard.check(providedPin: 'x', address: '10.0.0.7');
      expect(guard.lockedOutAddresses, contains('10.0.0.7'));

      final replacement = guard.regenerate();
      expect(replacement, isNot(original));
      expect(guard.lockedOutAddresses, isEmpty);
    });
  });
}
