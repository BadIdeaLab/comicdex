import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:desktop_backup_server/models/backup_models.dart';
import 'package:desktop_backup_server/storage/backup_exceptions.dart';
import 'package:desktop_backup_server/storage/backup_library.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('BackupLibrary', () {
    late Directory root;
    late BackupLibrary library;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('comicdex-backup-test');
      library = BackupLibrary(root: root);
    });

    tearDown(() async {
      if (root.existsSync()) {
        await root.delete(recursive: true);
      }
    });

    Future<void> put(String deviceId, String path, List<int> bytes) {
      return library.writeDownloadFile(
        deviceId: deviceId,
        relativePath: path,
        source: Stream<List<int>>.value(bytes),
        expectedSha256: sha256.convert(bytes).toString(),
      );
    }

    group('device id validation', () {
      test('accepts ordinary names', () {
        expect(BackupLibrary.validateDeviceId('Pixel-8'), 'Pixel-8');
        expect(BackupLibrary.validateDeviceId('  iPad Air '), 'iPad Air');
      });

      test(
        'accepts an iOS model identifier, which contains a comma — rejecting '
        'it made the WebSocket upgrade 400 and surfaced as "cannot reach '
        'this computer"',
        () {
          expect(
            BackupLibrary.validateDeviceId('iPad iPad13,16'),
            'iPad iPad13,16',
          );
          expect(
            BackupLibrary.validateDeviceId('iPhone16,2 (Pro Max)'),
            'iPhone16,2 (Pro Max)',
          );
        },
      );

      test('rejects names that could escape the backup root', () {
        for (final bad in <String?>[
          null,
          '',
          '   ',
          '..',
          '.',
          'a/b',
          'a,b/c',
          r'a\b',
          '../evil',
        ]) {
          expect(
            () => BackupLibrary.validateDeviceId(bad),
            throwsA(isA<InvalidBackupPathException>()),
            reason: 'should reject $bad',
          );
        }
      });
    });

    group('path traversal', () {
      test('rejects paths that climb out of the downloads root', () {
        for (final bad in <String>[
          '../../secret.txt',
          'a/../../secret.txt',
          '/etc/passwd',
          r'a\..\..\secret.txt',
          '',
          'a//b',
        ]) {
          expect(
            () => library.resolveDownloadFile('Pixel-8', bad),
            throwsA(isA<InvalidBackupPathException>()),
            reason: 'should reject $bad',
          );
        }
      });

      test('accepts the app\'s real download layout', () {
        final file = library.resolveDownloadFile('Pixel-8', '177013/pages/1.webp');
        expect(p.isWithin(root.path, file.path), isTrue);
      });
    });

    group('writeDownloadFile', () {
      test('stores the file and reports it in the inventory', () async {
        await put('Pixel-8', '177013/cover.webp', <int>[1, 2, 3, 4]);

        final entries = await library.inventory('Pixel-8');
        expect(entries, hasLength(1));
        expect(entries.single.path, '177013/cover.webp');
        expect(entries.single.sizeBytes, 4);
      });

      test(
        'a checksum mismatch leaves nothing behind, so a later inventory never '
        'reports a corrupt file as already present',
        () async {
          await expectLater(
            library.writeDownloadFile(
              deviceId: 'Pixel-8',
              relativePath: '177013/cover.webp',
              source: Stream<List<int>>.value(<int>[1, 2, 3]),
              expectedSha256: sha256.convert(<int>[9, 9, 9]).toString(),
            ),
            throwsA(isA<DigestMismatchException>()),
          );

          expect(await library.inventory('Pixel-8'), isEmpty);
          final target = library.resolveDownloadFile(
            'Pixel-8',
            '177013/cover.webp',
          );
          expect(target.existsSync(), isFalse);
          expect(File('${target.path}$kPartSuffix').existsSync(), isFalse);
        },
      );

      test('overwrites an existing file when re-uploaded', () async {
        await put('Pixel-8', '177013/cover.webp', <int>[1, 2, 3]);
        await put('Pixel-8', '177013/cover.webp', <int>[7, 7, 7, 7, 7]);

        final entries = await library.inventory('Pixel-8');
        expect(entries.single.sizeBytes, 5);
      });

      test('keeps devices completely isolated from each other', () async {
        await put('Pixel-8', '177013/cover.webp', <int>[1]);
        await put('iPad-Air', '999999/cover.webp', <int>[2]);

        expect(
          (await library.inventory('Pixel-8')).map((e) => e.path),
          <String>['177013/cover.webp'],
        );
        expect(
          (await library.inventory('iPad-Air')).map((e) => e.path),
          <String>['999999/cover.webp'],
        );
      });
    });

    group('inventory', () {
      test('is empty for an unknown device', () async {
        expect(await library.inventory('Nothing-Here'), isEmpty);
      });

      test('skips in-flight .part files', () async {
        await put('Pixel-8', '177013/cover.webp', <int>[1]);
        final stray = File(
          p.join(
            library.downloadsDirectory('Pixel-8').path,
            '177013',
            'pages',
            '1.webp$kPartSuffix',
          ),
        );
        await stray.parent.create(recursive: true);
        await stray.writeAsBytes(<int>[0, 0]);

        final paths = (await library.inventory('Pixel-8')).map((e) => e.path);
        expect(paths, <String>['177013/cover.webp']);
      });
    });

    group('database snapshots', () {
      Future<DbSnapshotInfo> putDb(String deviceId, List<int> bytes, int schema) {
        return library.writeDbSnapshot(
          deviceId: deviceId,
          gzippedSource: Stream<List<int>>.value(gzip.encode(bytes)),
          expectedSha256: sha256.convert(bytes).toString(),
          schemaVersion: schema,
        );
      }

      test('stores decompressed content and records the schema version', () async {
        final payload = utf8.encode('fake sqlite bytes');
        final info = await putDb('Pixel-8', payload, 9);

        expect(info.schemaVersion, 9);
        final stored = library.dbSnapshotFile('Pixel-8', info.filename);
        expect(await stored.readAsBytes(), Uint8List.fromList(payload));
      });

      test('rejects a snapshot whose digest does not match', () async {
        await expectLater(
          library.writeDbSnapshot(
            deviceId: 'Pixel-8',
            gzippedSource: Stream<List<int>>.value(gzip.encode(<int>[1, 2, 3])),
            expectedSha256: sha256.convert(<int>[4, 5, 6]).toString(),
            schemaVersion: 9,
          ),
          throwsA(isA<DigestMismatchException>()),
        );
        expect(await library.listDbSnapshots('Pixel-8'), isEmpty);
      });

      test('lists newest first and exposes the newest as latest', () async {
        await putDb('Pixel-8', utf8.encode('one'), 8);
        await putDb('Pixel-8', utf8.encode('two'), 9);

        final snapshots = await library.listDbSnapshots('Pixel-8');
        expect(snapshots, hasLength(2));
        expect(snapshots.first.createdAt.isAfter(snapshots.last.createdAt), isTrue);
        expect((await library.latestDbSnapshot('Pixel-8'))!.schemaVersion, 9);
      });

      test('drops the oldest snapshots beyond the retention limit', () async {
        final limited = BackupLibrary(root: root, maxDbSnapshots: 3);
        for (var i = 0; i < 5; i++) {
          await limited.writeDbSnapshot(
            deviceId: 'Pixel-8',
            gzippedSource: Stream<List<int>>.value(gzip.encode(<int>[i])),
            expectedSha256: sha256.convert(<int>[i]).toString(),
            schemaVersion: 9,
          );
        }
        expect(await limited.listDbSnapshots('Pixel-8'), hasLength(3));
      });

      test('records lastSyncAt on the device summary', () async {
        await putDb('Pixel-8', utf8.encode('one'), 9);
        final summary = await library.describeDevice('Pixel-8');

        expect(summary.lastSyncAt, isNotNull);
        expect(summary.latestDbSchemaVersion, 9);
        expect(summary.dbSnapshotCount, 1);
      });
    });

    group('listDevices', () {
      test('summarises each device partition', () async {
        await put('Pixel-8', '177013/cover.webp', <int>[1, 2, 3]);
        await put('Pixel-8', '177013/pages/1.webp', <int>[4, 5]);
        await put('iPad-Air', '999999/cover.webp', <int>[6]);

        final devices = await library.listDevices();
        expect(devices.map((d) => d.deviceId), <String>['Pixel-8', 'iPad-Air']..sort());

        final pixel = devices.firstWhere((d) => d.deviceId == 'Pixel-8');
        expect(pixel.fileCount, 2);
        expect(pixel.totalBytes, 5);
      });
    });

    group('prune', () {
      test('reports only files the phone no longer has, and deletes nothing '
          'until asked', () async {
        await put('Pixel-8', '177013/cover.webp', <int>[1]);
        await put('Pixel-8', '999999/cover.webp', <int>[2, 2]);

        final candidates = await library.pruneCandidates(
          deviceId: 'Pixel-8',
          phonePaths: <String>{'177013/cover.webp'},
        );

        expect(candidates.entries.map((e) => e.path), <String>[
          '999999/cover.webp',
        ]);
        expect(candidates.totalBytes, 2);
        // Still on disk: computing candidates must never delete.
        expect(await library.inventory('Pixel-8'), hasLength(2));
      });

      test('deletes confirmed files and cleans up emptied folders', () async {
        await put('Pixel-8', '177013/cover.webp', <int>[1]);
        await put('Pixel-8', '999999/cover.webp', <int>[2]);

        final deleted = await library.deleteDownloadFiles(
          deviceId: 'Pixel-8',
          relativePaths: <String>['999999/cover.webp'],
        );

        expect(deleted, 1);
        expect((await library.inventory('Pixel-8')).map((e) => e.path), <String>[
          '177013/cover.webp',
        ]);
        expect(
          Directory(
            p.join(library.downloadsDirectory('Pixel-8').path, '999999'),
          ).existsSync(),
          isFalse,
        );
        // The downloads root itself must survive so later syncs still work.
        expect(library.downloadsDirectory('Pixel-8').existsSync(), isTrue);
      });
    });

    group('startup maintenance', () {
      test('cleans up .part leftovers from interrupted transfers', () async {
        await put('Pixel-8', '177013/cover.webp', <int>[1]);
        final stray = File(
          '${library.resolveDownloadFile('Pixel-8', '177013/pages/1.webp').path}'
          '$kPartSuffix',
        );
        await stray.parent.create(recursive: true);
        await stray.writeAsBytes(<int>[0]);

        expect(await library.cleanupPartFiles(), 1);
        expect(stray.existsSync(), isFalse);
        expect(await library.inventory('Pixel-8'), hasLength(1));
      });
    });

    group('missing backup root', () {
      test(
        'fails loudly instead of silently recreating it — a silent empty '
        'mirror would make the phone re-upload its entire library',
        () async {
          await put('Pixel-8', '177013/cover.webp', <int>[1]);
          await root.delete(recursive: true);

          expect(library.rootExists, isFalse);
          expect(
            () => library.ensureRootAvailable(),
            throwsA(isA<BackupRootUnavailableException>()),
          );
          await expectLater(
            library.listDevices(),
            throwsA(isA<BackupRootUnavailableException>()),
          );
          expect(root.existsSync(), isFalse);
        },
      );
    });

    group('persistence across restarts', () {
      test('a fresh library instance sees everything the old one stored', () async {
        await put('Pixel-8', '177013/cover.webp', <int>[1, 2, 3]);
        await library.writeDbSnapshot(
          deviceId: 'Pixel-8',
          gzippedSource: Stream<List<int>>.value(gzip.encode(<int>[9])),
          expectedSha256: sha256.convert(<int>[9]).toString(),
          schemaVersion: 9,
        );

        final reopened = BackupLibrary(root: Directory(root.path));
        final devices = await reopened.listDevices();

        expect(devices, hasLength(1));
        expect(devices.single.fileCount, 1);
        expect(devices.single.latestDbSchemaVersion, 9);
        expect(devices.single.lastSyncAt, isNotNull);
      });
    });
  });
}
