import 'dart:io';

import 'package:concept_nhv/services/backup/backup_client.dart';
import 'package:concept_nhv/services/backup/backup_connection.dart';
import 'package:concept_nhv/services/backup/backup_models.dart';
import 'package:concept_nhv/services/backup/restore_models.dart';
import 'package:concept_nhv/services/backup/restore_path_resolver.dart';
import 'package:concept_nhv/services/backup/restore_progress_flag.dart';
import 'package:concept_nhv/services/download_asset_store.dart';
import 'package:path/path.dart' as p;

/// Reads the file paths a downloaded database snapshot references.
///
/// Injected so the orchestration can be tested without running sqlite.
typedef RestoreDatabaseReader = Future<List<String?>> Function(File snapshot);

/// Where a downloaded database waits until the app restarts.
const String kPendingRestoreDirName = 'pending_restore';
const String kPendingRestoreDbName = 'database.db';

/// Pulls a backup from the desktop mirror onto this device.
///
/// Three properties matter more than anything else here, and each is enforced
/// by ordering rather than by hoping the happy path holds:
///
/// 1. **Nothing local is touched until every check passes.** A restore that
///    wipes first and only then discovers it cannot proceed leaves the user
///    with neither their old library nor the new one.
/// 2. **The database is staged last.** It is the commit point: until it moves
///    into the pending slot, the app still boots the old database, so any
///    interruption is recoverable by simply running the restore again.
/// 3. **Every file write is atomic.** A truncated file left at a final path
///    whose size happens to match would be skipped forever by the resume logic.
class BackupRestoreService {
  BackupRestoreService({
    required this.client,
    required this.downloadAssetStore,
    required this.appSchemaVersion,
    required RestoreDatabaseReader databaseReader,
    required Future<Directory> Function() supportDirectory,
    RestoreProgressFlag? progressFlag,
  }) : _databaseReader = databaseReader,
       _supportDirectory = supportDirectory,
       progressFlag =
           progressFlag ??
           RestoreProgressFlag(supportDirectory: supportDirectory);

  final RestoreProgressFlag progressFlag;

  final BackupClient client;
  final DownloadAssetStore downloadAssetStore;
  final int appSchemaVersion;
  final RestoreDatabaseReader _databaseReader;
  final Future<Directory> Function() _supportDirectory;

  Future<Directory> pendingRestoreDirectory() async {
    final support = await _supportDirectory();
    return Directory(p.join(support.path, kPendingRestoreDirName));
  }

  Future<File> pendingDatabaseFile() async {
    return File(p.join((await pendingRestoreDirectory()).path, kPendingRestoreDbName));
  }

  /// Runs the whole restore.
  ///
  /// [sourceDeviceId] may be another phone's partition — that is the point of
  /// device-scoped backups, and how a replacement device gets its data.
  Future<RestoreResult> run({
    required BackupConnection connection,
    required String sourceDeviceId,
    void Function(RestoreProgress progress)? onProgress,
    BackupPauseToken? pauseToken,
  }) async {
    onProgress?.call(const RestoreProgress(stage: RestoreStage.checking));
    await client.checkHealth(connection);

    final inventory = await client.fetchInventoryOf(
      connection: connection,
      sourceDeviceId: sourceDeviceId,
    );
    if (inventory.isEmpty) {
      throw const RestoreBlockedException(RestoreBlockedReason.emptySource);
    }

    // Downloaded to a scratch location purely to be *read*. Moving it into the
    // pending slot — the step that makes it the app's next database — happens
    // only at the very end.
    final staging = await _stagingDatabaseFile();
    final int backupSchemaVersion;
    try {
      backupSchemaVersion = await client.downloadDatabase(
        connection: connection,
        sourceDeviceId: sourceDeviceId,
        target: staging,
      );
    } on BackupServerException catch (error) {
      // Only a 404 means "this device never uploaded one". Anything else is a
      // real server fault and must not be reported as a missing snapshot, which
      // would send the user looking at the wrong device.
      if (error.statusCode == HttpStatus.notFound) {
        throw const RestoreBlockedException(
          RestoreBlockedReason.noDatabaseSnapshot,
        );
      }
      rethrow;
    }

    if (backupSchemaVersion > appSchemaVersion) {
      // Checked here, before a single local byte has changed: drift can migrate
      // forward but never backward, so proceeding would corrupt the database —
      // and doing so after wiping would destroy the only other copy.
      await _deleteQuietly(staging);
      throw RestoreBlockedException(
        RestoreBlockedReason.backupIsNewer,
        backupSchemaVersion: backupSchemaVersion,
      );
    }

    onProgress?.call(const RestoreProgress(stage: RestoreStage.planning));
    final plan = await _buildPlan(
      staging: staging,
      inventory: inventory,
    );

    // --- Past this line local data changes. Everything above can abort freely.

    // Raised before the first deletion, so an interruption anywhere below is
    // detectable on the next launch. From here until the database is staged,
    // the on-disk library and the database the app would boot disagree.
    await progressFlag.markStarted(sourceDeviceId);

    onProgress?.call(const RestoreProgress(stage: RestoreStage.clearing));
    final deleted = await _deleteUnreferenced(plan.toDelete);

    var downloaded = 0;
    final failures = <String>[];
    final downloadsRoot = await downloadAssetStore.resolveDownloadsRoot();
    for (final relativePath in plan.toDownload) {
      if (pauseToken?.isPauseRequested ?? false) {
        break;
      }
      onProgress?.call(
        RestoreProgress(
          stage: RestoreStage.downloading,
          downloadedFiles: downloaded,
          totalFiles: plan.toDownload.length,
          currentPath: relativePath,
        ),
      );
      try {
        await client.downloadFile(
          connection: connection,
          sourceDeviceId: sourceDeviceId,
          relativePath: relativePath,
          target: File(p.join(downloadsRoot.path, relativePath)),
        );
        downloaded++;
      } catch (error) {
        failures.add('$relativePath: $error');
      }
    }

    final complete =
        failures.isEmpty &&
        downloaded == plan.toDownload.length &&
        !(pauseToken?.isPauseRequested ?? false);

    var staged = false;
    if (complete) {
      onProgress?.call(const RestoreProgress(stage: RestoreStage.applying));
      await _stageDatabase(staging);
      staged = true;
      // Cleared only here: the library and the staged database now agree again.
      // A paused or failed run deliberately leaves it set so the next launch
      // says so rather than presenting a half-restored library as normal.
      await progressFlag.clear();
    } else {
      // Not committing this run, so the downloaded snapshot is dead weight —
      // several MB that would otherwise sit there until the next restore
      // happens to overwrite it.
      await _deleteQuietly(staging);
    }

    onProgress?.call(
      RestoreProgress(
        stage: RestoreStage.done,
        downloadedFiles: downloaded,
        totalFiles: plan.toDownload.length,
      ),
    );

    return RestoreResult(
      downloadedCount: downloaded,
      deletedCount: deleted,
      keptCount: plan.keptCount,
      failedCount: failures.length,
      isPaused: pauseToken?.isPauseRequested ?? false,
      databaseStaged: staged,
      failures: failures,
    );
  }

