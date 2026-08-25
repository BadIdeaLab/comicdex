import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/activity_event.dart';
import '../models/backup_models.dart';
import '../models/mobile_control.dart';
import '../server/backup_server.dart';
import '../server/pin_guard.dart';
import '../services/network_addresses.dart';
import '../services/pairing_payload.dart';
import '../storage/backup_library.dart';
import '../storage/server_config.dart';

/// Drives the whole desktop app: owns the library, the server, and everything
/// the UI renders.
class ServerModel extends ChangeNotifier {
  ServerModel({required ServerConfigStore configStore})
    : _configStore = configStore;

  static const int maxActivityEntries = 100;
  static const String defaultFolderName = 'ComicdexBackups';

  final ServerConfigStore _configStore;

  ServerConfig _config = const ServerConfig();

  ServerConfig get config => _config;

  BackupLibrary? _library;
  BackupServer? _server;
  PinGuard? _pinGuard;

  Directory? _rootDirectory;
  List<LanAddress> _addresses = const <LanAddress>[];
  List<BackupDeviceSummary> _devices = const <BackupDeviceSummary>[];
  final List<ActivityEvent> _activity = <ActivityEvent>[];
  PruneCandidates? _pendingPrune;
  String? _startupError;
  bool _isStarting = true;
  bool _hasServedAnyone = false;
  Timer? _activityNotifyTimer;
  final Map<String, MobileJobState> _lastControlStates =
      <String, MobileJobState>{};

  Directory? get rootDirectory => _rootDirectory;
  String get rootPath => _rootDirectory?.path ?? '';
  bool get rootExists => _rootDirectory?.existsSync() ?? false;
  List<LanAddress> get addresses => _addresses;
  List<BackupDeviceSummary> get devices => _devices;
  List<ConnectedMobileDevice> get connectedDevices =>
      _server?.connectedDevices ?? const <ConnectedMobileDevice>[];
  List<ActivityEvent> get activity =>
      List<ActivityEvent>.unmodifiable(_activity);
  PruneCandidates? get pendingPrune => _pendingPrune;
  String? get startupError => _startupError;
  bool get isStarting => _isStarting;
  bool get isRunning => _server?.isRunning ?? false;
  int? get port => _server?.port;
  String get pin => _pinGuard?.pin ?? '------';

  /// What the pairing QR encodes, or null when there is nothing to pair with.
  ///
  /// Carries *every* address rather than a chosen one: this machine cannot tell
  /// which of its interfaces a given phone can reach — a VPN endpoint and a
  /// Hyper-V switch look much like a real LAN card, while the mobile-hotspot
  /// adapter is "virtual" yet is exactly where a phone connects. The phone
  /// tries them in turn, which replaces guessing with finding out.
  String? get pairingUri {
    final activePort = port;
    if (activePort == null || _addresses.isEmpty || _pinGuard == null) {
      return null;
    }
    return buildPairingUri(
      pin: pin,
      addresses: <String>[
        for (final address in _addresses) '${address.address}:$activePort',
      ],
    );
  }

  List<String> get lockedOutAddresses =>
      _pinGuard?.lockedOutAddresses ?? const <String>[];

  /// True until a request has actually been served. The UI uses this to keep the
  /// Windows Firewall hint visible — an unapproved firewall prompt is by far the
  /// most common reason the phone "can't connect", and it looks identical to a
  /// wrong IP.
  bool get hasServedAnyone => _hasServedAnyone;

  /// Starts everything from an already-loaded [config] so the file is read once
  /// at launch and shared with [AppLocaleModel].
  Future<void> initialize(ServerConfig config) async {
    _isStarting = true;
    _config = config;
    notifyListeners();

    try {
      _rootDirectory = await _resolveRootDirectory(config);
      final library = BackupLibrary(
        root: _rootDirectory!,
        maxDbSnapshots: config.maxDbSnapshots,
      );
      _library = library;

      if (library.rootExists) {
        final removed = await library.cleanupPartFiles();
        if (removed > 0) {
          _log(PartFilesCleanedEvent(count: removed));
        }
      }

      _pinGuard = PinGuard();
      final server = BackupServer(
        library: library,
        pinGuard: _pinGuard!,
        onActivity: _onServerActivity,
        onPruneRequest: _onPruneRequest,
        onControlDevicesChanged: _onControlDevicesChanged,
      );
      _server = server;
      await server.start(preferredPort: config.port);

      _addresses = await listLanAddresses();
      _startPinRotation();
      _startupError = null;
      await refreshDevices();
    } catch (error) {
      _startupError = '$error';
    } finally {
      _isStarting = false;
      notifyListeners();
    }
  }

