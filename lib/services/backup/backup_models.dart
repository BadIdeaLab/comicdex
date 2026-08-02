/// A file on this device that is a candidate for backup.
class LocalBackupFile {
  const LocalBackupFile({
    required this.relativePath,
    required this.absolutePath,
    required this.sizeBytes,
  });

  /// Relative to the downloads root, always `/`-separated so it compares
  /// directly against the server's inventory.
  final String relativePath;
  final String absolutePath;
  final int sizeBytes;
}

/// Which phase the sync is in, for the progress UI.
enum BackupSyncStage { connecting, snapshottingDatabase, comparing, uploading, done }

class BackupSyncProgress {
  const BackupSyncProgress({
    required this.stage,
    this.uploadedFiles = 0,
    this.totalFiles = 0,
    this.currentPath,
  });

  final BackupSyncStage stage;
  final int uploadedFiles;
  final int totalFiles;
  final String? currentPath;

  /// Real percentage, not a guess: the work list is computed up front, so
  /// unlike a single-archive upload the total is known before transferring.
  double? get fraction =>
      totalFiles == 0 ? null : (uploadedFiles / totalFiles).clamp(0.0, 1.0);
}

class BackupSyncResult {
  const BackupSyncResult({
    required this.uploadedCount,
    required this.skippedCount,
    required this.failedCount,
    required this.skippedInFlightCount,
    this.failures = const <String>[],
  });

  /// Files sent this run.
  final int uploadedCount;

  /// Already on the server with a matching size.
  final int skippedCount;

  final int failedCount;

  /// Belonged to downloads still in progress, so deliberately not sent.
  final int skippedInFlightCount;

  final List<String> failures;

  bool get hasFailures => failedCount > 0;
}
