import 'dart:convert';
import 'dart:io';

import 'package:convert/convert.dart' show AccumulatorSink;
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../models/backup_models.dart';
import 'backup_exceptions.dart';

/// Suffix used while a transfer is still in flight.
///
/// Nothing ever lands on its final path until its digest has been verified, so
/// an interrupted transfer can never leave a truncated file that a later
/// inventory would report as "already have this". That guarantee is what makes
/// resume safe across app restarts and reboots.
const String kPartSuffix = '.part';

const String _downloadsDirName = 'downloads';
const String _dbDirName = 'db';
const String _manifestFileName = 'manifest.json';

/// Characters allowed in a device id, which becomes a directory name.
///
/// Commas are permitted because iOS reports its model as `iPad13,16` — a device
/// name auto-filled from that is entirely legitimate, and rejecting it produced
/// a `400` on the WebSocket upgrade that surfaced to the user as "cannot reach
/// this computer". Commas are legal in filenames on every platform this runs on.
/// Path separators, `..` and the rest stay excluded.
final RegExp _deviceIdPattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9 ._,()-]{0,63}$');
final RegExp _snapshotPattern =
    RegExp(r'^database-(\d{8})-(\d{9})-v(\d+)\.db$');

/// Owns everything on disk: device partitions, the file mirror, database
/// snapshots, and the per-device manifest.
///
/// Deliberately free of Flutter plugin dependencies (no `path_provider`, no
/// `shared_preferences`) so the whole storage layer — and the server on top of
/// it — can be exercised in plain tests against a temp directory.
class BackupLibrary {
  BackupLibrary({required this.root, this.maxDbSnapshots = 10});

  final Directory root;

  /// Snapshots are a few MB each, so keeping several generations is cheap and
  /// lets the user roll back metadata after noticing an accidental deletion.
  final int maxDbSnapshots;

  // ---------------------------------------------------------------------
  // Root availability
  // ---------------------------------------------------------------------

  bool get rootExists => root.existsSync();

  /// Throws if the configured root has gone missing. Every operation calls this
  /// first — see [BackupRootUnavailableException] for why this must never
  /// silently recreate the directory.
  void ensureRootAvailable() {
    if (!rootExists) {
      throw BackupRootUnavailableException(
        'Backup folder not found: ${root.path}',
      );
    }
  }

  /// Creates the root if it does not exist yet. Only called from the UI when the
  /// user explicitly picks a folder — never as an automatic fallback.
  Future<void> createRoot() => root.create(recursive: true);

  // ---------------------------------------------------------------------
  // Validation and path resolution
  // ---------------------------------------------------------------------

  /// Device ids become directory names, so they are validated before ever
  /// touching the filesystem.
  static String validateDeviceId(String? deviceId) {
    final value = deviceId?.trim() ?? '';
    if (value.isEmpty) {
      throw const InvalidBackupPathException('Missing device id');
    }
    if (value == '.' || value == '..' || !_deviceIdPattern.hasMatch(value)) {
      throw InvalidBackupPathException('Invalid device id: $deviceId');
    }
    return value;
  }

  Directory deviceDirectory(String deviceId) {
    return Directory(p.join(root.path, validateDeviceId(deviceId)));
  }

  Directory downloadsDirectory(String deviceId) {
    return Directory(p.join(deviceDirectory(deviceId).path, _downloadsDirName));
  }

  Directory dbDirectory(String deviceId) {
    return Directory(p.join(deviceDirectory(deviceId).path, _dbDirName));
  }

