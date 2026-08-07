import 'dart:io';

import 'package:concept_nhv/models/download_job_status.dart';
import 'package:concept_nhv/services/backup/backup_client.dart';
import 'package:concept_nhv/services/backup/backup_connection.dart';
import 'package:concept_nhv/services/backup/backup_diff.dart';
import 'package:concept_nhv/services/backup/backup_models.dart';
import 'package:concept_nhv/services/download_asset_store.dart';
import 'package:concept_nhv/storage/download_queue_repository.dart';
import 'package:concept_nhv/storage/local_database.dart';
import 'package:path/path.dart' as p;

/// Produces a consistent copy of the live database.
///
/// Split out so tests can supply a plain file instead of running sqlite.
typedef DatabaseSnapshotBuilder = Future<File> Function();

/// Pushes this device's database and downloaded files to the desktop server.
class BackupSyncService {
  BackupSyncService({
    required this.client,
    required this.downloadAssetStore,
    required this.downloadQueueRepository,
    required this.schemaVersion,
    required DatabaseSnapshotBuilder snapshotBuilder,
  }) : _snapshotBuilder = snapshotBuilder;

  final BackupClient client;
  final DownloadAssetStore downloadAssetStore;
  final DownloadQueueRepository downloadQueueRepository;
  final int schemaVersion;
  final DatabaseSnapshotBuilder _snapshotBuilder;

  /// Runs a full incremental backup.
  ///
  /// **Order matters and must not be swapped.** The database snapshot is taken
  /// and uploaded *before* the files are scanned and sent. Doing it the other
  /// way round means a page that finishes downloading mid-sync can end up
  /// recorded as complete in the snapshot while its file was never uploaded —
  /// a backup that claims to hold a comic it cannot restore. In this order the
  /// worst case is an uploaded file the snapshot does not mention yet, which is
  /// harmless and picked up by the next backup.
  ///
  /// [snapshotPolicy] lets a paused backup resume without minting another
  /// database snapshot — see [DatabaseSnapshotPolicy]. Skipping is safe only
  /// because the earlier snapshot in the *same* logical backup already uploaded:
  /// files sent after it are, at worst, orphans the snapshot does not mention,
  /// which is the same harmless case the ordering rule above already permits.
  Future<BackupSyncResult> run({
    required BackupConnection connection,
    void Function(BackupSyncProgress progress)? onProgress,
    BackupPauseToken? pauseToken,
    DatabaseSnapshotPolicy snapshotPolicy = DatabaseSnapshotPolicy.capture,
  }) async {
    onProgress?.call(
      const BackupSyncProgress(stage: BackupSyncStage.connecting),
    );
    // Fail before any long work if the PIN or address is wrong.
    await client.checkHealth(connection);

    var databaseSnapshotUploaded = false;
    if (snapshotPolicy == DatabaseSnapshotPolicy.capture) {
      onProgress?.call(
        const BackupSyncProgress(stage: BackupSyncStage.snapshottingDatabase),
      );
      final snapshot = await _snapshotBuilder();
      try {
        await client.uploadDatabase(
          connection: connection,
          snapshot: snapshot,
          schemaVersion: schemaVersion,
        );
        // Set only after the upload returns: a throw here must leave this false
        // so the caller cannot establish a resume checkpoint.
        databaseSnapshotUploaded = true;
      } finally {
        await _deleteQuietly(snapshot);
      }
    }

    onProgress?.call(
      const BackupSyncProgress(stage: BackupSyncStage.comparing),
    );
    final inFlightComicIds = await _inFlightComicIds();
    final localFiles = await collectLocalFiles(
      excludedComicIds: inFlightComicIds,
    );
    final remoteInventory = await client.fetchInventory(connection);
    final pending = computeUploadList(
      localFiles: localFiles,
      remoteInventory: remoteInventory,
    );

    var uploaded = 0;
    final failures = <String>[];
    for (final file in pending) {
      if (pauseToken?.isPauseRequested ?? false) {
        break;
      }
      onProgress?.call(
        BackupSyncProgress(
          stage: BackupSyncStage.uploading,
          uploadedFiles: uploaded,
          totalFiles: pending.length,
          currentPath: file.relativePath,
        ),
      );
      try {
        await client.uploadFile(
          connection: connection,
          relativePath: file.relativePath,
          file: File(file.absolutePath),
        );
        uploaded++;
      } catch (error) {
        // One bad file must not abandon the rest. Resume is inherent — the next
        // run simply retries whatever is still missing.
        failures.add('${file.relativePath}: $error');
      }
    }

    onProgress?.call(
      BackupSyncProgress(
        stage: BackupSyncStage.done,
        uploadedFiles: uploaded,
        totalFiles: pending.length,
      ),
    );

    return BackupSyncResult(
      uploadedCount: uploaded,
      skippedCount: localFiles.length - pending.length,
      failedCount: failures.length,
      skippedInFlightCount: inFlightComicIds.length,
      failures: failures,
      isPaused: pauseToken?.isPauseRequested ?? false,
      databaseSnapshotUploaded: databaseSnapshotUploaded,
    );
  }

