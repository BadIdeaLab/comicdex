// Ad-hoc integrity check for a desktop backup partition.
//
// Verifies the invariant the whole design rests on: every file the backed-up
// database says it has must actually exist in the mirror.
//
// Handles the legacy absolute paths that predate the P51 relative-path
// convention by taking everything after the last `/downloads/` segment — those
// rows point at an old app-container UUID, but the file itself still lives at
// the same place relative to the downloads root.
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

void main(List<String> args) {
  final partition = Directory(args.single);
  final downloads = Directory(p.join(partition.path, 'downloads'));
  final snapshots =
      Directory(p.join(partition.path, 'db'))
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.db'))
          .toList()
        ..sort((a, b) => b.path.compareTo(a.path));

  stdout.writeln('db snapshots: ${snapshots.length}');
  final db = sqlite3.open(snapshots.first.path, mode: OpenMode.readOnly);

  var checked = 0;
  var legacyAbsolute = 0;
  var missing = 0;
  final samples = <String>[];

  void check(String? stored) {
    if (stored == null || stored.isEmpty) return;
    checked++;
    var rel = stored;
    const marker = '/downloads/';
    final at = rel.lastIndexOf(marker);
    if (at >= 0) {
      rel = rel.substring(at + marker.length);
      legacyAbsolute++;
    }
    if (!File(p.join(downloads.path, rel)).existsSync()) {
      missing++;
      if (samples.length < 5) samples.add(stored);
    }
  }

  for (final row in db.select('SELECT cover_local_path FROM DownloadedComic')) {
    check(row['cover_local_path'] as String?);
  }
  for (final row in db.select(
    "SELECT local_path FROM DownloadJobPage WHERE status = 'completed'",
  )) {
    check(row['local_path'] as String?);
  }

  stdout.writeln('paths referenced by the database : $checked');
  stdout.writeln('  of which legacy absolute paths : $legacyAbsolute');
  stdout.writeln('MISSING from the mirror          : $missing');
  if (samples.isNotEmpty) stdout.writeln('examples: ${samples.join(', ')}');
  db.close();
}
