import 'dart:math';

/// Outcome of checking a request's `X-Backup-Pin` header.
enum PinCheckResult {
  ok,

  /// Wrong or missing PIN — the caller answers `401`.
  rejected,

  /// Too many recent failures from this address — the caller answers `429`.
  lockedOut,
}

/// Guards the pairing PIN and throttles guessing.
///
/// A 6-digit PIN is only a million combinations; over a LAN an unthrottled
/// attacker exhausts that in seconds, which would make the PIN decorative. The
/// lockout below is what actually gives it meaning.
///
/// The PIN lives in memory only and is regenerated on every launch — restarting
/// the desktop app deliberately invalidates old pairings.
class PinGuard {
  PinGuard({
    Random? random,
    this.maxFailedAttempts = 5,
    this.lockoutDuration = const Duration(minutes: 5),
    DateTime Function()? clock,
  }) : _random = random ?? Random.secure(),
       _clock = clock ?? DateTime.now {
    _pin = _generatePin();
  }

  final Random _random;
  final int maxFailedAttempts;
  final Duration lockoutDuration;
  final DateTime Function() _clock;

  late String _pin;
  final Map<String, _FailureRecord> _failures = <String, _FailureRecord>{};

  String get pin => _pin;

  /// Addresses currently locked out, for the desktop UI to surface. Seeing this
  /// tells the user either that they mistyped, or that something on the network
  /// is probing them.
  List<String> get lockedOutAddresses {
    final now = _clock();
    return _failures.entries
        .where((entry) => entry.value.isLockedAt(now))
        .map((entry) => entry.key)
        .toList(growable: false);
  }

  String regenerate() {
    _pin = _generatePin();
    _failures.clear();
    return _pin;
  }

  PinCheckResult check({required String? providedPin, required String address}) {
    final now = _clock();
    final record = _failures[address];
    if (record != null && record.isLockedAt(now)) {
      return PinCheckResult.lockedOut;
    }

    if (providedPin != null && providedPin == _pin) {
      _failures.remove(address);
      return PinCheckResult.ok;
    }

    final updated = (record ?? _FailureRecord()) ..registerFailure();
    if (updated.count >= maxFailedAttempts) {
      updated.lockedUntil = now.add(lockoutDuration);
      updated.count = 0;
      _failures[address] = updated;
      return PinCheckResult.lockedOut;
    }
    _failures[address] = updated;
    return PinCheckResult.rejected;
  }

  String _generatePin() {
    return List<int>.generate(6, (_) => _random.nextInt(10)).join();
  }
}

class _FailureRecord {
  int count = 0;
  DateTime? lockedUntil;

  bool isLockedAt(DateTime now) {
    final until = lockedUntil;
    return until != null && now.isBefore(until);
  }

  void registerFailure() {
    count++;
  }
}