  /// What the toolbar's refresh button runs: re-scans the network adapters as
  /// well as the backup folder.
  ///
  /// Adapters can appear and disappear while the app is open — plugging in
  /// Ethernet, joining Wi-Fi, or turning on Windows' mobile hotspot (which adds
  /// a `192.168.137.1` adapter). Without rescanning, the only way to see a newly
  /// available address was to restart the app.
  ///
  /// Kept separate from [refreshDevices] on purpose: that one runs on transfer
  /// checkpoints, and enumerating interfaces there would put avoidable work back
  /// on the hot path this app already had to trim once.
  Future<void> refreshAll() async {
    _addresses = await listLanAddresses();
    await refreshDevices();
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

  /// Resolves the folder to back up into, creating the Documents default only
  /// on first run.
  ///
  /// A previously chosen folder is returned even when it is currently missing:
  /// [BackupLibrary] then reports it as unavailable, which is far safer than
  /// quietly relocating to an empty default the phone would read as "nothing
  /// backed up yet".
  Future<Directory> _resolveRootDirectory(ServerConfig config) async {
    final configured = config.backupRootPath;
    if (configured != null) {
      return Directory(configured);
    }
    final documents = await getApplicationDocumentsDirectory();
    final fallback = Directory(p.join(documents.path, defaultFolderName));
    if (!fallback.existsSync()) {
      await fallback.create(recursive: true);
    }
    await _persistConfig(_config.copyWith(backupRootPath: fallback.path));
    return fallback;
  }

  Future<void> _persistConfig(ServerConfig config) async {
    _config = config;
    await _configStore.save(config);
  }

  /// Switches to a folder the user picked. The directory is created if needed —
  /// that is safe here precisely because it was an explicit choice, unlike the
  /// automatic fallback the library refuses to do.
  Future<void> changeRootDirectory(String path) async {
    final directory = Directory(path);
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
    await _persistConfig(_config.copyWith(backupRootPath: path));
    _rootDirectory = directory;
    final library = BackupLibrary(
      root: directory,
      maxDbSnapshots: _config.maxDbSnapshots,
    );
    _library = library;

    final pinGuard = _pinGuard ??= PinGuard();
    await _server?.stop();
    final server = BackupServer(
      library: library,
      pinGuard: pinGuard,
      onActivity: _onServerActivity,
      onPruneRequest: _onPruneRequest,
      onControlDevicesChanged: _onControlDevicesChanged,
    );
    _server = server;
    await server.start(preferredPort: _config.port);

    _log(BackupFolderChangedEvent(path: path));
    await refreshDevices();
  }

  /// How long a displayed PIN and QR stay valid.
  static const Duration pinRotationInterval = Duration(seconds: 60);

  Timer? _pinRotationTimer;
  DateTime? _pinRotatesAt;

  /// Seconds until the PIN and QR change, or null when nothing is rotating.
  ///
  /// Surfaced so the countdown is visible: without it the code silently becomes
  /// a different code, and someone who photographed the screen has no way to
  /// know their picture just stopped working.
  int? get secondsUntilPinRotation {
    final rotatesAt = _pinRotatesAt;
    if (rotatesAt == null) return null;
    final remaining = rotatesAt.difference(DateTime.now()).inSeconds;
    return remaining < 0 ? 0 : remaining;
  }

  /// Rotates the PIN on a timer so a photographed QR stops working quickly.
  ///
  /// Safe for devices already paired: they authenticate with the session token
  /// issued at pairing, which [PinGuard.regenerate] deliberately leaves alone.
  /// Without that, this timer would guarantee a mid-transfer failure — a backup
  /// is dozens of requests spread over tens of minutes.
  void _startPinRotation() {
    _pinRotationTimer?.cancel();
    _pinRotatesAt = DateTime.now().add(pinRotationInterval);
    _pinRotationTimer = Timer.periodic(pinRotationInterval, (_) {
      _pinGuard?.regenerate();
      _pinRotatesAt = DateTime.now().add(pinRotationInterval);
      notifyListeners();
    });
    notifyListeners();
  }

  String regeneratePin() {
    // Restarts the clock: a code the user just replaced by hand should get the
    // full window, not whatever was left of the previous one.
    _startPinRotation();
    final replacement = _pinGuard?.regenerate() ?? '------';
    _log(PinRegeneratedEvent());
    notifyListeners();
    return replacement;
  }

  bool startBackup(String deviceId) {
    return _server?.sendControlCommand(
          deviceId,
          MobileControlAction.startBackup,
        ) ??
        false;
  }

  /// Tells [deviceId] to restore itself from [sourceDeviceId]'s backup.
  ///
  /// The two are often different: a replacement phone restores from the old
  /// one's partition, which is the whole reason backups are device-scoped.
  ///
  /// Only ever called after the confirmation dialog — the phone will delete
  /// local files it no longer needs, and that is not something to trigger from
  /// a single click.
  bool startRestore({
    required String deviceId,
    required String sourceDeviceId,
  }) {
    return _server?.sendControlCommand(
          deviceId,
          MobileControlAction.startRestore,
          sourceDeviceId: sourceDeviceId,
        ) ??
        false;
  }

  bool pauseBackup(String deviceId) {
    return _server?.sendControlCommand(deviceId, MobileControlAction.pause) ??
        false;
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
    _log(StaleFilesDeletedEvent(deviceId: pending.deviceId, count: deleted));
    await refreshDevices();
    return deleted;
  }

  void _onServerActivity(ActivityEvent event) {
    _hasServedAnyone = true;
    if (event is FileReceivedEvent || event is FileSentEvent) {
      // Large libraries can deliver hundreds of events per second. Rebuilding
      // the window and rescanning the complete backup tree for every page
      // starves scrolling, buttons, and the WebSocket command channel.
      _appendActivity(event);
      _activityNotifyTimer ??= Timer(const Duration(milliseconds: 150), () {
        _activityNotifyTimer = null;
        notifyListeners();
      });
      return;
    }
    _log(event);
    if (event is DatabaseStoredEvent) {
      unawaited(refreshDevices());
    }
  }

  void _onPruneRequest(PruneCandidates candidates) {
    _pendingPrune = candidates;
    notifyListeners();
  }

  void _onControlDevicesChanged() {
    _hasServedAnyone = true;
    var shouldRefreshDevices = false;
    final currentIds = <String>{};
    for (final device in connectedDevices) {
      currentIds.add(device.deviceId);
      final previous = _lastControlStates[device.deviceId];
      _lastControlStates[device.deviceId] = device.state;
      final reachedCheckpoint =
          device.state == MobileJobState.paused ||
          device.state == MobileJobState.completed ||
          device.state == MobileJobState.error;
      if (reachedCheckpoint && previous != device.state) {
        shouldRefreshDevices = true;
      }
    }
    _lastControlStates.removeWhere(
      (deviceId, _) => !currentIds.contains(deviceId),
    );
    notifyListeners();
    if (shouldRefreshDevices) {
      unawaited(refreshDevices());
    }
  }

  void _log(ActivityEvent event) {
    _appendActivity(event);
    notifyListeners();
  }

  void _appendActivity(ActivityEvent event) {
    _activity.insert(0, event);
    if (_activity.length > maxActivityEntries) {
      _activity.removeRange(maxActivityEntries, _activity.length);
    }
  }

  @override
  void dispose() {
    _activityNotifyTimer?.cancel();
    _pinRotationTimer?.cancel();
    final server = _server;
    if (server != null) {
      unawaited(server.stop());
    }
    super.dispose();
  }
}
