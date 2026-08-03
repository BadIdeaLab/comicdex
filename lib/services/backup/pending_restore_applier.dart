import 'dart:io';

import 'package:concept_nhv/services/backup/backup_restore_service.dart';
import 'package:path/path.dart' as p;

/// Outcome of the startup check, mostly so tests and logs can tell the cases
/// apart.
enum PendingRestoreOutcome { none, applied, failed }

/// Suffix of the intermediate file that sits beside the database while the swap
/// is in flight.
///
/// It exists so the operation can be split into two independently resumable
/// halves: consume the staged snapshot, then replace the database. Whichever
/// half is interrupted, the next launch finishes the job exactly once.
const String kRestoreHandoverSuffix = '.restoring';

/// Swaps in a database left behind by a completed restore.
///
/// **Must run before `LocalDatabase` opens its connection.** drift creates the
/// connection lazily but holds it for the process lifetime, and every
/// repository is built on it; replacing the file underneath a live connection
/// risks reading half of one database and half of another. Running first — at
/// the very top of `main()` — sidesteps that entirely, which is why the restore
/// flow ends by asking the user to relaunch rather than trying to hot-swap.
///
/// Deliberately tolerant: any failure leaves the existing database untouched
/// and reports [PendingRestoreOutcome.failed]. Refusing to launch would strand
/// the user with no way back into the app.
Future<PendingRestoreOutcome> applyPendingRestore({
  required Future<Directory> Function() supportDirectory,
  required Future<String> Function() databasePath,
}) async {
  try {
    final support = await supportDirectory();
    final pending = File(
      p.join(support.path, kPendingRestoreDirName, kPendingRestoreDbName),
    );
    final target = File(await databasePath());
    final handover = File('${target.path}$kRestoreHandoverSuffix');

    // Both halves are checked: a launch that finds only a handover file is
    // resuming a swap interrupted after the staged snapshot was consumed.
    if (!pending.existsSync() && !handover.existsSync()) {
      return PendingRestoreOutcome.none;
    }
    await target.parent.create(recursive: true);

    if (pending.existsSync()) {
      // Copy rather than rename: on Android the database lives beside the
      // support directory rather than inside it, so the two can be on different
      // volumes and rename would fail.
      await pending.copy(handover.path);
      // Consuming the pending file here — before the database is replaced — is
      // what makes this safe to interrupt. If it were deleted afterwards and
      // that delete failed, the next launch would apply the same snapshot a
      // second time and silently roll back everything the user did in between.
      await pending.delete();
    }

    if (!handover.existsSync()) {
      return PendingRestoreOutcome.none;
    }

    // sqlite side files describe the *old* database; leaving them next to a
    // freshly swapped-in file is how you get "database disk image is malformed".
    for (final suffix in const <String>['-wal', '-shm', '-journal']) {
      final sideFile = File('${target.path}$suffix');
      if (sideFile.existsSync()) {
        await sideFile.delete();
      }
    }
    if (target.existsSync()) {
      await target.delete();
    }
    // Same volume by construction, so this is an atomic rename.
    await handover.rename(target.path);
    return PendingRestoreOutcome.applied;
  } on FileSystemException {
    return PendingRestoreOutcome.failed;
  }
}
