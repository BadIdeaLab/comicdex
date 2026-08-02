/// Why a restore was refused before it touched anything.
enum RestoreBlockedReason {
  /// The backup was made by a newer app version. drift migrations only run
  /// forward, so restoring it would corrupt the database.
  backupIsNewer,

  /// The chosen device has files but no database snapshot — the last backup
  /// never got as far as uploading one.
  noDatabaseSnapshot,

  /// The mirror holds nothing for that device.
  emptySource,
}

/// Raised by the preflight, always *before* any local data is modified.
class RestoreBlockedException implements Exception {
  const RestoreBlockedException(this.reason, {this.backupSchemaVersion});

  final RestoreBlockedReason reason;
  final int? backupSchemaVersion;

  @override
  String toString() => 'RestoreBlockedException($reason)';
}

/// What a restore is about to do, computed before anything is changed.
class RestorePlan {
  const RestorePlan({
    required this.toDownload,
    required this.toDelete,
    required this.bytesToDownload,
    required this.keptCount,
  });

  /// Mirror-relative paths to fetch.
  final List<String> toDownload;

  /// Local files the restored database does not reference.
  ///
  /// Removed *before* downloading rather than after: it frees their space for
  /// the incoming files, which is what makes a restore onto a nearly-full
  /// device viable at all.
  final List<String> toDelete;

  final int bytesToDownload;

  /// Already present locally at the right size — neither deleted nor re-fetched.
  /// A restore of the same backup onto the same phone is therefore almost a
  /// no-op rather than a full re-download.
  final int keptCount;

  bool get isEmpty => toDownload.isEmpty && toDelete.isEmpty;
}

enum RestoreStage { checking, planning, clearing, downloading, applying, done }

class RestoreProgress {
  const RestoreProgress({
    required this.stage,
    this.downloadedFiles = 0,
    this.totalFiles = 0,
    this.currentPath,
  });

  final RestoreStage stage;
  final int downloadedFiles;
  final int totalFiles;
  final String? currentPath;

  double? get fraction =>
      totalFiles == 0 ? null : (downloadedFiles / totalFiles).clamp(0.0, 1.0);
}

class RestoreResult {
  const RestoreResult({
    required this.downloadedCount,
    required this.deletedCount,
    required this.keptCount,
    required this.failedCount,
    required this.isPaused,
    required this.databaseStaged,
    this.failures = const <String>[],
  });

  final int downloadedCount;
  final int deletedCount;
  final int keptCount;
  final int failedCount;
  final bool isPaused;

  /// True only when every file arrived and the new database was moved into the
  /// pending slot — the single commit point of the whole operation.
  final bool databaseStaged;

  final List<String> failures;
}
