import 'package:concept_nhv/services/backup/backup_client.dart';

/// The addresses to try, in order.
///
/// A pairing code carries every address the desktop has, because it cannot tell
/// which of its interfaces a given phone can reach — a VPN endpoint and a
/// Hyper-V switch look much like a real LAN card, while the mobile-hotspot
/// adapter is "virtual" yet is exactly where a phone connects. Trying them in
/// turn settles it by experiment instead of by guessing.
///
/// [typed] always goes first so an address the user typed or edited is never
/// silently overridden by one from a scanned code.
List<String> orderedConnectionCandidates({
  required String typed,
  required List<String> fromPairingCode,
}) {
  return <String>[
    typed,
    for (final address in fromPairingCode)
      if (address != typed) address,
  ];
}

/// Connects to the first address that answers.
///
/// The distinction that matters is **"unreachable" versus "answered"**:
///
/// * Unreachable — no route, no listener, timeout — means this address is the
///   wrong one, so the next candidate gets a turn.
/// * Answered and refused — a wrong PIN, a lockout, a rejected device name —
///   means the desktop *is* there. Trying the remaining addresses would only
///   reproduce the same refusal more slowly, and would bury the real reason
///   behind a generic "cannot reach" at the end.
///
/// Rethrows the last failure when nothing worked, so the caller can still say
/// something specific.
/// Reports which address is being tried, and how far through the list it is.
///
/// Worth surfacing because the slow path here is several TCP timeouts in a row:
/// without it the app simply appears to hang, and the user cannot tell a long
/// search from a crash.
typedef ConnectionAttemptProgress =
    void Function(String address, int attempt, int total);

Future<String> connectToFirstReachable({
  required List<String> candidates,
  required Future<void> Function(String address) attempt,
  ConnectionAttemptProgress? onAttempt,
}) async {
  Object? lastFailure;
  StackTrace? lastStackTrace;

  for (var index = 0; index < candidates.length; index++) {
    final candidate = candidates[index];
    onAttempt?.call(candidate, index + 1, candidates.length);
    try {
      await attempt(candidate);
      return candidate;
    } on BackupServerException {
      rethrow;
    } on BackupPairingRejectedException {
      rethrow;
    } on Object catch (error, stackTrace) {
      lastFailure = error;
      lastStackTrace = stackTrace;
    }
  }

  if (lastFailure != null) {
    Error.throwWithStackTrace(lastFailure, lastStackTrace!);
  }
  throw StateError('connectToFirstReachable was given no candidates');
}
