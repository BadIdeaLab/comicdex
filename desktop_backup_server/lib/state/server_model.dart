import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/backup_models.dart';
import '../server/backup_server.dart';
import '../server/pin_guard.dart';
import '../services/network_addresses.dart';
import '../storage/backup_library.dart';
import '../storage/server_settings_store.dart';

/// Drives the whole desktop app: owns the library, the server, and everything
/// the UI renders.
class ServerModel extends ChangeNotifier {
  ServerModel({ServerSettingsStore? settingsStore})
    : _settingsStore = settingsStore ?? ServerSettingsStore();

  static const int maxActivityEntries = 100;

  final ServerSettingsStore _settingsStore;

  BackupLibrary? _library;
  BackupServer? _server;
  PinGuard? _pinGuard;

  Directory? _rootDirectory;
  List<LanAddress> _addresses = const <LanAddress>[];
  List<BackupDeviceSummary> _devices = const <BackupDeviceSummary>[];
  final List<String> _activity = <String>[];
  PruneCandidates? _pendingPrune;
  String? _startupError;
  bool _isStarting = true;
  bool _hasServedAnyone = false;

  Directory? get rootDirectory => _rootDirectory;
  String get rootPath => _rootDirectory?.path ?? '';
  bool get rootExists => _rootDirectory?.existsSync() ?? false;
  List<LanAddress> get addresses => _addresses;
  List<BackupDeviceSummary> get devices => _devices;
  List<String> get activity => List<String>.unmodifiable(_activity);
  PruneCandidates? get pendingPrune => _pendingPrune;
  String? get startupError => _startupError;
  bool get isStarting => _isStarting;
  bool get isRunning => _server?.isRunning ?? false;
  int? get port => _server?.port;
  String get pin => _pinGuard?.pin ?? '------';
  List<String> get lockedOutAddresses =>
      _pinGuard?.lockedOutAddresses ?? const <String>[];

  /// True until a request has actually been served. The UI uses this to keep the
  /// Windows Firewall hint visible — an unapproved firewall prompt is by far the
  /// most common reason the phone "can't connect", and it looks identical to a
  /// wrong IP.
  bool get hasServedAnyone => _hasServedAnyone;

  Future<void> initialize() async {
    _isStarting = true;
    notifyListeners();

    try {
      _rootDirectory = await _settingsStore.resolveRootDirectory();
      final library = BackupLibrary(root: _rootDirectory!);
      _library = library;

      if (library.rootExists) {
        final removed = await library.cleanupPartFiles();
        if (removed > 0) {
          _log('Cleaned up $removed interrupted transfer(s)');
        }
      }

      _pinGuard = PinGuard();
      final server = BackupServer(
        library: library,
        pinGuard: _pinGuard!,
        onActivity: _onServerActivity,
        onPruneRequest: _onPruneRequest,
      );
      _server = server;
      await server.start();

      _addresses = await listLanAddresses();
      _startupError = null;
      await refreshDevices();
    } catch (error) {
      _startupError = '$error';
    } finally {
      _isStarting = false;
      notifyListeners();
    }
  }

  Future<void> refreshDevices() async {
    final library = _library;
    if (library == null || !library.rootExists) {
      _devices = const <BackupDeviceSummary>[];
      notifyListeners();
      return;
    }
    try {
      _devices = await library.listDevices();
      _startupError = null;
    } catch (error) {
      _devices = const <BackupDeviceSummary>[];
      _startupError = '$error';
    }
    notifyListeners();
  }

  /// Switches to a folder the user picked. The directory is created if needed —
  /// that is safe here precisely because it was an explicit choice, unlike the
  /// automatic fallback the library refuses to do.
  Future<void> changeRootDirectory(String path) async {
    final directory = Directory(path);
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
    await _settingsStore.saveRootPath(path);
    _rootDirectory = directory;
    final library = BackupLibrary(root: directory);
    _library = library;

    final pinGuard = _pinGuard ??= PinGuard();
    await _server?.stop();
    final server = BackupServer(
      library: library,
      pinGuard: pinGuard,
      onActivity: _onServerActivity,
      onPruneRequest: _onPruneRequest,
    );
    _server = server;
    await server.start();

    _log('Backup folder changed to $path');
    await refreshDevices();
  }

  String regeneratePin() {
    final replacement = _pinGuard?.regenerate() ?? '------';
    _log('PIN regenerated');
    notifyListeners();
    return replacement;
  }

  void dismissPrune() {
    _pendingPrune = null;
    notifyListeners();
  }

  /// Applies a prune the user explicitly confirmed. Never called automatically.
  Future<int> confirmPrune() async {
    final pending = _pendingPrune;
    final library = _library;
    if (pending == null || library == null) {
      return 0;
    }
    final deleted = await library.deleteDownloadFiles(
      deviceId: pending.deviceId,
      relativePaths: pending.entries.map((entry) => entry.path),
    );
    _pendingPrune = null;
    _log('Deleted $deleted stale file(s) for ${pending.deviceId}');
    await refreshDevices();
    return deleted;
  }

  void _onServerActivity(String message) {
    _hasServedAnyone = true;
    _log(message);
    // Device totals change on every upload; keep the summary honest without
    // making the user hit refresh.
    unawaited(refreshDevices());
  }

  void _onPruneRequest(PruneCandidates candidates) {
    _pendingPrune = candidates;
    notifyListeners();
  }

  void _log(String message) {
    final stamp = DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');
    _activity.insert(
      0,
      '${two(stamp.hour)}:${two(stamp.minute)}:${two(stamp.second)}  $message',
    );
    if (_activity.length > maxActivityEntries) {
      _activity.removeRange(maxActivityEntries, _activity.length);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    final server = _server;
    if (server != null) {
      unawaited(server.stop());
    }
    super.dispose();
  }
}
