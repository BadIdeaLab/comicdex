import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Desktop-side preferences. Only the chosen backup folder lives here — nothing
/// about the phone's data is stored outside the backup root itself.
class ServerSettingsStore {
  static const String _rootPathKey = 'backupRootPath';
  static const String defaultFolderName = 'ComicdexBackups';

  Future<String?> loadRootPath() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_rootPathKey);
    return (value == null || value.isEmpty) ? null : value;
  }

  Future<void> saveRootPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_rootPathKey, path);
  }

  /// `Documents/ComicdexBackups`, used only when the user has not picked a
  /// folder yet.
  Future<String> defaultRootPath() async {
    final documents = await getApplicationDocumentsDirectory();
    return p.join(documents.path, defaultFolderName);
  }

  /// Resolves the folder to use at startup, creating the default one on first
  /// run.
  ///
  /// A previously chosen folder is returned even when it is currently missing —
  /// the caller surfaces that as an error rather than silently relocating, since
  /// an empty-looking mirror would make the phone re-upload everything.
  Future<Directory> resolveRootDirectory() async {
    final saved = await loadRootPath();
    if (saved != null) {
      return Directory(saved);
    }
    final fallback = Directory(await defaultRootPath());
    if (!fallback.existsSync()) {
      await fallback.create(recursive: true);
    }
    await saveRootPath(fallback.path);
    return fallback;
  }
}
