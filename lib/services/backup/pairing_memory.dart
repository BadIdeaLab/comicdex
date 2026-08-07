import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// What was typed last time, so a familiar computer does not have to be
/// re-entered from scratch.
class RememberedPairing {
  const RememberedPairing({required this.address, required this.deviceName});

  /// As typed, e.g. `192.168.1.20:8787`.
  final String address;
  final String deviceName;
}

/// Remembers the address and device name of the last successful pairing.
///
/// **The PIN is deliberately not stored.** It changes every time the desktop app
/// restarts, so a saved one would usually be wrong — and re-entering it is the
/// step that proves the person holding the phone can also see the computer's
/// screen, which is the entire security model here. Saving it would quietly
/// turn pairing into "anything on this Wi-Fi that once connected, forever".
///
/// Stored as a file rather than in the drift database, because a restore
/// replaces that database wholesale: pairing details would be reverted to
/// whatever they were when the backup was taken, or lost entirely.
class PairingMemory {
  PairingMemory({required Future<Directory> Function() supportDirectory})
    : _supportDirectory = supportDirectory;

  static const String fileName = 'backup_pairing.json';

  final Future<Directory> Function() _supportDirectory;

  Future<File> _file() async {
    final support = await _supportDirectory();
    return File(p.join(support.path, fileName));
  }

  Future<RememberedPairing?> read() async {
    try {
      final file = await _file();
      if (!file.existsSync()) {
        return null;
      }
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, Object?>) {
        return null;
      }
      final address = decoded['address'];
      final deviceName = decoded['deviceName'];
      if (address is! String || address.isEmpty) {
        return null;
      }
      return RememberedPairing(
        address: address,
        deviceName: deviceName is String ? deviceName : '',
      );
    } on FormatException {
      return null;
    } on FileSystemException {
      return null;
    }
  }

  /// Called only after a pairing actually succeeds, so a mistyped address is
  /// never the one offered next time.
  Future<void> remember({
    required String address,
    required String deviceName,
  }) async {
    try {
      final file = await _file();
      await file.parent.create(recursive: true);
      await file.writeAsString(
        jsonEncode(<String, Object?>{
          'address': address,
          'deviceName': deviceName,
        }),
        flush: true,
      );
    } on FileSystemException {
      // Convenience only; failing to remember must never fail the pairing.
    }
  }
}
