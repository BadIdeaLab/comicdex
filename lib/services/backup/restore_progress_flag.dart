import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// A restore that started but never committed.
class InterruptedRestore {
  const InterruptedRestore({required this.sourceDeviceId, required this.startedAt});

  final String sourceDeviceId;
  final DateTime startedAt;
}

/// Records that a restore is mid-flight, so an interrupted one is noticed.
///
/// Once a restore begins deleting files the old database no longer matches what
/// is on disk: it still lists comics whose pages have been removed to make room
/// for the incoming ones. If the app is then killed, it boots that old database
/// and the Downloads tab fills with entries that will not open — which reads as
/// a broken app rather than an unfinished restore.
///
/// Deliberately a plain file, **not a row in the drift database**: the database
/// is the very thing a restore replaces, so a flag stored there would be wiped
/// or reverted by the operation it is supposed to survive. A file beside it also
/// keeps this testable without any plugin.
class RestoreProgressFlag {
  RestoreProgressFlag({required Future<Directory> Function() supportDirectory})
    : _supportDirectory = supportDirectory;

  static const String fileName = 'restore_in_progress.json';

  final Future<Directory> Function() _supportDirectory;

  Future<File> _file() async {
    final support = await _supportDirectory();
    return File(p.join(support.path, fileName));
  }

  Future<InterruptedRestore?> read() async {
    try {
      final file = await _file();
      if (!file.existsSync()) {
        return null;
      }
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, Object?>) {
        return null;
      }
      final source = decoded['sourceDeviceId'];
      final startedAt = DateTime.tryParse(decoded['startedAt'] as String? ?? '');
      if (source is! String || startedAt == null) {
        return null;
      }
      return InterruptedRestore(sourceDeviceId: source, startedAt: startedAt);
    } on FormatException {
      // A corrupt flag still means *something* was in progress, but nothing
      // useful can be said about it; treat it as absent rather than blocking
      // launch on unparseable state.
      return null;
    } on FileSystemException {
      return null;
    }
  }

  /// Written immediately before the first destructive step, never after.
  Future<void> markStarted(String sourceDeviceId) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode(<String, Object?>{
        'sourceDeviceId': sourceDeviceId,
        'startedAt': DateTime.now().toUtc().toIso8601String(),
      }),
      flush: true,
    );
  }

  Future<void> clear() async {
    try {
      final file = await _file();
      if (file.existsSync()) {
        await file.delete();
      }
    } on FileSystemException {
      // Worst case the user sees one spurious "unfinished restore" prompt and
      // dismisses it; that is better than failing the restore itself.
    }
  }
}
