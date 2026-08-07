import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:desktop_backup_server/models/backup_models.dart';
import 'package:desktop_backup_server/models/mobile_control.dart';
import 'package:desktop_backup_server/server/backup_server.dart';
import 'package:desktop_backup_server/server/pin_guard.dart';
import 'package:desktop_backup_server/storage/backup_library.dart';
import 'package:flutter_test/flutter_test.dart';

/// Exercised against a real [HttpServer] on an ephemeral port with a real
/// [HttpClient]. There is nothing to gain from mocking `dart:io` here — the
/// interesting behaviour (status codes, headers, streaming, atomicity) only
/// shows up when the actual stack runs.
void main() {
  group('BackupServer', () {
    late Directory root;
    late BackupLibrary library;
    late PinGuard pinGuard;
    late BackupServer server;
    late HttpClient client;
    late int port;
    late List<PruneCandidates> pruneRequests;

    /// Starts (or restarts) the server. Most tests want a guard that will not
    /// lock them out mid-test, so the brute-force threshold is effectively
    /// disabled here and exercised deliberately in its own test below.
    Future<void> startServer({int maxFailedAttempts = 1000}) async {
      await server.stop();
      pinGuard = PinGuard(maxFailedAttempts: maxFailedAttempts);
      server = BackupServer(
        library: library,
        pinGuard: pinGuard,
        onPruneRequest: pruneRequests.add,
      );
      port = await server.start(preferredPort: 0);
    }

    setUp(() async {
      root = await Directory.systemTemp.createTemp('comicdex-server-test');
      library = BackupLibrary(root: root);
      pruneRequests = <PruneCandidates>[];
      pinGuard = PinGuard(maxFailedAttempts: 1000);
      server = BackupServer(
        library: library,
        pinGuard: pinGuard,
        onPruneRequest: pruneRequests.add,
      );
      port = await server.start(preferredPort: 0);
      client = HttpClient();
    });

    tearDown(() async {
      client.close(force: true);
      await server.stop();
      if (root.existsSync()) {
        await root.delete(recursive: true);
      }
    });

    Future<HttpClientResponse> send(
      String method,
      String path, {
      String? pin,
      String? deviceId = 'Pixel-8',
      List<int>? body,
      Map<String, String> headers = const <String, String>{},
      bool omitPin = false,
    }) async {
      final request = await client.openUrl(
        method,
        Uri.parse('http://127.0.0.1:$port$path'),
      );
      if (!omitPin) {
        request.headers.set(kPinHeader, pin ?? pinGuard.pin);
      }
      if (deviceId != null) {
        request.headers.set(kDeviceHeader, deviceId);
      }
      headers.forEach(request.headers.set);
      if (body != null) {
        request.contentLength = body.length;
        request.add(body);
      }
      return request.close();
    }

    Future<String> textOf(HttpClientResponse response) {
      return response.transform(utf8.decoder).join();
    }

    Future<List<int>> bytesOf(HttpClientResponse response) {
      return response.fold<List<int>>(
        <int>[],
        (buffer, chunk) => buffer..addAll(chunk),
      );
    }

    Future<HttpClientResponse> putFile(String path, List<int> bytes) {
      return send(
        'PUT',
        '/files/$path',
        body: bytes,
        headers: <String, String>{
          kSha256Header: sha256.convert(bytes).toString(),
        },
      );
    }

    Future<HttpClientResponse> putDatabase(
      List<int> bytes, {
      int schemaVersion = 9,
    }) {
      return send(
        'PUT',
        '/database',
        body: gzip.encode(bytes),
        headers: <String, String>{
          kSha256Header: sha256.convert(bytes).toString(),
          kSchemaVersionHeader: '$schemaVersion',
        },
      );
    }

    group('authentication', () {
      test('every endpoint rejects a missing or wrong PIN with 401', () async {
        for (final target in <(String, String)>[
          ('GET', '/health'),
          ('GET', '/devices'),
          ('GET', '/inventory'),
          ('GET', '/files/177013/cover.webp'),
          ('GET', '/database'),
          ('GET', '/database/history'),
        ]) {
          final missing = await send(target.$1, target.$2, omitPin: true);
          expect(
            missing.statusCode,
            HttpStatus.unauthorized,
            reason: 'no PIN on ${target.$2}',
          );
          await missing.drain<void>();

          final wrong = await send(target.$1, target.$2, pin: '000000x');
          expect(
            wrong.statusCode,
            HttpStatus.unauthorized,
            reason: 'wrong PIN on ${target.$2}',
          );
          await wrong.drain<void>();
        }
      });

      test('repeated wrong PINs lock the caller out with 429', () async {
        await startServer(maxFailedAttempts: 5);
        for (var i = 0; i < 4; i++) {
          final response = await send('GET', '/health', pin: 'wrong');
          expect(response.statusCode, HttpStatus.unauthorized);
          await response.drain<void>();
        }
        final locked = await send('GET', '/health', pin: 'wrong');
        expect(locked.statusCode, HttpStatus.tooManyRequests);
        await locked.drain<void>();

        // Even the right PIN is refused while locked out.
        final blocked = await send('GET', '/health');
        expect(blocked.statusCode, HttpStatus.tooManyRequests);
        await blocked.drain<void>();
      });

      test('health reports the protocol version once authenticated', () async {
        final response = await send('GET', '/health', deviceId: null);
        expect(response.statusCode, HttpStatus.ok);
        expect(jsonDecode(await textOf(response)), <String, Object?>{
          'protocolVersion': kProtocolVersion,
        });
      });
    });

    group('device scoping', () {
      test('rejects a missing or unsafe device id with 400', () async {
        for (final bad in <String?>[null, '..', 'a/b']) {
          final response = await send('GET', '/inventory', deviceId: bad);
          expect(
            response.statusCode,
            HttpStatus.badRequest,
            reason: 'device id $bad',
          );
          await response.drain<void>();
        }
      });

      test('each device only sees its own files', () async {
        await (await putFile('177013/cover.webp', <int>[
          1,
          2,
          3,
        ])).drain<void>();

        final other = await send('GET', '/inventory', deviceId: 'iPad-Air');
        expect(jsonDecode(await textOf(other)), isEmpty);

        final own = await send('GET', '/inventory');
        expect(jsonDecode(await textOf(own)), hasLength(1));
      });
    });

    group('file round trip', () {
      test('upload, list, then download returns identical bytes', () async {
        final payload = List<int>.generate(5000, (i) => i % 256);

        final upload = await putFile('177013/pages/1.webp', payload);
        expect(upload.statusCode, HttpStatus.created);
        expect(jsonDecode(await textOf(upload)), <String, Object?>{
          'path': '177013/pages/1.webp',
          'sizeBytes': payload.length,
        });

        final inventory = await send('GET', '/inventory');
        expect(jsonDecode(await textOf(inventory)), <Object?>[
          <String, Object?>{
            'path': '177013/pages/1.webp',
            'sizeBytes': payload.length,
          },
        ]);

        final download = await send('GET', '/files/177013/pages/1.webp');
        expect(download.statusCode, HttpStatus.ok);
        expect(await bytesOf(download), payload);
      });

      test('a wrong checksum returns 422 and stores nothing', () async {
        final response = await send(
          'PUT',
          '/files/177013/cover.webp',
          body: <int>[1, 2, 3],
          headers: <String, String>{
            kSha256Header: sha256.convert(<int>[9, 9, 9]).toString(),
          },
        );
        expect(response.statusCode, HttpStatus.unprocessableEntity);
        await response.drain<void>();

        final inventory = await send('GET', '/inventory');
        expect(jsonDecode(await textOf(inventory)), isEmpty);
      });

      test('a missing checksum header returns 400', () async {
        final response = await send(
          'PUT',
          '/files/177013/cover.webp',
          body: <int>[1, 2, 3],
        );
        expect(response.statusCode, HttpStatus.badRequest);
        await response.drain<void>();
      });

      test('path traversal returns 400 and writes nothing', () async {
        final response = await send(
          'PUT',
          '/files/..%2F..%2Fescaped.txt',
          body: <int>[1],
          headers: <String, String>{
            kSha256Header: sha256.convert(<int>[1]).toString(),
          },
        );
        expect(response.statusCode, HttpStatus.badRequest);
        await response.drain<void>();
        expect(File('${root.path}/escaped.txt').existsSync(), isFalse);
      });

      test('downloading an unknown file returns 404', () async {
        final response = await send('GET', '/files/000000/cover.webp');
        expect(response.statusCode, HttpStatus.notFound);
        await response.drain<void>();
      });
    });

    group('database endpoints', () {
      test('upload then download returns the same bytes, gzipped', () async {
        final payload = utf8.encode('pretend this is sqlite');

        final upload = await putDatabase(payload);
        expect(upload.statusCode, HttpStatus.created);
        final created =
            jsonDecode(await textOf(upload)) as Map<String, Object?>;
        expect(created['schemaVersion'], 9);

        final download = await send('GET', '/database');
        expect(download.statusCode, HttpStatus.ok);
        expect(download.headers.value(kSchemaVersionHeader), '9');
        expect(gzip.decode(await bytesOf(download)), payload);
      });

      test('missing schema version header returns 400', () async {
        final payload = utf8.encode('db');
        final response = await send(
          'PUT',
          '/database',
          body: gzip.encode(payload),
          headers: <String, String>{
            kSha256Header: sha256.convert(payload).toString(),
          },
        );
        expect(response.statusCode, HttpStatus.badRequest);
        await response.drain<void>();
      });

      test('downloading with no snapshot yet returns 404', () async {
        final response = await send('GET', '/database');
        expect(response.statusCode, HttpStatus.notFound);
        await response.drain<void>();
      });

      test('history lists snapshots newest first', () async {
        await (await putDatabase(
          utf8.encode('one'),
          schemaVersion: 8,
        )).drain<void>();
        await (await putDatabase(
          utf8.encode('two'),
          schemaVersion: 9,
        )).drain<void>();

        final response = await send('GET', '/database/history');
        final history = jsonDecode(await textOf(response)) as List<Object?>;
        expect(history, hasLength(2));
        expect((history.first! as Map<String, Object?>)['schemaVersion'], 9);
      });
    });

    group('devices endpoint', () {
      test('summarises every device partition', () async {
        await (await putFile('177013/cover.webp', <int>[
          1,
          2,
          3,
        ])).drain<void>();
        await (await putDatabase(utf8.encode('db'))).drain<void>();

        final response = await send('GET', '/devices', deviceId: null);
        final devices = jsonDecode(await textOf(response)) as List<Object?>;
        expect(devices, hasLength(1));

        final device = devices.single! as Map<String, Object?>;
        expect(device['deviceId'], 'Pixel-8');
        expect(device['fileCount'], 1);
        expect(device['totalBytes'], 3);
        expect(device['latestDbSchemaVersion'], 9);
        expect(device['lastSyncAt'], isNotNull);
      });
    });

    group('mobile control channel', () {
      test(
        'a restore command carries the source device, and the reported job kind '
        'comes back so a finished restore is not labelled a finished backup',
        () async {
          final socket = await WebSocket.connect(
            'ws://127.0.0.1:$port/control/connect',
            headers: <String, String>{
              kPinHeader: pinGuard.pin,
              kDeviceHeader: 'New-Phone',
            },
          );
          final messages = StreamIterator<Object?>(socket);
          await messages.moveNext(); // 'connected'

          expect(
            server.sendControlCommand(
              'New-Phone',
              MobileControlAction.startRestore,
              sourceDeviceId: 'Old-Phone',
            ),
            isTrue,
          );
          expect(await messages.moveNext(), isTrue);
          final command =
              jsonDecode(messages.current! as String) as Map<String, Object?>;
          expect(command['action'], 'startRestore');
          // Without this the phone cannot tell which partition to pull, and it
          // must never guess.
          expect(command['sourceDeviceId'], 'Old-Phone');

          socket.add(
            jsonEncode(<String, Object?>{
              'type': 'status',
              'state': 'completed',
              'jobKind': 'restore',
            }),
          );
          await Future<void>.delayed(const Duration(milliseconds: 20));
          expect(server.connectedDevices.single.isRestoring, isTrue);

          await messages.cancel();
          await socket.close();
        },
      );

      test('a status without a job kind is treated as a backup', () async {
        final socket = await WebSocket.connect(
          'ws://127.0.0.1:$port/control/connect',
          headers: <String, String>{
            kPinHeader: pinGuard.pin,
            kDeviceHeader: 'Pixel-8',
          },
        );
        final messages = StreamIterator<Object?>(socket);
        await messages.moveNext();

        socket.add(
          jsonEncode(<String, Object?>{'type': 'status', 'state': 'running'}),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(server.connectedDevices.single.isRestoring, isFalse);

        await messages.cancel();
        await socket.close();
      });

      test('tracks status and sends desktop commands over WebSocket', () async {
        final socket = await WebSocket.connect(
          'ws://127.0.0.1:$port/control/connect',
          headers: <String, String>{
            kPinHeader: pinGuard.pin,
            kDeviceHeader: 'Pixel-8',
          },
        );
        final messages = StreamIterator<Object?>(socket);
        expect(await messages.moveNext(), isTrue);
        expect(jsonDecode(messages.current! as String), <String, Object?>{
          'type': 'connected',
        });
        expect(server.connectedDevices.single.deviceId, 'Pixel-8');

        expect(
          server.sendControlCommand('Pixel-8', MobileControlAction.startBackup),
          isTrue,
        );
        expect(await messages.moveNext(), isTrue);
        final command =
            jsonDecode(messages.current! as String) as Map<String, Object?>;
        expect(command['action'], 'startBackup');
        expect(command['commandId'], isNotEmpty);

        socket.add(
          jsonEncode(<String, Object?>{
            'type': 'status',
            'state': 'running',
            'uploadedFiles': 2,
            'totalFiles': 5,
            'currentPath': '177013/pages/2.webp',
          }),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
        final status = server.connectedDevices.single;
        expect(status.state, MobileJobState.running);
        expect(status.uploadedFiles, 2);
        expect(status.totalFiles, 5);

        await messages.cancel();
        await socket.close();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(server.connectedDevices, isEmpty);
      });

      test('rejects a WebSocket connection with a wrong PIN', () async {
        await expectLater(
          WebSocket.connect(
            'ws://127.0.0.1:$port/control/connect',
            headers: <String, String>{
              kPinHeader: '000000',
              kDeviceHeader: 'Pixel-8',
            },
          ),
          throwsA(isA<WebSocketException>()),
        );
      });
    });

    group('prune', () {
      test('reports stale files without deleting them', () async {
        await (await putFile('177013/cover.webp', <int>[1])).drain<void>();
        await (await putFile('999999/cover.webp', <int>[2, 2])).drain<void>();

        final response = await send(
          'POST',
          '/prune',
          body: utf8.encode(
            jsonEncode(<String, Object?>{
              'paths': <String>['177013/cover.webp'],
            }),
          ),
        );
        expect(response.statusCode, HttpStatus.ok);

        final payload =
            jsonDecode(await textOf(response)) as Map<String, Object?>;
        expect(payload['fileCount'], 1);
        expect(payload['totalBytes'], 2);

        // Handed to the UI for explicit confirmation, and still on disk.
        expect(pruneRequests, hasLength(1));
        expect(pruneRequests.single.entries.single.path, '999999/cover.webp');
        expect(await library.inventory('Pixel-8'), hasLength(2));
      });

      test('rejects a malformed body with 400', () async {
        final response = await send(
          'POST',
          '/prune',
          body: utf8.encode(jsonEncode(<String, Object?>{'wrong': 1})),
        );
        expect(response.statusCode, HttpStatus.badRequest);
        await response.drain<void>();
      });
    });

    group('missing backup root', () {
      test('returns 503 rather than pretending the mirror is empty', () async {
        await (await putFile('177013/cover.webp', <int>[1])).drain<void>();
        await root.delete(recursive: true);

        final response = await send('GET', '/inventory');
        expect(response.statusCode, HttpStatus.serviceUnavailable);
        await response.drain<void>();
        expect(root.existsSync(), isFalse);
      });
    });

    group('routing', () {
      test('unknown paths return 404', () async {
        final response = await send('GET', '/nope');
        expect(response.statusCode, HttpStatus.notFound);
        await response.drain<void>();
      });
    });
  });
}
