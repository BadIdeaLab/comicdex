import 'dart:io';

import 'package:concept_nhv/services/backup/backup_connection.dart';
import 'package:concept_nhv/services/backup/backup_models.dart';
import 'package:concept_nhv/services/backup/backup_restore_service.dart';
import 'package:concept_nhv/services/backup/pending_restore_applier.dart';
import 'package:concept_nhv/services/backup/restore_models.dart';
import 'package:concept_nhv/services/backup/restore_progress_flag.dart';
import 'package:concept_nhv/services/download_asset_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../test_support/fakes/fake_backup_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BackupRestoreService', () {
    late Directory support;
    late Directory downloads;
    late FakeBackupClient client;
    late List<String?> databasePaths;

    final connection = BackupConnection(
      baseUri: Uri.parse('http://127.0.0.1:8787'),
      pin: '123456',
      deviceId: 'New-Phone',
    );

    setUp(() async {
      support = await Directory.systemTemp.createTemp('nhv-restore-test');
      downloads = Directory(p.join(support.path, 'downloads'));
      await downloads.create(recursive: true);
      client = FakeBackupClient();
      databasePaths = <String?>[];
    });

    tearDown(() async {
      if (support.existsSync()) {
        await support.delete(recursive: true);
      }
    });

    BackupRestoreService buildService({int appSchemaVersion = 9}) {
      return BackupRestoreService(
        client: client,
        downloadAssetStore: DownloadAssetStore(
          directoryResolver: () async => downloads,
        ),
        appSchemaVersion: appSchemaVersion,
        databaseReader: (_) async => databasePaths,
        supportDirectory: () async => support,
      );
    }

    Future<void> writeLocal(String relativePath, List<int> bytes) async {
      final file = File(p.join(downloads.path, relativePath));
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
    }

    bool localExists(String relativePath) =>
        File(p.join(downloads.path, relativePath)).existsSync();

    group('preflight — nothing local may change until every check passes', () {
      test('refuses a backup made by a newer app version', () async {
        client.inventory = <String, int>{'177013/cover.webp': 3};
        client.remoteDatabaseSchemaVersion = 10;
        await writeLocal('existing/keep.webp', <int>[9, 9]);

        await expectLater(
          buildService(appSchemaVersion: 9).run(
            connection: connection,
            sourceDeviceId: 'Old-Phone',
          ),
          throwsA(
            isA<RestoreBlockedException>().having(
              (e) => e.reason,
              'reason',
              RestoreBlockedReason.backupIsNewer,
            ),
          ),
        );

        // The decisive assertion: the user's existing library is intact.
        expect(localExists('existing/keep.webp'), isTrue);
      });

      test('refuses a source with no files at all', () async {
        client.inventory = const <String, int>{};
        await writeLocal('existing/keep.webp', <int>[9, 9]);

        await expectLater(
          buildService().run(
            connection: connection,
            sourceDeviceId: 'Old-Phone',
          ),
          throwsA(isA<RestoreBlockedException>()),
        );
        expect(localExists('existing/keep.webp'), isTrue);
      });

      test('checks health before anything else', () async {
        client.healthError = StateError('unreachable');

        await expectLater(
          buildService().run(
            connection: connection,
            sourceDeviceId: 'Old-Phone',
          ),
          throwsA(isA<StateError>()),
        );
        expect(client.callLog, <String>['health']);
      });

      test('accepts a backup at or below the app schema version', () async {
        client.inventory = <String, int>{'177013/cover.webp': 3};
        client.remoteFiles = <String, List<int>>{
          '177013/cover.webp': <int>[1, 2, 3],
        };
        client.remoteDatabaseSchemaVersion = 8;
        databasePaths = <String?>['177013/cover.webp'];

        final result = await buildService(appSchemaVersion: 9).run(
          connection: connection,
          sourceDeviceId: 'Old-Phone',
        );

        expect(result.downloadedCount, 1);
      });
    });

    group('planning', () {
      test('downloads what is missing and keeps what already matches', () async {
        await writeLocal('177013/cover.webp', <int>[1, 2, 3]);
        client.inventory = <String, int>{
          '177013/cover.webp': 3,
          '177013/pages/1.webp': 2,
        };
        client.remoteFiles = <String, List<int>>{
          '177013/pages/1.webp': <int>[4, 5],
        };
        databasePaths = <String?>['177013/cover.webp', '177013/pages/1.webp'];

        final result = await buildService().run(
          connection: connection,
          sourceDeviceId: 'Old-Phone',
        );

        expect(client.downloadedPaths, <String>['177013/pages/1.webp']);
        expect(result.keptCount, 1);
        expect(localExists('177013/cover.webp'), isTrue);
      });

      test(
        'deletes local files the restored database does not reference, and does '
        'so before downloading so their space is available',
        () async {
          await writeLocal('999999/cover.webp', <int>[7, 7, 7]);
          client.inventory = <String, int>{'177013/cover.webp': 3};
          client.remoteFiles = <String, List<int>>{
            '177013/cover.webp': <int>[1, 2, 3],
          };
          databasePaths = <String?>['177013/cover.webp'];

          final result = await buildService().run(
            connection: connection,
            sourceDeviceId: 'Old-Phone',
          );

          expect(localExists('999999/cover.webp'), isFalse);
          expect(result.deletedCount, 1);
          // Deletion precedes the first download in the call order.
          expect(localExists('177013/cover.webp'), isTrue);
        },
      );

      test(
        'restores legacy absolute paths recorded by older app versions',
        () async {
          client.inventory = <String, int>{'287290/cover.webp': 3};
          client.remoteFiles = <String, List<int>>{
            '287290/cover.webp': <int>[1, 2, 3],
          };
          databasePaths = <String?>[
            '/var/mobile/Containers/Data/Application/OLD-UUID/Library/'
                'Application Support/downloads/287290/cover.webp',
          ];

          await buildService().run(
            connection: connection,
            sourceDeviceId: 'Old-Phone',
          );

          expect(client.downloadedPaths, <String>['287290/cover.webp']);
        },
      );

      test('sweeps leftover .part files instead of counting them', () async {
        await writeLocal('177013/cover.webp.part', <int>[0]);
        client.inventory = <String, int>{'177013/cover.webp': 3};
        client.remoteFiles = <String, List<int>>{
          '177013/cover.webp': <int>[1, 2, 3],
        };
        databasePaths = <String?>['177013/cover.webp'];

        await buildService().run(
          connection: connection,
          sourceDeviceId: 'Old-Phone',
        );

        expect(localExists('177013/cover.webp.part'), isFalse);
        expect(localExists('177013/cover.webp'), isTrue);
      });
    });

    group('the database is the commit point', () {
      Future<File> pendingFile() async =>
          File(p.join(support.path, kPendingRestoreDirName, kPendingRestoreDbName));

      test('stages the database only after every file arrived', () async {
        client.inventory = <String, int>{'177013/cover.webp': 3};
        client.remoteFiles = <String, List<int>>{
          '177013/cover.webp': <int>[1, 2, 3],
        };
        databasePaths = <String?>['177013/cover.webp'];

        final result = await buildService().run(
          connection: connection,
          sourceDeviceId: 'Old-Phone',
        );

        expect(result.databaseStaged, isTrue);
        expect((await pendingFile()).existsSync(), isTrue);
      });

      test(
        'a failed file leaves the database unstaged, so the next launch still '
        'boots the old one and the restore can simply be re-run',
        () async {
          client.inventory = <String, int>{
            'ok/1.webp': 1,
            'broken/2.webp': 1,
          };
          client.remoteFiles = <String, List<int>>{'ok/1.webp': <int>[1]};
          databasePaths = <String?>['ok/1.webp', 'broken/2.webp'];

          final result = await buildService().run(
            connection: connection,
            sourceDeviceId: 'Old-Phone',
          );

          expect(result.failedCount, 1);
          expect(result.databaseStaged, isFalse);
          expect((await pendingFile()).existsSync(), isFalse);
        },
      );

      test(
        'a run that does not commit leaves no multi-megabyte snapshot behind',
        () async {
          client.inventory = <String, int>{'broken/1.webp': 1};
          client.remoteFiles = const <String, List<int>>{};
          databasePaths = <String?>['broken/1.webp'];

          final result = await buildService().run(
            connection: connection,
            sourceDeviceId: 'Old-Phone',
          );

          expect(result.databaseStaged, isFalse);
          final staging = File(
            p.join(support.path, kPendingRestoreDirName, 'incoming.db'),
          );
          expect(staging.existsSync(), isFalse);
        },
      );

      test('a pause leaves the database unstaged', () async {
        client.inventory = <String, int>{'a/1.webp': 1, 'a/2.webp': 1};
        client.remoteFiles = <String, List<int>>{
          'a/1.webp': <int>[1],
          'a/2.webp': <int>[2],
        };
        databasePaths = <String?>['a/1.webp', 'a/2.webp'];
        final token = BackupPauseToken()..requestPause();

        final result = await buildService().run(
          connection: connection,
          sourceDeviceId: 'Old-Phone',
          pauseToken: token,
        );

        expect(result.isPaused, isTrue);
        expect(result.databaseStaged, isFalse);
        expect((await pendingFile()).existsSync(), isFalse);
      });
    });

    group('interrupted-restore flag', () {
      RestoreProgressFlag flag() =>
          RestoreProgressFlag(supportDirectory: () async => support);

      test('is not raised when the preflight refuses', () async {
        client.inventory = <String, int>{'a/1.webp': 1};
        client.remoteDatabaseSchemaVersion = 99;

        await expectLater(
          buildService().run(
            connection: connection,
            sourceDeviceId: 'Old-Phone',
          ),
          throwsA(isA<RestoreBlockedException>()),
        );

        expect(await flag().read(), isNull);
      });

      test('is cleared once the database is staged', () async {
        client.inventory = <String, int>{'a/1.webp': 1};
        client.remoteFiles = <String, List<int>>{'a/1.webp': <int>[1]};
        databasePaths = <String?>['a/1.webp'];

        final result = await buildService().run(
          connection: connection,
          sourceDeviceId: 'Old-Phone',
        );

        expect(result.databaseStaged, isTrue);
        expect(await flag().read(), isNull);
      });

      test(
        'survives a failed run, because the library on disk no longer matches '
        'the database the app would boot',
        () async {
          client.inventory = <String, int>{'broken/1.webp': 1};
          client.remoteFiles = const <String, List<int>>{};
          databasePaths = <String?>['broken/1.webp'];

          final result = await buildService().run(
            connection: connection,
            sourceDeviceId: 'Old-Phone',
          );

          expect(result.databaseStaged, isFalse);
          final interrupted = await flag().read();
          expect(interrupted, isNotNull);
          expect(interrupted!.sourceDeviceId, 'Old-Phone');
        },
      );

      test('survives a pause', () async {
        client.inventory = <String, int>{'a/1.webp': 1};
        client.remoteFiles = <String, List<int>>{'a/1.webp': <int>[1]};
        databasePaths = <String?>['a/1.webp'];

        await buildService().run(
          connection: connection,
          sourceDeviceId: 'Old-Phone',
          pauseToken: BackupPauseToken()..requestPause(),
        );

        expect(await flag().read(), isNotNull);
      });
    });

    group('progress', () {
      test('reports stages in order and ends at done', () async {
        client.inventory = <String, int>{'a/1.webp': 1};
        client.remoteFiles = <String, List<int>>{'a/1.webp': <int>[1]};
        databasePaths = <String?>['a/1.webp'];

        final stages = <RestoreStage>[];
        await buildService().run(
          connection: connection,
          sourceDeviceId: 'Old-Phone',
          onProgress: (progress) => stages.add(progress.stage),
        );

        expect(stages.first, RestoreStage.checking);
        expect(stages, containsAllInOrder(<RestoreStage>[
          RestoreStage.checking,
          RestoreStage.planning,
          RestoreStage.clearing,
          RestoreStage.downloading,
          RestoreStage.applying,
          RestoreStage.done,
        ]));
      });
    });
  });

  group('applyPendingRestore', () {
    late Directory support;
    late File database;

    setUp(() async {
      support = await Directory.systemTemp.createTemp('nhv-pending-test');
      database = File(p.join(support.path, 'db', 'database.db'));
      await database.parent.create(recursive: true);
      await database.writeAsBytes(<int>[0, 0, 0]);
    });

    tearDown(() async {
      if (support.existsSync()) {
        await support.delete(recursive: true);
      }
    });

    Future<PendingRestoreOutcome> apply() {
      return applyPendingRestore(
        supportDirectory: () async => support,
        databasePath: () async => database.path,
      );
    }

    Future<File> writePending(List<int> bytes) async {
      final pending = File(
        p.join(support.path, kPendingRestoreDirName, kPendingRestoreDbName),
      );
      await pending.parent.create(recursive: true);
      await pending.writeAsBytes(bytes);
      return pending;
    }

    test('does nothing when no restore is pending', () async {
      expect(await apply(), PendingRestoreOutcome.none);
      expect(await database.readAsBytes(), <int>[0, 0, 0]);
    });

    test('swaps in the staged database and clears the staging slot', () async {
      final pending = await writePending(<int>[1, 2, 3]);

      expect(await apply(), PendingRestoreOutcome.applied);
      expect(await database.readAsBytes(), <int>[1, 2, 3]);
      expect(pending.existsSync(), isFalse);
    });

    test(
      'removes sqlite side files, which describe the replaced database and '
      'would otherwise corrupt the new one',
      () async {
        await writePending(<int>[1, 2, 3]);
        for (final suffix in const <String>['-wal', '-shm', '-journal']) {
          await File('${database.path}$suffix').writeAsBytes(<int>[9]);
        }

        expect(await apply(), PendingRestoreOutcome.applied);
        for (final suffix in const <String>['-wal', '-shm', '-journal']) {
          expect(File('${database.path}$suffix').existsSync(), isFalse);
        }
      },
    );

    test('is idempotent — a second launch finds nothing to do', () async {
      await writePending(<int>[1, 2, 3]);

      expect(await apply(), PendingRestoreOutcome.applied);
      expect(await apply(), PendingRestoreOutcome.none);
      expect(await database.readAsBytes(), <int>[1, 2, 3]);
    });

    test(
      'finishes a swap interrupted after the staged snapshot was consumed',
      () async {
        // The state left by a crash between "pending consumed" and "database
        // replaced": no pending file, but a handover file waiting.
        await File(
          '${database.path}$kRestoreHandoverSuffix',
        ).writeAsBytes(<int>[4, 5, 6]);

        expect(await apply(), PendingRestoreOutcome.applied);
        expect(await database.readAsBytes(), <int>[4, 5, 6]);
        expect(
          File('${database.path}$kRestoreHandoverSuffix').existsSync(),
          isFalse,
        );
      },
    );

    test(
      'never applies the same snapshot twice — the staged file is consumed '
      'before the database is touched, so a later failure cannot silently roll '
      'the user back to the restore point',
      () async {
        final pending = await writePending(<int>[1, 2, 3]);
        expect(await apply(), PendingRestoreOutcome.applied);
        expect(pending.existsSync(), isFalse);

        // Simulate the app being used after the restore.
        await database.writeAsBytes(<int>[7, 7, 7]);

        expect(await apply(), PendingRestoreOutcome.none);
        expect(await database.readAsBytes(), <int>[7, 7, 7]);
      },
    );
  });
}
