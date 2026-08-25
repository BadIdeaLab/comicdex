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
    this.sessionLifetime = const Duration(hours: 1),
    DateTime Function()? clock,
  }) : _random = random ?? Random.secure(),
       _clock = clock ?? DateTime.now {
    _pin = _generatePin();
  }

  final Random _random;
  final int maxFailedAttempts;
  final Duration lockoutDuration;

  /// How long a paired device stays authenticated without re-pairing.
  final Duration sessionLifetime;
  final DateTime Function() _clock;

  late String _pin;
  final Map<String, _FailureRecord> _failures = <String, _FailureRecord>{};

  /// Issued tokens and when each stops being accepted.
  final Map<String, DateTime> _sessions = <String, DateTime>{};

  String get pin => _pin;

  /// Number of session tokens still valid. Exposed for tests and diagnostics.
  int get activeSessionCount {
    _pruneExpiredSessions(_clock());
    return _sessions.length;
  }

  bool _isSessionValid(String token, DateTime now) {
    _pruneExpiredSessions(now);
    return _sessions.containsKey(token);
  }

  void _pruneExpiredSessions(DateTime now) {
    _sessions.removeWhere((_, expiry) => !now.isBefore(expiry));
  }

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

  /// Replaces the PIN. **Deliberately leaves issued session tokens alone.**
  ///
  /// The PIN is rotated on a timer so a photographed QR stops working almost
  /// immediately. Devices that already paired must not be caught by that: a
  /// backup is dozens of HTTP requests over tens of minutes, and every one of
  /// them carries credentials, so invalidating them on rotation would guarantee
  /// a mid-transfer failure. Rotation is about *new* pairings only.
  String regenerate() {
    _pin = _generatePin();
    _failures.clear();
    return _pin;
  }

  /// Grants a device credentials that survive PIN rotation.
  ///
  /// In memory only, like the PIN: restarting the desktop app invalidates every
  /// pairing, which is the behaviour the phone side already assumes.
  String issueSessionToken() {
    final token = List<int>.generate(24, (_) => _random.nextInt(16))
        .map((digit) => digit.toRadixString(16))
        .join();
    _sessions[token] = _clock().add(sessionLifetime);
    return token;
  }

  PinCheckResult check({
    required String? providedPin,
    required String address,
    String? providedToken,
  }) {
    final now = _clock();
    final record = _failures[address];
    if (record != null && record.isLockedAt(now)) {
      return PinCheckResult.lockedOut;
    }

    // Checked before the PIN: a paired device sends a token on every request,
    // and the PIN it originally used may well have rotated away by now.
    if (providedToken != null && _isSessionValid(providedToken, now)) {
      _failures.remove(address);
      return PinCheckResult.ok;
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
