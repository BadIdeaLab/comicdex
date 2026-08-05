import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:concept_nhv/services/backup/backup_client.dart';
import 'package:concept_nhv/services/backup/backup_connection.dart';

class BackupControlCommand {
  const BackupControlCommand({
    required this.action,
    required this.commandId,
    this.sourceDeviceId,
  });

  final String action;
  final String commandId;

  /// Which device's backup a  should pull from.
  ///
  /// Absent for every other action. It is chosen on the desktop because that is
  /// where the list of backed-up devices lives — and a replacement phone needs
  /// to name a partition that is not its own.
  final String? sourceDeviceId;
}

abstract class BackupControlClient {
  Stream<BackupControlCommand> get commands;
  Stream<void> get disconnected;
  bool get isConnected;

  Future<void> connect(BackupConnection connection);
  void sendStatus({
    required String state,
    String? commandId,
    int uploadedFiles = 0,
    int totalFiles = 0,
    String? currentPath,
    String? message,
  });
  Future<void> disconnect();
}

class WebSocketBackupControlClient implements BackupControlClient {
  final StreamController<BackupControlCommand> _commands =
      StreamController<BackupControlCommand>.broadcast();
  final StreamController<void> _disconnected =
      StreamController<void>.broadcast();
  WebSocket? _socket;
  StreamSubscription<Object?>? _subscription;

  @override
  Stream<BackupControlCommand> get commands => _commands.stream;
  @override
  Stream<void> get disconnected => _disconnected.stream;

  @override
  bool get isConnected => _socket != null;

  @override
  Future<void> connect(BackupConnection connection) async {
    await disconnect();
    final uri = connection.baseUri.replace(
      scheme: connection.baseUri.scheme == 'https' ? 'wss' : 'ws',
      path: '/control/connect',
    );
    final socket = await WebSocket.connect(
      uri.toString(),
      headers: <String, String>{
        kBackupPinHeader: connection.pin,
        kBackupDeviceHeader: connection.deviceId,
      },
    );
    _socket = socket;
    _subscription = socket.listen(
      _onMessage,
      onDone: _handleSocketClosed,
      onError: (_) => _handleSocketClosed(),
      cancelOnError: true,
    );
  }

  void _handleSocketClosed() {
    if (_socket == null) {
      return;
    }
    _socket = null;
    _disconnected.add(null);
  }

  void _onMessage(Object? raw) {
    if (raw is! String) {
      return;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, Object?> || decoded['type'] != 'command') {
      return;
    }
    final action = decoded['action'];
    final commandId = decoded['commandId'];
    if (action is String && commandId is String) {
      _commands.add(
        BackupControlCommand(
          action: action,
          commandId: commandId,
          sourceDeviceId: decoded['sourceDeviceId'] as String?,
        ),
      );
    }
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
    _socket?.add(
      jsonEncode(<String, Object?>{
        'type': 'status',
        'state': state,
        'commandId': ?commandId,
        'uploadedFiles': uploadedFiles,
        'totalFiles': totalFiles,
        'currentPath': ?currentPath,
        'message': ?message,
      }),
    );
  }

  @override
  Future<void> disconnect() async {
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
    final socket = _socket;
    _socket = null;
    await socket?.close(WebSocketStatus.normalClosure, 'Disconnected');
  }
}
