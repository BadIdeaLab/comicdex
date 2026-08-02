import 'dart:async';
import 'dart:io';

import 'package:concept_nhv/services/backup/backup_connection.dart';
import 'package:concept_nhv/services/backup/backup_control_client.dart';
import 'package:concept_nhv/services/backup/backup_sync_service.dart';
import 'package:concept_nhv/services/download_asset_store.dart';
import 'package:concept_nhv/state/backup_control_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../test_support/fakes/fake_backup_client.dart';
import '../test_support/storage/sqlite_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BackupControlModel', () {
    late SqliteTestHarness harness;
    late Directory root;
    late FakeBackupClient backupClient;
    late FakeControlClient controlClient;
    late BackupControlModel model;
    var wakelockEnabled = 0;
    var wakelockDisabled = 0;

    setUp(() async {
      wakelockEnabled = 0;
      wakelockDisabled = 0;
      harness = SqliteTestHarness();
      await harness.initialize();
      root = await Directory.systemTemp.createTemp('backup-control-test');
      backupClient = FakeBackupClient();
      controlClient = FakeControlClient();
      final syncService = BackupSyncService(
        client: backupClient,
        downloadAssetStore: DownloadAssetStore(
          directoryResolver: () async =>
              Directory(p.join(root.path, 'downloads')),
        ),
        downloadQueueRepository: harness.downloadQueueRepository,
        schemaVersion: 9,
        snapshotBuilder: () async =>
            File(p.join(root.path, 'snapshot.db'))
              ..writeAsBytesSync(<int>[1, 2, 3]),
      );
      model = BackupControlModel(
        client: controlClient,
        healthClient: backupClient,
        syncService: syncService,
        enableWakelock: () async => wakelockEnabled++,
        disableWakelock: () async => wakelockDisabled++,
      );
    });

    tearDown(() async {
      model.dispose();
      await controlClient.dispose();
      await harness.dispose();
      if (root.existsSync()) {
        await root.delete(recursive: true);
      }
    });

    test('pairing alone does not start a backup', () async {
      await model.connect(_connection);

      expect(model.state, BackupControlState.idle);
      expect(backupClient.callLog, <String>['health']);
      expect(controlClient.statuses.last.state, 'idle');
    });

    test('desktop start command runs backup and reports completion', () async {
      await model.connect(_connection);
      controlClient.addCommand(
        const BackupControlCommand(action: 'startBackup', commandId: 'one'),
      );
      await _waitUntil(() => model.state == BackupControlState.completed);

      expect(
        backupClient.callLog,
        containsAllInOrder(<String>['health', 'health', 'database']),
      );
      expect(controlClient.statuses.last.state, 'completed');
      expect(wakelockEnabled, 1);
      expect(wakelockDisabled, 1);
    });

    test('duplicate command id is idempotent', () async {
      await model.connect(_connection);
      const command = BackupControlCommand(
        action: 'startBackup',
        commandId: 'same',
      );
      controlClient.addCommand(command);
      await _waitUntil(() => model.state == BackupControlState.completed);
      controlClient.addCommand(command);
      await Future<void>.delayed(Duration.zero);

      expect(
        backupClient.callLog.where((entry) => entry == 'database'),
        hasLength(1),
      );
    });

    test('socket closure marks the phone disconnected', () async {
      await model.connect(_connection);
      controlClient.closeRemotely();
      await _waitUntil(() => model.state == BackupControlState.disconnected);

      expect(model.isConnected, isFalse);
    });

    test(
      'socket closure during a file leaves the final state disconnected',
      () async {
        final file = File(
          p.join(root.path, 'downloads', '177013', 'cover.webp'),
        );
        await file.parent.create(recursive: true);
        await file.writeAsBytes(<int>[1, 2, 3]);
        final gate = Completer<void>();
        backupClient.uploadGate = gate;
        await model.connect(_connection);
        controlClient.addCommand(
          const BackupControlCommand(action: 'startBackup', commandId: 'slow'),
        );
        await _waitUntil(
          () => backupClient.callLog.contains('file:177013/cover.webp'),
        );

        controlClient.closeRemotely();
        gate.complete();
        await _waitUntil(() => model.state == BackupControlState.disconnected);
        await Future<void>.delayed(const Duration(milliseconds: 5));

        expect(model.state, BackupControlState.disconnected);
        expect(model.isConnected, isFalse);
      },
    );

    test(
      'pause during a file finishes that file but never starts the next',
      () async {
        for (final relativePath in <String>[
          p.join('downloads', '177013', 'cover.webp'),
          p.join('downloads', '177013', 'pages', '1.webp'),
        ]) {
          final file = File(p.join(root.path, relativePath));
          await file.parent.create(recursive: true);
          await file.writeAsBytes(<int>[1, 2, 3]);
        }
        final gate = Completer<void>();
        backupClient.uploadGate = gate;
        await model.connect(_connection);
        controlClient.addCommand(
          const BackupControlCommand(action: 'startBackup', commandId: 'start'),
        );
        await _waitUntil(
          () => backupClient.callLog.contains('file:177013/cover.webp'),
        );

        controlClient.addCommand(
          const BackupControlCommand(action: 'pause', commandId: 'pause'),
        );
        await _waitUntil(() => model.state == BackupControlState.pausing);
        gate.complete();
        await _waitUntil(() => model.state == BackupControlState.paused);

        expect(backupClient.uploadedPaths, <String>['177013/cover.webp']);
        expect(
          backupClient.callLog,
          isNot(contains('file:177013/pages/1.webp')),
        );
        expect(controlClient.statuses.last.state, 'paused');
      },
    );

    // ---------------------------------------------------------------------
    // Snapshot policy: one logical backup uploads exactly one DB snapshot.
    // ---------------------------------------------------------------------

    /// Writes two files and pauses after the first, leaving the model paused
    /// mid-backup with its snapshot already uploaded.
    Future<void> startAndPauseMidBackup() async {
      for (final relativePath in <String>[
        p.join('downloads', '177013', 'cover.webp'),
        p.join('downloads', '177013', 'pages', '1.webp'),
      ]) {
        final file = File(p.join(root.path, relativePath));
        await file.parent.create(recursive: true);
        await file.writeAsBytes(<int>[1, 2, 3]);
      }
      final gate = Completer<void>();
      backupClient.uploadGate = gate;
      controlClient.addCommand(
        const BackupControlCommand(action: 'startBackup', commandId: 's1'),
      );
      await _waitUntil(
        () => backupClient.callLog.contains('file:177013/cover.webp'),
      );
      controlClient.addCommand(
        const BackupControlCommand(action: 'pause', commandId: 'p1'),
      );
      await _waitUntil(() => model.state == BackupControlState.pausing);
      gate.complete();
      backupClient.uploadGate = null;
      await _waitUntil(() => model.state == BackupControlState.paused);
    }

    int databaseUploadCount() =>
        backupClient.callLog.where((entry) => entry == 'database').length;

    test(
      'resuming a paused backup reuses the existing snapshot instead of '
      'minting another one',
      () async {
        await model.connect(_connection);
        await startAndPauseMidBackup();
        expect(databaseUploadCount(), 1);

        // The server now holds the first file, so a resume only owes the second.
        backupClient.inventory = <String, int>{'177013/cover.webp': 3};
        controlClient.addCommand(
          const BackupControlCommand(action: 'startBackup', commandId: 's2'),
        );
        await _waitUntil(() => model.state == BackupControlState.completed);

        expect(databaseUploadCount(), 1);
        expect(backupClient.uploadedPaths, <String>[
          '177013/cover.webp',
          '177013/pages/1.webp',
        ]);
      },
    );

    test('starting again after completion creates a new snapshot', () async {
      await model.connect(_connection);
      controlClient.addCommand(
        const BackupControlCommand(action: 'startBackup', commandId: 'one'),
      );
      await _waitUntil(() => model.state == BackupControlState.completed);
      expect(databaseUploadCount(), 1);

      controlClient.addCommand(
        const BackupControlCommand(action: 'startBackup', commandId: 'two'),
      );
      // Wait for the second run to finish, not merely to reach the upload:
      // tearDown disposes the model, and an in-flight run would then call
      // notifyListeners() on a disposed ChangeNotifier.
      await _waitUntil(
        () =>
            databaseUploadCount() == 2 &&
            model.state == BackupControlState.completed,
      );

      expect(databaseUploadCount(), 2);
    });

    test(
      'a failed database upload never leaves the backup resumable — otherwise '
      'the next start would skip the snapshot the server never received',
      () async {
        await model.connect(_connection);
        backupClient.databaseError = StateError('snapshot rejected');
        controlClient.addCommand(
          const BackupControlCommand(action: 'startBackup', commandId: 'bad'),
        );
        await _waitUntil(() => model.state == BackupControlState.error);

        backupClient.databaseError = null;
        controlClient.addCommand(
          const BackupControlCommand(action: 'startBackup', commandId: 'retry'),
        );
        await _waitUntil(() => model.state == BackupControlState.completed);

        // Two attempts: the failed one and the retry that actually captured.
        expect(databaseUploadCount(), 2);
      },
    );

    test(
      'reconnecting discards the checkpoint, because the snapshot belonged to '
      'a session that no longer exists',
      () async {
        await model.connect(_connection);
        await startAndPauseMidBackup();
        expect(databaseUploadCount(), 1);

        controlClient.closeRemotely();
        await _waitUntil(() => model.state == BackupControlState.disconnected);
        await model.connect(_connection);

        backupClient.inventory = <String, int>{'177013/cover.webp': 3};
        controlClient.addCommand(
          const BackupControlCommand(action: 'startBackup', commandId: 's3'),
        );
        await _waitUntil(() => model.state == BackupControlState.completed);

        expect(databaseUploadCount(), 2);
      },
    );

    test(
      'an explicit disconnect also discards the checkpoint',
      () async {
        await model.connect(_connection);
        await startAndPauseMidBackup();

        await model.disconnect();
        await model.connect(_connection);

        backupClient.inventory = <String, int>{'177013/cover.webp': 3};
        controlClient.addCommand(
          const BackupControlCommand(action: 'startBackup', commandId: 's4'),
        );
        await _waitUntil(() => model.state == BackupControlState.completed);

        expect(databaseUploadCount(), 2);
      },
    );
  });
}

