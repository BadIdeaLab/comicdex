/// A single file the desktop mirror already holds for a device.
///
/// [path] is relative to that device's `downloads/` root and always uses `/`
/// separators, matching the mobile app's own relative-path convention so the
/// two sides can compare inventories directly.
class InventoryEntry {
  const InventoryEntry({required this.path, required this.sizeBytes});

  final String path;
  final int sizeBytes;

  Map<String, Object?> toJson() {
    return <String, Object?>{'path': path, 'sizeBytes': sizeBytes};
  }
}

/// One stored database snapshot.
///
/// Timestamp and schema version are encoded in the filename so the directory
/// listing alone is enough to reconstruct this — the manifest is only a cache
/// and is never trusted as the source of truth.
class DbSnapshotInfo {
  const DbSnapshotInfo({
    required this.filename,
    required this.createdAt,
    required this.sizeBytes,
    required this.schemaVersion,
  });

  final String filename;
  final DateTime createdAt;
  final int sizeBytes;
  final int schemaVersion;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'filename': filename,
      'createdAt': createdAt.toIso8601String(),
      'sizeBytes': sizeBytes,
      'schemaVersion': schemaVersion,
    };
  }
}

/// Aggregate view of one device's partition, used by `GET /devices` and by the
/// desktop UI's device list.
class BackupDeviceSummary {
  const BackupDeviceSummary({
    required this.deviceId,
    required this.fileCount,
    required this.totalBytes,
    required this.dbSnapshotCount,
    this.lastSyncAt,
    this.latestDbSchemaVersion,
  });

  final String deviceId;
  final int fileCount;
  final int totalBytes;
  final int dbSnapshotCount;
  final DateTime? lastSyncAt;
  final int? latestDbSchemaVersion;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'deviceId': deviceId,
      'fileCount': fileCount,
      'totalBytes': totalBytes,
      'dbSnapshotCount': dbSnapshotCount,
      'lastSyncAt': lastSyncAt?.toIso8601String(),
      'latestDbSchemaVersion': latestDbSchemaVersion,
    };
  }
}

/// Result of comparing the mirror against the phone's current file list.
///
/// Nothing is deleted when this is produced — it is only the candidate set the
/// desktop UI shows for explicit confirmation.
class PruneCandidates {
  const PruneCandidates({required this.deviceId, required this.entries});

  final String deviceId;
  final List<InventoryEntry> entries;

  int get totalBytes =>
      entries.fold<int>(0, (sum, entry) => sum + entry.sizeBytes);

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'deviceId': deviceId,
      'fileCount': entries.length,
      'totalBytes': totalBytes,
      'entries': entries.map((entry) => entry.toJson()).toList(growable: false),
    };
  }
}
