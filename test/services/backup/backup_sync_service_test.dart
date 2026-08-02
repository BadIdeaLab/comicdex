import 'dart:io';

import 'package:concept_nhv/services/backup/backup_connection.dart';
import 'package:concept_nhv/services/backup/backup_models.dart';
import 'package:concept_nhv/services/backup/backup_sync_service.dart';
import 'package:concept_nhv/services/download_asset_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../test_support/fakes/fake_backup_client.dart';
import '../../test_support/fixtures/sample_comic.dart';
import '../../test_support/storage/sqlite_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BackupSyncService', () {
    late SqliteTestHarness harness;
    late Directory downloadsRoot;
    late Directory tempRoot;
    late FakeBackupClient client;

    final connection = BackupConnection(
      baseUri: Uri.parse('http://127.0.0.1:8787'),
      pin: '123456',
      deviceId: 'Pixel-8',
    );

    setUp(() async {
      harness = SqliteTestHarness();
      await harness.initialize();
      tempRoot = await Directory.systemTemp.createTemp('nhv-backup-test');
      downloadsRoot = Directory(p.join(tempRoot.path, 'downloads'));
      await downloadsRoot.create(recursive: true);
      client = FakeBackupClient();
    });

    tearDown(() async {
      await harness.dispose();
      if (tempRoot.existsSync()) {
        await tempRoot.delete(recursive: true);
      }
    });

    Future<void> writeDownload(String relativePath, List<int> bytes) async {
      final file = File(p.join(downloadsRoot.path, relativePath));
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
    }

    BackupSyncService buildService() {
      return BackupSyncService(
        client: client,
        downloadAssetStore: DownloadAssetStore(
          directoryResolver: () async => downloadsRoot,
        ),
        downloadQueueRepository: harness.downloadQueueRepository,
        schemaVersion: 9,
        snapshotBuilder: () async {
          final snapshot = File(p.join(tempRoot.path, 'snapshot.db'));
          await snapshot.writeAsBytes(<int>[1, 2, 3]);
          return snapshot;
        },
      );
    }

    test(
      'uploads the database BEFORE scanning and sending files — the reverse '
      'order can record a page as complete whose file was never uploaded',
      () async {
        await writeDownload('177013/cover.webp', <int>[1, 2, 3]);

        await buildService().run(connection: connection);

        final databaseIndex = client.callLog.indexOf('database');
        final inventoryIndex = client.callLog.indexOf('inventory');
        final firstFileIndex = client.callLog.indexWhere(
          (entry) => entry.startsWith('file:'),
        );

        expect(databaseIndex, isNonNegative);
        expect(databaseIndex, lessThan(inventoryIndex));
        expect(databaseIndex, lessThan(firstFileIndex));
      },
    );

    test('checks health before doing any work', () async {
      client.healthError = StateError('unreachable');

      await expectLater(
        buildService().run(connection: connection),
        throwsA(isA<StateError>()),
      );

      expect(client.callLog, <String>['health']);
      expect(client.uploadedPaths, isEmpty);
    });

    test(
      'the skip policy uploads no snapshot but still compares and uploads '
      'files, and reports that it captured nothing',
      () async {
        await writeDownload('177013/cover.webp', <int>[1, 2, 3]);

        final result = await buildService().run(
          connection: connection,
          snapshotPolicy: DatabaseSnapshotPolicy.skip,
        );

        expect(client.callLog, isNot(contains('database')));
        expect(client.uploadedPaths, <String>['177013/cover.webp']);
        expect(result.databaseSnapshotUploaded, isFalse);
      },
    );

    test('the capture policy reports that the snapshot was uploaded', () async {
      final result = await buildService().run(connection: connection);

      expect(result.databaseSnapshotUploaded, isTrue);
    });

    test('sends the schema version with the database snapshot', () async {
      await buildService().run(connection: connection);

      expect(client.uploadedDatabaseSchemaVersions, <int>[9]);
    });

    test('uploads only what the server is missing', () async {
      await writeDownload('177013/cover.webp', <int>[1, 2, 3]);
      await writeDownload('177013/pages/1.webp', <int>[4, 5]);
      client.inventory = <String, int>{'177013/cover.webp': 3};

      final result = await buildService().run(connection: connection);

      expect(client.uploadedPaths, <String>['177013/pages/1.webp']);
      expect(result.uploadedCount, 1);
      expect(result.skippedCount, 1);
    });

    test('a second run with nothing new uploads nothing', () async {
      await writeDownload('177013/cover.webp', <int>[1, 2, 3]);
      client.inventory = <String, int>{'177013/cover.webp': 3};

      final result = await buildService().run(connection: connection);

      expect(client.uploadedPaths, isEmpty);
      expect(result.uploadedCount, 0);
      expect(result.skippedCount, 1);
    });

    test(
      'one failed file does not abandon the rest, and is reported',
      () async {
        await writeDownload('177013/cover.webp', <int>[1]);
        await writeDownload('177013/pages/1.webp', <int>[2]);
        await writeDownload('177013/pages/2.webp', <int>[3]);
        client.failUploadsFor = <String>{'177013/pages/1.webp'};

        final result = await buildService().run(connection: connection);

        expect(client.uploadedPaths, <String>[
          '177013/cover.webp',
          '177013/pages/2.webp',
        ]);
        expect(result.uploadedCount, 2);
        expect(result.failedCount, 1);
        expect(result.failures.single, contains('177013/pages/1.webp'));
      },
    );

    test('skips files belonging to downloads still in progress, because a page '
        'being written right now would hash and upload truncated', () async {
      final comic = sampleComic(id: '900', mediaId: '321');
      await harness.downloadQueueRepository.upsertJobManifest(
        comic: comic,
        title: 'In progress',
      );
      await writeDownload('900/pages/1.webp', <int>[1, 2]);
      await writeDownload('177013/cover.webp', <int>[3, 4]);

      final result = await buildService().run(connection: connection);

      expect(client.uploadedPaths, <String>['177013/cover.webp']);
      expect(result.skippedInFlightCount, 1);
    });

    test('includes files of downloads that have completed', () async {
      final comic = sampleComic(id: '900', mediaId: '321');
      await harness.downloadQueueRepository.upsertJobManifest(
        comic: comic,
        title: 'Finished',
      );
      await harness.downloadQueueRepository.markJobCompleted('900');
      await writeDownload('900/pages/1.webp', <int>[1, 2]);

      final result = await buildService().run(connection: connection);

      expect(client.uploadedPaths, <String>['900/pages/1.webp']);
      expect(result.skippedInFlightCount, 0);
    });

    test(
      'reports real progress because the work list is known up front',
      () async {
        await writeDownload('177013/cover.webp', <int>[1]);
        await writeDownload('177013/pages/1.webp', <int>[2]);

        final stages = <BackupSyncStage>[];
        double? finalFraction;
        await buildService().run(
          connection: connection,
          onProgress: (progress) {
            stages.add(progress.stage);
            if (progress.stage == BackupSyncStage.done) {
              finalFraction = progress.fraction;
            }
          },
        );

        expect(stages.first, BackupSyncStage.connecting);
        expect(stages, contains(BackupSyncStage.snapshottingDatabase));
        expect(stages, contains(BackupSyncStage.uploading));
        expect(stages.last, BackupSyncStage.done);
        expect(finalFraction, 1.0);
      },
    );

    test('deletes the temporary database snapshot after uploading', () async {
      await buildService().run(connection: connection);

      expect(File(p.join(tempRoot.path, 'snapshot.db')).existsSync(), isFalse);
    });

    test('handles an empty downloads folder', () async {
      final result = await buildService().run(connection: connection);

      expect(result.uploadedCount, 0);
      expect(result.failedCount, 0);
      expect(client.uploadedDatabaseSchemaVersions, hasLength(1));
    });

    test(
      'pause stops before the next file and keeps the database snapshot',
      () async {
        await writeDownload('177013/cover.webp', <int>[1]);
        await writeDownload('177013/pages/1.webp', <int>[2]);
        final pauseToken = BackupPauseToken()..requestPause();

        final result = await buildService().run(
          connection: connection,
          pauseToken: pauseToken,
        );

        expect(result.isPaused, isTrue);
        expect(client.uploadedDatabaseSchemaVersions, hasLength(1));
        expect(client.uploadedPaths, isEmpty);
      },
    );
  });

  group('BackupConnection.parseAddress', () {
    test('parses host:port', () {
      final uri = BackupConnection.parseAddress('192.168.50.72:6890');
      expect(uri.toString(), 'http://192.168.50.72:6890');
    });

    test('applies the default port when omitted', () {
      final uri = BackupConnection.parseAddress('192.168.50.72');
      expect(uri!.port, 8787);
    });

    test('tolerates a pasted http:// prefix and trailing path', () {
      final uri = BackupConnection.parseAddress('http://192.168.50.72:6890/');
      expect(uri.toString(), 'http://192.168.50.72:6890');
    });

    test('rejects https, empty, and malformed ports', () {
      expect(BackupConnection.parseAddress('https://192.168.50.72'), isNull);
      expect(BackupConnection.parseAddress('   '), isNull);
      expect(BackupConnection.parseAddress('192.168.50.72:abc'), isNull);
      expect(BackupConnection.parseAddress('192.168.50.72:99999'), isNull);
    });
  });
}
