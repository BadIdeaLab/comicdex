import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Everything the desktop app needs to remember between launches.
///
/// Kept as one small, human-readable JSON file rather than `shared_preferences`
/// after a real incident: on Windows, `shared_preferences` lives under
/// `%APPDATA%\<CompanyName>\<ProductName>\`, and both of those come from the
/// executable's version metadata (`windows/runner/Runner.rc`). Renaming the app
/// silently moved the store and orphaned the user's chosen backup folder — the
/// old file was still on disk, the app just could no longer find it.
///
/// Settings must not be tied to metadata that is expected to change, so
/// [ServerConfigStore] builds its own fixed path instead.
class ServerConfig {
  const ServerConfig({
    this.backupRootPath,
    this.port = defaultPort,
    this.maxDbSnapshots = defaultMaxDbSnapshots,
    this.language = defaultLanguage,
  });

  static const int defaultPort = 8787;
  static const int defaultMaxDbSnapshots = 10;
  static const String defaultLanguage = 'system';

  /// `null` means "not chosen yet"; the caller falls back to Documents.
  final String? backupRootPath;
  final int port;
  final int maxDbSnapshots;
  final String language;

  ServerConfig copyWith({
    String? backupRootPath,
    int? port,
    int? maxDbSnapshots,
    String? language,
  }) {
    return ServerConfig(
      backupRootPath: backupRootPath ?? this.backupRootPath,
      port: port ?? this.port,
      maxDbSnapshots: maxDbSnapshots ?? this.maxDbSnapshots,
      language: language ?? this.language,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'backupRootPath': backupRootPath,
      'port': port,
      'maxDbSnapshots': maxDbSnapshots,
      'language': language,
    };
  }

  /// Tolerant on purpose: this file is meant to be hand-editable, so a bad or
  /// missing value falls back to its default rather than refusing to start.
  factory ServerConfig.fromJson(Map<String, Object?> json) {
    final rawRoot = json['backupRootPath'];
    final rawPort = json['port'];
    final rawSnapshots = json['maxDbSnapshots'];
    final rawLanguage = json['language'];
    return ServerConfig(
      backupRootPath: (rawRoot is String && rawRoot.trim().isNotEmpty)
          ? rawRoot
          : null,
      port: (rawPort is int && rawPort >= 0 && rawPort <= 65535)
          ? rawPort
          : defaultPort,
      maxDbSnapshots: (rawSnapshots is int && rawSnapshots > 0)
          ? rawSnapshots
          : defaultMaxDbSnapshots,
      language: rawLanguage is String && rawLanguage.isNotEmpty
          ? rawLanguage
          : defaultLanguage,
    );
  }
}

/// Reads and writes [ServerConfig] as JSON at a stable, self-chosen location.
class ServerConfigStore {
  ServerConfigStore({Directory? directory}) : _directory = directory;

  static const String folderName = 'ComicdexBackupServer';
  static const String fileName = 'config.json';

  final Directory? _directory;

  /// `%APPDATA%\ComicdexBackupServer\` on Windows, `~/.comicdex-backup-server/`
  /// elsewhere.
  ///
  /// Built by hand rather than via `path_provider` precisely because
  /// `getApplicationSupportDirectory()` derives from the executable's metadata —
  /// the thing that broke settings once already.
  Directory get directory {
    final override = _directory;
    if (override != null) {
      return override;
    }
    final appData = Platform.environment['APPDATA'];
    if (appData != null && appData.isNotEmpty) {
      return Directory(p.join(appData, folderName));
    }
    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';
    return Directory(p.join(home, '.comicdex-backup-server'));
  }

  File get file => File(p.join(directory.path, fileName));

  Future<ServerConfig> load() async {
    final configFile = file;
    if (!configFile.existsSync()) {
      return const ServerConfig();
    }
    try {
      final decoded = jsonDecode(await configFile.readAsString());
      if (decoded is Map<String, Object?>) {
        return ServerConfig.fromJson(decoded);
      }
    } on FormatException {
      // Hand-edited into invalid JSON: fall back to defaults rather than
      // refusing to launch. The file is rewritten on the next save.
    } on FileSystemException {
      return const ServerConfig();
    }
    return const ServerConfig();
  }

  Future<void> save(ServerConfig config) async {
    final configFile = file;
    await configFile.parent.create(recursive: true);
    await configFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(config.toJson()),
    );
  }
}