final BackupConnection _connection = BackupConnection(
  baseUri: Uri.parse('http://127.0.0.1:8787'),
  pin: '123456',
  deviceId: 'Pixel-8',
);

Future<void> _waitUntil(bool Function() predicate) async {
  for (var attempt = 0; attempt < 100 && !predicate(); attempt++) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  expect(predicate(), isTrue);
}

class SentStatus {
  const SentStatus(this.state);
  final String state;
}

class FakeControlClient implements BackupControlClient {
  final StreamController<BackupControlCommand> _commands =
      StreamController<BackupControlCommand>.broadcast();
  final StreamController<void> _disconnected =
      StreamController<void>.broadcast();
  final List<SentStatus> statuses = <SentStatus>[];
  bool _connected = false;

  @override
  Stream<BackupControlCommand> get commands => _commands.stream;

  @override
  Stream<void> get disconnected => _disconnected.stream;

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect(BackupConnection connection) async {
    _connected = true;
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
  }

  void addCommand(BackupControlCommand command) => _commands.add(command);

  void closeRemotely() {
    _connected = false;
    _disconnected.add(null);
  }


  @override
  void sendStatus({
    required String state,
    String? commandId,
    int uploadedFiles = 0,
    int totalFiles = 0,
    String? currentPath,
    String? message,
  }) {
    statuses.add(SentStatus(state));
  }

  Future<void> dispose() async {
    await _commands.close();
    await _disconnected.close();
  }
}
