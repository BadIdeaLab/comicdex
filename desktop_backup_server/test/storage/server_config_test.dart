import 'dart:convert';
import 'dart:io';

import 'package:desktop_backup_server/storage/server_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ServerConfigStore', () {
    late Directory directory;
    late ServerConfigStore store;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('comicdex-config-test');
      store = ServerConfigStore(directory: directory);
    });

    tearDown(() async {
      if (directory.existsSync()) {
        await directory.delete(recursive: true);
      }
    });

    test('returns defaults when no config file exists yet', () async {
      final config = await store.load();

      expect(config.backupRootPath, isNull);
      expect(config.port, ServerConfig.defaultPort);
      expect(config.maxDbSnapshots, ServerConfig.defaultMaxDbSnapshots);
      expect(config.language, ServerConfig.defaultLanguage);
    });

    test('round-trips every setting', () async {
      await store.save(
        const ServerConfig(
          backupRootPath: r'E:\ProgramData\ComicdexBackups',
          port: 9000,
          maxDbSnapshots: 3,
          language: 'zh_Hant',
        ),
      );

      final reloaded = await store.load();
      expect(reloaded.backupRootPath, r'E:\ProgramData\ComicdexBackups');
      expect(reloaded.port, 9000);
      expect(reloaded.maxDbSnapshots, 3);
      expect(reloaded.language, 'zh_Hant');
    });

    test('writes readable, hand-editable JSON', () async {
      await store.save(const ServerConfig(backupRootPath: '/tmp/backups'));

      final raw = await store.file.readAsString();
      expect(raw, contains('\n'));
      expect(
        jsonDecode(raw),
        containsPair('backupRootPath', '/tmp/backups'),
      );
    });

    test(
      'survives a hand-edit that breaks the JSON instead of refusing to start',
      () async {
        await store.file.parent.create(recursive: true);
        await store.file.writeAsString('{ this is not json');

        final config = await store.load();
        expect(config.port, ServerConfig.defaultPort);
      },
    );

    test('falls back per-field for out-of-range or wrong-typed values', () async {
      await store.file.parent.create(recursive: true);
      await store.file.writeAsString(
        jsonEncode(<String, Object?>{
          'backupRootPath': '   ',
          'port': 99999,
          'maxDbSnapshots': 0,
          'language': 42,
        }),
      );

      final config = await store.load();
      expect(config.backupRootPath, isNull);
      expect(config.port, ServerConfig.defaultPort);
      expect(config.maxDbSnapshots, ServerConfig.defaultMaxDbSnapshots);
      expect(config.language, ServerConfig.defaultLanguage);
    });

    test(
      'the config path is chosen by us, not derived from executable metadata',
      () {
        // Regression guard for a real incident: settings used to live in
        // shared_preferences, which on Windows resolves under
        // %APPDATA%\<CompanyName>\<ProductName> taken from Runner.rc. Renaming
        // the app moved the store and orphaned the user's backup folder.
        final defaultStore = ServerConfigStore();
        expect(defaultStore.directory.path, contains(ServerConfigStore.folderName));
        expect(defaultStore.file.path, endsWith(ServerConfigStore.fileName));
      },
    );
  });

  group('ServerConfig', () {
    test('copyWith replaces only the named field', () {
      const original = ServerConfig(
        backupRootPath: '/a',
        port: 1234,
        maxDbSnapshots: 5,
        language: 'en',
      );

      final updated = original.copyWith(backupRootPath: '/b');

      expect(updated.backupRootPath, '/b');
      expect(updated.port, 1234);
      expect(updated.maxDbSnapshots, 5);
      expect(updated.language, 'en');
    });
  });
}
