import 'dart:async';

import 'package:concept_nhv/services/backup/backup_connection.dart';
import 'package:concept_nhv/services/backup/backup_client.dart';
import 'package:concept_nhv/services/backup/backup_control_client.dart';
import 'package:concept_nhv/services/backup/backup_models.dart';
import 'package:concept_nhv/services/backup/backup_restore_service.dart';
import 'package:concept_nhv/services/backup/backup_sync_service.dart';
import 'package:concept_nhv/services/backup/restore_models.dart';
import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

enum BackupControlState {
  disconnected,
  connecting,
  idle,
  running,
  pausing,
  paused,
  completed,
  error,
}

class BackupControlModel extends ChangeNotifier {
  BackupControlModel({
    required BackupControlClient client,
    required BackupClient healthClient,
    required BackupSyncService syncService,
    BackupRestoreService? restoreService,
    Future<void> Function()? enableWakelock,
    Future<void> Function()? disableWakelock,
  }) : _client = client,
       _healthClient = healthClient,
       _syncService = syncService,
       _restoreService = restoreService,
       _enableWakelock = enableWakelock ?? WakelockPlus.enable,
       _disableWakelock = disableWakelock ?? WakelockPlus.disable {
    _commandSubscription = _client.commands.listen(_handleCommand);
    _disconnectSubscription = _client.disconnected.listen((_) {
      _pauseToken?.requestPause();
      _connection = null;
      // The snapshot was uploaded to a session that no longer exists; the next
      // start has to be a fresh logical backup.
      _canResumeWithoutSnapshot = false;
      _state = BackupControlState.disconnected;
      notifyListeners();
    });
  }

  final BackupControlClient _client;
  final BackupClient _healthClient;
  final BackupSyncService _syncService;
  final BackupRestoreService? _restoreService;
  final Future<void> Function() _enableWakelock;
  final Future<void> Function() _disableWakelock;
  late final StreamSubscription<BackupControlCommand> _commandSubscription;
  late final StreamSubscription<void> _disconnectSubscription;

  BackupControlState _state = BackupControlState.disconnected;
  BackupConnection? _connection;
  BackupSyncProgress? _progress;
  BackupSyncResult? _result;
  BackupPauseToken? _pauseToken;
  String? _error;
  String? _activeCommandId;
  final Set<String> _handledCommands = <String>{};

  /// True while a paused backup can be resumed without re-uploading the
  /// database snapshot.
  ///
  /// Deliberately in-memory only and **never persisted**. A checkpoint is only
  /// meaningful against the exact server state the snapshot was uploaded to; if
  /// it survived an app restart, a re-pair, or a different desktop, a resume
  /// would skip the snapshot and leave that server holding files with no
  /// database describing them. Keeping it in RAM makes every one of those cases
  /// reset to "new backup" for free, with no expiry logic to get wrong.
  bool _canResumeWithoutSnapshot = false;

  /// Which kind of job the reported state belongs to.
  bool _activeJobIsRestore = false;

  /// A restore finished and its database is waiting in the pending slot.
  ///
  /// Nothing the user does in the app now survives: the next launch replaces
  /// the database wholesale. Until they relaunch, what they are looking at is
  /// the old library over the new files, so the UI has to say so plainly rather
  /// than report a cheerful "completed".
  bool _restoreAwaitingRestart = false;

  bool get restoreAwaitingRestart => _restoreAwaitingRestart;
  bool get lastJobWasRestore => _activeJobIsRestore;

  BackupControlState get state => _state;
  BackupSyncProgress? get progress => _progress;
  BackupSyncResult? get result => _result;
  String? get error => _error;
  bool get isConnected => _connection != null && _client.isConnected;