  /// Works out what to fetch and what is no longer needed, without changing
  /// anything.
  Future<RestorePlan> _buildPlan({
    required File staging,
    required Map<String, int> inventory,
  }) async {
    final databasePaths = await _databaseReader(staging);
    final localFiles = await _localFileSizes();

    final toDownload = computeRestoreDownloadList(
      databasePaths: databasePaths,
      remoteInventory: inventory,
      localFiles: localFiles,
    );

    final wanted = <String>{};
    for (final raw in databasePaths) {
      final path = normaliseRestorePath(raw);
      if (path != null && inventory.containsKey(path)) {
        wanted.add(path);
      }
    }
    final toDelete = localFiles.keys
        .where((path) => !wanted.contains(path))
        .toList(growable: false);
    final kept = localFiles.keys.where(wanted.contains).length -
        toDownload.where(localFiles.containsKey).length;

    return RestorePlan(
      toDownload: toDownload,
      toDelete: toDelete,
      bytesToDownload: toDownload.fold<int>(
        0,
        (sum, path) => sum + (inventory[path] ?? 0),
      ),
      keptCount: kept < 0 ? 0 : kept,
    );
  }

  Future<Map<String, int>> _localFileSizes() async {
    final root = await downloadAssetStore.resolveDownloadsRoot();
    if (!root.existsSync()) {
      return <String, int>{};
    }
    final sizes = <String, int>{};
    await for (final entity in root.list(recursive: true)) {
      if (entity is! File) {
        continue;
      }
      // Leftovers from an interrupted transfer are never valid content.
      if (entity.path.endsWith('.part')) {
        await _deleteQuietly(entity);
        continue;
      }
      final relative = p
          .relative(entity.path, from: root.path)
          .replaceAll(r'\', '/');
      sizes[relative] = await entity.length();
    }
    return sizes;
  }

  Future<int> _deleteUnreferenced(List<String> relativePaths) async {
    if (relativePaths.isEmpty) {
      return 0;
    }
    final root = await downloadAssetStore.resolveDownloadsRoot();
    var deleted = 0;
    for (final relativePath in relativePaths) {
      final file = File(p.join(root.path, relativePath));
      if (file.existsSync()) {
        await _deleteQuietly(file);
        deleted++;
      }
    }
    return deleted;
  }

  /// The commit: moves the downloaded database into the slot the next launch
  /// reads before it opens any connection.
  Future<void> _stageDatabase(File staging) async {
    final pending = await pendingDatabaseFile();
    await pending.parent.create(recursive: true);
    if (pending.existsSync()) {
      await pending.delete();
    }
    await staging.rename(pending.path);
  }

  Future<File> _stagingDatabaseFile() async {
    final directory = await pendingRestoreDirectory();
    await directory.create(recursive: true);
    return File(p.join(directory.path, 'incoming.db'));
  }

  static Future<void> _deleteQuietly(FileSystemEntity entity) async {
    try {
      if (entity.existsSync()) {
        await entity.delete();
      }
    } on FileSystemException {
      // Best effort; a leftover file costs space, not correctness.
    }
  }
}
