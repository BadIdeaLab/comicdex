import 'dart:io';

import 'package:concept_nhv/services/backup/backup_restore_service.dart';
import 'package:sqlite3/sqlite3.dart';

/// Reads the file paths a downloaded snapshot references.
///
/// Opened read-only and closed immediately: this database is not the app's, and
/// must not gain `-wal`/`-shm` side files that would then travel with it into
/// the pending slot.
///
/// Only completed pages are considered. A page still queued or failed has no
/// file to restore, and asking the mirror for one would just produce a spurious
/// failure in the summary.
Future<List<String?>> readSnapshotFilePaths(File snapshot) async {
  final db = sqlite3.open(snapshot.path, mode: OpenMode.readOnly);
  try {
    final paths = <String?>[];
    for (final row in db.select(
      'SELECT cover_local_path FROM DownloadedComic',
    )) {
      paths.add(row['cover_local_path'] as String?);
    }
    for (final row in db.select(
      "SELECT local_path FROM DownloadJobPage WHERE status = 'completed'",
    )) {
      paths.add(row['local_path'] as String?);
    }
    return paths;
  } finally {
    db.close();
  }
}

/// Convenience for wiring into [BackupRestoreService].
RestoreDatabaseReader get sqliteSnapshotReader => readSnapshotFilePaths;