  Future<void> connect(BackupConnection connection) async {
    _state = BackupControlState.connecting;
    _error = null;
    // Re-pairing always starts a new logical backup, even against the same
    // desktop: the server may have been restarted or pointed at another folder.
    _canResumeWithoutSnapshot = false;
    notifyListeners();
    try {
      await _healthClient.checkHealth(connection);
      try {
        await _client.connect(connection);
      } on Object catch (error) {
        // Health already succeeded, so the machine is definitely reachable and
        // the PIN is right — the server refused the pairing itself (e.g. a
        // device name it will not accept). Reported as a server error rather
        // than a connectivity one, because `WebSocket.connect` throws a plain
        // WebSocketException that would otherwise be misread as "cannot reach
        // this computer" and send the user hunting through Wi-Fi and firewall
        // settings for a problem that is not there.
        throw BackupPairingRejectedException('$error');
      }
      _connection = connection;
      _state = BackupControlState.idle;
      _sendState();
    } catch (error) {
      _connection = null;
      _state = BackupControlState.error;
      _error = '$error';
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    _pauseToken?.requestPause();
    await _client.disconnect();
    _connection = null;
    _canResumeWithoutSnapshot = false;
    _state = BackupControlState.disconnected;
    notifyListeners();
  }

  void _handleCommand(BackupControlCommand command) {
    if (!_handledCommands.add(command.commandId)) {
      _sendState();
      return;
    }
    if (_handledCommands.length > 100) {
      _handledCommands.remove(_handledCommands.first);
    }
    switch (command.action) {
      case 'startBackup':
        if (_state != BackupControlState.running &&
            _state != BackupControlState.pausing) {
          unawaited(_runBackup(command.commandId));
        } else {
          _sendState(commandId: command.commandId);
        }
      case 'startRestore':
        final source = command.sourceDeviceId;
        if (source == null || source.isEmpty) {
          // The desktop is the only place that knows which partitions exist, so
          // a restore command without one is malformed rather than a default.
          _error = 'Restore command did not name a source device';
          _state = BackupControlState.error;
          _sendState(commandId: command.commandId, message: _error);
          notifyListeners();
        } else if (_state != BackupControlState.running &&
            _state != BackupControlState.pausing) {
          unawaited(_runRestore(command.commandId, source));
        } else {
          _sendState(commandId: command.commandId);
        }
      case 'pause':
        if (_state == BackupControlState.running) {
          _activeCommandId = command.commandId;
          _pauseToken?.requestPause();
          _state = BackupControlState.pausing;
          _sendState();
          notifyListeners();
        } else {
          _sendState(commandId: command.commandId);
        }
    }
  }

  /// Restores this device from [sourceDeviceId]'s partition.
  ///
  /// Reuses the backup job's state machine so the desktop sees one consistent
  /// set of states, and so a restore is subject to the same "one job at a time"
  /// rule — the two must never run together, since a backup would upload the
  /// half-restored library back over the mirror it is being restored from.
  Future<void> _runRestore(String commandId, String sourceDeviceId) async {
    final connection = _connection;
    final restoreService = _restoreService;
    if (connection == null) {
      return;
    }
    if (restoreService == null) {
      _error = 'Restore is not available on this build';
      _state = BackupControlState.error;
      _sendState(commandId: commandId, message: _error);
      notifyListeners();
      return;
    }

    _activeCommandId = commandId;
    _activeJobIsRestore = true;
    _restoreAwaitingRestart = false;
    _pauseToken = BackupPauseToken();
    _progress = const BackupSyncProgress(stage: BackupSyncStage.connecting);
    _result = null;
    _error = null;
    // A restore invalidates any resume checkpoint: the library it described is
    // being replaced wholesale.
    _canResumeWithoutSnapshot = false;
    _state = BackupControlState.running;
    _sendState();
    notifyListeners();
    await _enableWakelock();
    try {
      final result = await restoreService.run(
        connection: connection,
        sourceDeviceId: sourceDeviceId,
        pauseToken: _pauseToken,
        onProgress: (progress) {
          // Mapped onto the backup progress shape so the desktop needs only one
          // renderer; the wire protocol carries counts, not job kinds.
          _progress = BackupSyncProgress(
            stage: switch (progress.stage) {
              RestoreStage.checking ||
              RestoreStage.planning => BackupSyncStage.comparing,
              RestoreStage.clearing ||
              RestoreStage.downloading => BackupSyncStage.uploading,
              RestoreStage.applying ||
              RestoreStage.done => BackupSyncStage.done,
            },
            uploadedFiles: progress.downloadedFiles,
            totalFiles: progress.totalFiles,
            currentPath: progress.currentPath,
          );
          _sendState();
          notifyListeners();
        },
      );
      if (_connection == null || !_client.isConnected) {
        _state = BackupControlState.disconnected;
      } else if (result.databaseStaged) {
        _restoreAwaitingRestart = true;
        _state = BackupControlState.completed;
        _sendState();
      } else {
        _state = result.isPaused
            ? BackupControlState.paused
            : BackupControlState.error;
        _error = result.failures.isEmpty ? null : result.failures.first;
        _sendState(message: _error);
      }
    } on RestoreBlockedException catch (error) {
      // These are refusals, not faults: nothing local was touched.
      _error = switch (error.reason) {
        RestoreBlockedReason.backupIsNewer =>
          'That backup was made by a newer version of the app',
        RestoreBlockedReason.noDatabaseSnapshot =>
          'That device has no database snapshot to restore from',
        RestoreBlockedReason.emptySource => 'That device has no backup yet',
      };
      _state = BackupControlState.error;
      _sendState(message: _error);
    } catch (error) {
      _error = '$error';
      _state = _client.isConnected
          ? BackupControlState.error
          : BackupControlState.disconnected;
      _sendState(message: _error);
    } finally {
      _pauseToken = null;
      await _disableWakelock();
      notifyListeners();
    }
  }

  Future<void> _runBackup(String commandId) async {
    final connection = _connection;
    if (connection == null) {
      return;
    }
    // Resolved before _state is overwritten below. Only a backup that paused
    // *after* successfully uploading its snapshot may skip that step.
    final snapshotPolicy = _canResumeWithoutSnapshot
        ? DatabaseSnapshotPolicy.skip
        : DatabaseSnapshotPolicy.capture;

    _activeCommandId = commandId;
    _activeJobIsRestore = false;
    _pauseToken = BackupPauseToken();
    _progress = const BackupSyncProgress(stage: BackupSyncStage.connecting);
    _result = null;
    _error = null;
    _state = BackupControlState.running;
    _sendState();
    notifyListeners();
    await _enableWakelock();
    try {
      final result = await _syncService.run(
        connection: connection,
        pauseToken: _pauseToken,
        snapshotPolicy: snapshotPolicy,
        onProgress: (progress) {
          _progress = progress;
          _sendState();
          notifyListeners();
        },
      );
      _result = result;
      if (_connection == null || !_client.isConnected) {
        _canResumeWithoutSnapshot = false;
        _state = BackupControlState.disconnected;
      } else if (result.isPaused) {
        // Still the same logical backup: keep the checkpoint if this run
        // uploaded the snapshot, or if an earlier run in this backup did.
        _canResumeWithoutSnapshot =
            _canResumeWithoutSnapshot || result.databaseSnapshotUploaded;
        _state = BackupControlState.paused;
        _sendState();
      } else {
        // Finished: the next start is a new backup and gets a new snapshot.
        _canResumeWithoutSnapshot = false;
        _state = BackupControlState.completed;
        _sendState();
      }
    } catch (error) {
      _error = '$error';
      // A failed run says nothing reliable about the server's state, including
      // whether the snapshot landed — never resume across it.
      _canResumeWithoutSnapshot = false;
      if (_connection == null || !_client.isConnected) {
        _state = BackupControlState.disconnected;
      } else {
        _state = BackupControlState.error;
        _sendState(message: _error);
      }
    } finally {
      _pauseToken = null;
      await _disableWakelock();
      notifyListeners();
    }
  }

  void _sendState({String? commandId, String? message}) {
    // The desktop otherwise labels a finished restore "backup completed".
    final jobKind = _activeJobIsRestore ? 'restore' : 'backup';
    final progress = _progress;
    _client.sendStatus(
      state: _wireState,
      jobKind: jobKind,
      commandId: commandId ?? _activeCommandId,
      uploadedFiles: progress?.uploadedFiles ?? 0,
      totalFiles: progress?.totalFiles ?? 0,
      currentPath: progress?.currentPath,
      message: message,
    );
  }

  String get _wireState => switch (_state) {
    BackupControlState.disconnected || BackupControlState.connecting => 'idle',
    BackupControlState.idle => 'idle',
    BackupControlState.running => 'running',
    BackupControlState.pausing => 'pausing',
    BackupControlState.paused => 'paused',
    BackupControlState.completed => 'completed',
    BackupControlState.error => 'error',
  };

  @override
  void dispose() {
    _pauseToken?.requestPause();
    unawaited(_client.disconnect());
    unawaited(_commandSubscription.cancel());
    unawaited(_disconnectSubscription.cancel());
    unawaited(_disableWakelock());
    super.dispose();
  }
}