  /// Comics whose download has not finished.
  ///
  /// Their page files may be mid-write, and reading one then would hash and
  /// upload a truncated image that the server has no way to reject — our digest
  /// would match the truncated bytes we sent. Skipping them costs nothing: the
  /// next backup picks them up once complete.
  Future<Set<String>> _inFlightComicIds() async {
    final jobs = await downloadQueueRepository.loadJobs();
    return jobs
        .where((job) => job.status != DownloadJobStatus.completed)
        .map((job) => job.comicId)
        .toSet();
  }

  /// Walks the downloads tree, skipping anything belonging to
  /// [excludedComicIds].
  Future<List<LocalBackupFile>> collectLocalFiles({
    Set<String> excludedComicIds = const <String>{},
  }) async {
    final root = await downloadAssetStore.resolveDownloadsRoot();
    if (!root.existsSync()) {
      return const <LocalBackupFile>[];
    }
    final files = <LocalBackupFile>[];
    await for (final entity in root.list(recursive: true)) {
      if (entity is! File) {
        continue;
      }
      // Half-written files an interrupted restore left behind. Uploading one
      // would put a truncated image in the mirror that nothing references and
      // that prune can never remove — the phone genuinely still has it, so it
      // never looks stale. Skipped rather than deleted: a backup should only
      // ever read. The next restore's planning pass sweeps them.
      if (entity.path.endsWith('.part')) {
        continue;
      }
      final relative = p
          .relative(entity.path, from: root.path)
          .replaceAll(r'\', '/');
      final comicId = relative.split('/').first;
      if (excludedComicIds.contains(comicId)) {
        continue;
      }
      files.add(
        LocalBackupFile(
          relativePath: relative,
          absolutePath: entity.path,
          sizeBytes: await entity.length(),
        ),
      );
    }
    files.sort((a, b) => a.relativePath.compareTo(b.relativePath));
    return files;
  }

  static Future<void> _deleteQuietly(File file) async {
    try {
      if (file.existsSync()) {
        await file.delete();
      }
    } on FileSystemException {
      // A leftover temp snapshot is harmless; it is overwritten next run.
    }
  }
}

/// Builds a consistent database snapshot with `VACUUM INTO`.
///
/// Copying `database.db` directly is not safe while the app is using it: with
/// WAL journalling the newest committed data lives in a side file, so a raw
/// copy can be stale or torn. `VACUUM INTO` asks sqlite itself for a clean,
/// self-contained copy and works the same whichever journal mode is active, so
/// it is correct without having to detect the mode.
DatabaseSnapshotBuilder vacuumSnapshotBuilder({
  required LocalDatabase database,
  required Future<Directory> Function() temporaryDirectory,
}) {
  return () async {
    final directory = await temporaryDirectory();
    final target = File(p.join(directory.path, 'backup-snapshot.db'));
    // VACUUM INTO refuses to overwrite an existing file.
    if (target.existsSync()) {
      await target.delete();
    }
    final escaped = target.path.replaceAll("'", "''");
    await database.customStatement("VACUUM INTO '$escaped'");
    return target;
  };
}