  /// Resolves a client-supplied relative path inside the device's downloads
  /// root, rejecting anything that escapes it.
  ///
  /// Two independent checks on purpose: reject bad segments up front, then
  /// verify the normalised absolute result is still under the root. The second
  /// check is what actually stops traversal on every platform.
  ///
  /// [relativePath] must already be percent-decoded — the HTTP layer hands over
  /// `Uri.pathSegments`, which are decoded, so decoding again here would corrupt
  /// any name legitimately containing a `%`.
  File resolveDownloadFile(String deviceId, String relativePath) {
    final downloads = downloadsDirectory(deviceId);
    final decoded = relativePath;
    if (decoded.isEmpty) {
      throw const InvalidBackupPathException('Empty file path');
    }
    if (decoded.contains(r'\') || p.isAbsolute(decoded)) {
      throw InvalidBackupPathException('Invalid file path: $relativePath');
    }
    final segments = decoded.split('/');
    for (final segment in segments) {
      if (segment.isEmpty || segment == '.' || segment == '..') {
        throw InvalidBackupPathException('Invalid file path: $relativePath');
      }
    }

    final candidate = p.normalize(p.join(downloads.path, segments.join('/')));
    if (!p.isWithin(downloads.path, candidate)) {
      throw InvalidBackupPathException(
        'Path escapes backup root: $relativePath',
      );
    }
    return File(candidate);
  }

  // ---------------------------------------------------------------------
  // Devices
  // ---------------------------------------------------------------------

  Future<List<BackupDeviceSummary>> listDevices() async {
    ensureRootAvailable();
    final summaries = <BackupDeviceSummary>[];
    await for (final entity in root.list()) {
      if (entity is! Directory) {
        continue;
      }
      final deviceId = p.basename(entity.path);
      if (!_deviceIdPattern.hasMatch(deviceId)) {
        continue;
      }
      summaries.add(await describeDevice(deviceId));
    }
    summaries.sort((a, b) => a.deviceId.compareTo(b.deviceId));
    return summaries;
  }

  Future<BackupDeviceSummary> describeDevice(String deviceId) async {
    ensureRootAvailable();
    final id = validateDeviceId(deviceId);
    // Stats are always recomputed from disk rather than read back from the
    // manifest: a stale cached count could make the phone skip files it
    // actually still needs to send.
    final entries = await inventory(id);
    final snapshots = await listDbSnapshots(id);
    return BackupDeviceSummary(
      deviceId: id,
      fileCount: entries.length,
      totalBytes: entries.fold<int>(0, (sum, e) => sum + e.sizeBytes),
      dbSnapshotCount: snapshots.length,
      lastSyncAt: await _readLastSyncAt(id),
      latestDbSchemaVersion:
          snapshots.isEmpty ? null : snapshots.first.schemaVersion,
    );
  }

  // ---------------------------------------------------------------------
  // Inventory
  // ---------------------------------------------------------------------

  /// Every mirrored file for [deviceId], as `/`-separated paths relative to its
  /// downloads root. In-flight `.part` files are skipped so a partial transfer
  /// is never advertised as present.
  Future<List<InventoryEntry>> inventory(String deviceId) async {
    ensureRootAvailable();
    final downloads = downloadsDirectory(deviceId);
    if (!downloads.existsSync()) {
      return const <InventoryEntry>[];
    }
    final entries = <InventoryEntry>[];
    await for (final entity in downloads.list(recursive: true)) {
      if (entity is! File) {
        continue;
      }
      if (entity.path.endsWith(kPartSuffix)) {
        continue;
      }
      final relative = p
          .relative(entity.path, from: downloads.path)
          .replaceAll(r'\', '/');
      entries.add(
        InventoryEntry(path: relative, sizeBytes: await entity.length()),
      );
    }
    entries.sort((a, b) => a.path.compareTo(b.path));
    return entries;
  }

  // ---------------------------------------------------------------------
  // File transfer
  // ---------------------------------------------------------------------

  /// Streams [source] into the mirror, verifying it hashes to [expectedSha256].
  ///
  /// Writes to a `.part` sibling and only renames into place after the digest
  /// matches, so a failed or interrupted transfer leaves the final path
  /// untouched.
  Future<int> writeDownloadFile({
    required String deviceId,
    required String relativePath,
    required Stream<List<int>> source,
    required String expectedSha256,
  }) async {
    ensureRootAvailable();
    final target = resolveDownloadFile(deviceId, relativePath);
    return _writeVerified(
      target: target,
      source: source,
      expectedSha256: expectedSha256,
    );
  }

  Future<File?> findDownloadFile(String deviceId, String relativePath) async {
    ensureRootAvailable();
    final file = resolveDownloadFile(deviceId, relativePath);
    return file.existsSync() ? file : null;
  }

  // ---------------------------------------------------------------------
  // Database snapshots
  // ---------------------------------------------------------------------

  /// Stores a gzipped database snapshot.
  ///
  /// [expectedSha256] is the digest of the *uncompressed* bytes, and the file is
  /// stored decompressed so it can be opened directly with any sqlite tool.
  /// The filename carries both timestamp and schema version, keeping the
  /// directory listing self-describing.
  Future<DbSnapshotInfo> writeDbSnapshot({
    required String deviceId,
    required Stream<List<int>> gzippedSource,
    required String expectedSha256,
    required int schemaVersion,
  }) async {
    ensureRootAvailable();
    final id = validateDeviceId(deviceId);
    if (schemaVersion <= 0) {
      throw InvalidBackupPathException('Invalid schema version: $schemaVersion');
    }
    // Server clock, never the client's: a phone with a wrong date would produce
    // filenames that sort incorrectly and break "latest snapshot" resolution.
    final createdAt = DateTime.now().toUtc();
    final filename =
        'database-${_formatStamp(createdAt)}-v$schemaVersion.db';
    final target = File(p.join(dbDirectory(id).path, filename));

    final sizeBytes = await _writeVerified(
      target: target,
      source: gzip.decoder.bind(gzippedSource),
      expectedSha256: expectedSha256,
    );

    await _writeManifest(id, lastSyncAt: createdAt);
    await _enforceSnapshotRetention(id);

    return DbSnapshotInfo(
      filename: filename,
      createdAt: createdAt,
      sizeBytes: sizeBytes,
      schemaVersion: schemaVersion,
    );
  }

  /// Snapshots newest first.
  Future<List<DbSnapshotInfo>> listDbSnapshots(String deviceId) async {
    ensureRootAvailable();
    final dir = dbDirectory(deviceId);
    if (!dir.existsSync()) {
      return const <DbSnapshotInfo>[];
    }
    final snapshots = <DbSnapshotInfo>[];
    await for (final entity in dir.list()) {
      if (entity is! File) {
        continue;
      }
      final info = _parseSnapshot(entity);
      if (info != null) {
        snapshots.add(info);
      }
    }
    snapshots.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return snapshots;
  }

  Future<DbSnapshotInfo?> latestDbSnapshot(String deviceId) async {
    final snapshots = await listDbSnapshots(deviceId);
    return snapshots.isEmpty ? null : snapshots.first;
  }

  File dbSnapshotFile(String deviceId, String filename) {
    return File(p.join(dbDirectory(deviceId).path, filename));
  }

  // ---------------------------------------------------------------------
  // Prune
  // ---------------------------------------------------------------------

  /// Files the mirror holds that the phone no longer has.
  ///
  /// Computed only — deletion is a separate, explicitly confirmed step in the
  /// desktop UI. A backup that quietly mirrors deletions would let one
  /// accidental phone-side delete destroy the backup too.
  Future<PruneCandidates> pruneCandidates({
    required String deviceId,
    required Set<String> phonePaths,
  }) async {
    final entries = await inventory(deviceId);
    final stale = entries
        .where((entry) => !phonePaths.contains(entry.path))
        .toList(growable: false);
    return PruneCandidates(
      deviceId: validateDeviceId(deviceId),
      entries: stale,
    );
  }

  /// Deletes previously-confirmed prune candidates, plus any directories left
  /// empty afterwards. Returns how many files were actually removed.
  Future<int> deleteDownloadFiles({
    required String deviceId,
    required Iterable<String> relativePaths,
  }) async {
    ensureRootAvailable();
    var deleted = 0;
    for (final relativePath in relativePaths) {
      final file = resolveDownloadFile(deviceId, relativePath);
      if (file.existsSync()) {
        await file.delete();
        deleted++;
      }
    }
    final downloads = downloadsDirectory(deviceId);
    await _removeEmptyDirectories(downloads, keep: downloads.path);
    return deleted;
  }

  // ---------------------------------------------------------------------
  // Startup maintenance
  // ---------------------------------------------------------------------

  /// Removes leftover `.part` files from interrupted transfers.
  ///
  /// Always safe: a complete file has already been renamed to its final name, so
  /// anything still carrying the suffix is by definition discardable.
  Future<int> cleanupPartFiles() async {
    if (!rootExists) {
      return 0;
    }
    var removed = 0;
    await for (final entity in root.list(recursive: true)) {
      if (entity is File && entity.path.endsWith(kPartSuffix)) {
        try {
          await entity.delete();
          removed++;
        } on FileSystemException {
          // A file locked by another process is not worth failing startup over.
        }
      }
    }
    return removed;
  }

  // ---------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------

  Future<int> _writeVerified({
    required File target,
    required Stream<List<int>> source,
    required String expectedSha256,
  }) async {
    final partFile = File('${target.path}$kPartSuffix');
    await partFile.parent.create(recursive: true);

    final digestSink = AccumulatorSink<Digest>();
    final hashSink = sha256.startChunkedConversion(digestSink);
    final sink = partFile.openWrite();
    var sinkClosed = false;
    var written = 0;

    try {
      await for (final chunk in source) {
        hashSink.add(chunk);
        sink.add(chunk);
        written += chunk.length;
      }
      await sink.flush();
      await sink.close();
      sinkClosed = true;
    } on FileSystemException catch (error) {
      if (!sinkClosed) {
        await _closeQuietly(sink);
      }
      await _deleteQuietly(partFile);
      throw BackupStorageException('Failed to write backup file: $error');
    } catch (_) {
      if (!sinkClosed) {
        await _closeQuietly(sink);
      }
      await _deleteQuietly(partFile);
      rethrow;
    } finally {
      hashSink.close();
    }

    final actual = digestSink.events.single.toString();
    if (actual.toLowerCase() != expectedSha256.trim().toLowerCase()) {
      await _deleteQuietly(partFile);
      throw DigestMismatchException(
        'Checksum mismatch for ${p.basename(target.path)}',
      );
    }

    try {
      if (target.existsSync()) {
        await target.delete();
      }
      await partFile.rename(target.path);
    } on FileSystemException catch (error) {
      await _deleteQuietly(partFile);
      throw BackupStorageException('Failed to finalize backup file: $error');
    }
    return written;
  }

  DbSnapshotInfo? _parseSnapshot(File file) {
    final match = _snapshotPattern.firstMatch(p.basename(file.path));
    if (match == null) {
      return null;
    }
    final createdAt = _parseStamp(match.group(1)!, match.group(2)!);
    if (createdAt == null) {
      return null;
    }
    return DbSnapshotInfo(
      filename: p.basename(file.path),
      createdAt: createdAt,
      sizeBytes: file.lengthSync(),
      schemaVersion: int.parse(match.group(3)!),
    );
  }

  Future<void> _enforceSnapshotRetention(String deviceId) async {
    final snapshots = await listDbSnapshots(deviceId);
    if (snapshots.length <= maxDbSnapshots) {
      return;
    }
    for (final stale in snapshots.skip(maxDbSnapshots)) {
      await _deleteQuietly(dbSnapshotFile(deviceId, stale.filename));
    }
  }

  File _manifestFile(String deviceId) {
    return File(p.join(deviceDirectory(deviceId).path, _manifestFileName));
  }

  Future<void> _writeManifest(
    String deviceId, {
    required DateTime lastSyncAt,
  }) async {
    final file = _manifestFile(deviceId);
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(<String, Object?>{
        'deviceId': deviceId,
        'lastSyncAt': lastSyncAt.toIso8601String(),
      }),
    );
  }

  Future<DateTime?> _readLastSyncAt(String deviceId) async {
    final file = _manifestFile(deviceId);
    if (!file.existsSync()) {
      return null;
    }
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map<String, Object?>) {
        final raw = decoded['lastSyncAt'];
        if (raw is String) {
          return DateTime.tryParse(raw);
        }
      }
    } on FormatException {
      // A corrupt manifest only costs a display timestamp; everything else is
      // reconstructed from disk.
    } on FileSystemException {
      return null;
    }
    return null;
  }

  /// Removes directories left empty by a prune, without ever removing [keep]
  /// itself — the device's downloads root must survive so later syncs still
  /// have somewhere to write.
  Future<void> _removeEmptyDirectories(
    Directory directory, {
    required String keep,
  }) async {
    if (!directory.existsSync()) {
      return;
    }
    for (final entity in directory.listSync()) {
      if (entity is Directory) {
        await _removeEmptyDirectories(entity, keep: keep);
      }
    }
    if (directory.listSync().isEmpty &&
        p.equals(directory.path, keep) == false) {
      await _deleteDirectoryQuietly(directory);
    }
  }

  static Future<void> _closeQuietly(IOSink sink) async {
    try {
      await sink.close();
    } on FileSystemException {
      // Already failing; the original error is the one worth reporting.
    }
  }

  static Future<void> _deleteQuietly(File file) async {
    try {
      if (file.existsSync()) {
        await file.delete();
      }
    } on FileSystemException {
      // Best effort cleanup.
    }
  }

  static Future<void> _deleteDirectoryQuietly(Directory directory) async {
    try {
      await directory.delete();
    } on FileSystemException {
      // Best effort cleanup.
    }
  }

  static String _formatStamp(DateTime value) {
    final utc = value.toUtc();
    String pad(int value, int width) => value.toString().padLeft(width, '0');
    final date = '${pad(utc.year, 4)}${pad(utc.month, 2)}${pad(utc.day, 2)}';
    final time =
        '${pad(utc.hour, 2)}${pad(utc.minute, 2)}${pad(utc.second, 2)}'
        '${pad(utc.millisecond, 3)}';
    return '$date-$time';
  }

  static DateTime? _parseStamp(String date, String time) {
    try {
      return DateTime.utc(
        int.parse(date.substring(0, 4)),
        int.parse(date.substring(4, 6)),
        int.parse(date.substring(6, 8)),
        int.parse(time.substring(0, 2)),
        int.parse(time.substring(2, 4)),
        int.parse(time.substring(4, 6)),
        int.parse(time.substring(6, 9)),
      );
    } on FormatException {
      return null;
    }
  }
}
