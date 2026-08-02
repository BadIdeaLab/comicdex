import 'dart:async';
import 'dart:io';

import 'package:concept_nhv/services/backup/backup_client.dart';
import 'package:concept_nhv/services/backup/backup_connection.dart';

/// Records every call in order so tests can assert not just *what* was sent but
/// *when* — the database-before-files ordering is a correctness requirement, not
/// a style choice.
class FakeBackupClient implements BackupClient {
  FakeBackupClient({
    this.inventory = const <String, int>{},
    this.devices = const <RemoteBackupDevice>[],
    this.healthError,
    this.failUploadsFor = const <String>{},
  });

  Map<String, int> inventory;
  List<RemoteBackupDevice> devices;
  Object? healthError;

  /// Relative paths whose upload should throw, to exercise partial failure.
  Set<String> failUploadsFor;
  Completer<void>? uploadGate;

  final List<String> callLog = <String>[];
  final List<String> uploadedPaths = <String>[];
  final List<int> uploadedDatabaseSchemaVersions = <int>[];

  @override
  Future<void> checkHealth(BackupConnection connection) async {
    callLog.add('health');
    final error = healthError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<List<RemoteBackupDevice>> listDevices(
    BackupConnection connection,
  ) async {
    callLog.add('devices');
    return devices;
  }

  @override
  Future<Map<String, int>> fetchInventory(BackupConnection connection) async {
    callLog.add('inventory');
    return inventory;
  }

  @override
  Future<void> uploadFile({
    required BackupConnection connection,
    required String relativePath,
    required File file,
  }) async {
    callLog.add('file:$relativePath');
    await uploadGate?.future;
    if (failUploadsFor.contains(relativePath)) {
      throw StateError('simulated upload failure for $relativePath');
    }
    uploadedPaths.add(relativePath);
  }

  /// Set to make the database upload fail, so tests can prove a resume
  /// checkpoint is never established off a snapshot that did not land.
  Object? databaseError;

  @override
  Future<void> uploadDatabase({
    required BackupConnection connection,
    required File snapshot,
    required int schemaVersion,
  }) async {
    callLog.add('database');
    final error = databaseError;
    if (error != null) {
      throw error;
    }
    uploadedDatabaseSchemaVersions.add(schemaVersion);
  }
}
