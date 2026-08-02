import 'dart:io';

import 'package:concept_nhv/services/backup/backup_restore_service.dart';
import 'package:path/path.dart' as p;

/// Outcome of the startup check, mostly so tests and logs can tell the cases
/// apart.
enum PendingRestoreOutcome { none, applied, failed }

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
    if (!pending.existsSync()) {
      return PendingRestoreOutcome.none;
    }

    final target = File(await databasePath());
    await target.parent.create(recursive: true);

    // Copy-then-delete rather than rename: the pending file and the database
    // can sit on different volumes (Android puts the database beside the app's
    // support directory, not inside it), and rename fails across volumes.
    await pending.copy(target.path);
    await pending.delete();

    // sqlite side files describe the *old* database; leaving them next to a
    // freshly swapped-in file is how you get "database disk image is malformed".
    for (final suffix in const <String>['-wal', '-shm', '-journal']) {
      final sideFile = File('${target.path}$suffix');
      if (sideFile.existsSync()) {
        await sideFile.delete();
      }
    }
    return PendingRestoreOutcome.applied;
  } on FileSystemException {
    return PendingRestoreOutcome.failed;
  }
}
