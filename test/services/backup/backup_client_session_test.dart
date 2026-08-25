import 'dart:convert';

import 'package:concept_nhv/services/backup/backup_client.dart';
import 'package:concept_nhv/services/backup/backup_connection.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Covers the client half of the session-token contract.
///
/// This layer had no tests, and that is exactly how a real regression got out:
/// `PinGuard` and the server were both covered, but nothing checked what the
/// *phone* sends after the desktop rotates its PIN. A backup re-checks health
/// before it starts, so the token has to survive that call — dropping it there
/// produced a 401 at the one moment it existed to prevent.
void main() {
  group('DioBackupClient session token', () {
    late _RecordingAdapter adapter;
    late DioBackupClient client;

    final connection = BackupConnection(
      baseUri: Uri.parse('http://192.168.50.72:6890'),
      pin: 'original-pin',
      deviceId: 'Pixel-8',
    );

    setUp(() {
      adapter = _RecordingAdapter();
      client = DioBackupClient(dio: Dio()..httpClientAdapter = adapter);
    });

    test('keeps the token across a second health check', () async {
      adapter.sessionToken = 'token-1';

      await client.checkHealth(connection);
      await client.checkHealth(connection);

      expect(
        adapter.sentSessionHeaders,
        <String?>[null, 'token-1'],
        reason: 'the second call must still carry the token from the first',
      );
    });

    test('sends the token on ordinary requests, not just health', () async {
      adapter.sessionToken = 'token-1';
      await client.checkHealth(connection);
      adapter.sentSessionHeaders.clear();

      await client.fetchInventory(connection);

      expect(adapter.sentSessionHeaders, <String?>['token-1']);
    });

    test('takes the newest token the server offers', () async {
      adapter.sessionToken = 'token-1';
      await client.checkHealth(connection);
      adapter.sessionToken = 'token-2';
      await client.checkHealth(connection);
      adapter.sentSessionHeaders.clear();

      await client.fetchInventory(connection);

      expect(adapter.sentSessionHeaders, <String?>['token-2']);
    });

    test('still sends the PIN alongside, so a fresh server can pair', () async {
      // A stale token reaching a different machine is harmless — that server
      // tries the token, fails, and falls through to the PIN.
      adapter.sessionToken = 'token-1';
      await client.checkHealth(connection);

      expect(adapter.sentPinHeaders.last, 'original-pin');
    });

    test('copes with a server that offers no token', () async {
      // An older desktop build predates the whole mechanism.
      adapter.sessionToken = null;

      await client.checkHealth(connection);
      await client.fetchInventory(connection);

      expect(adapter.sentSessionHeaders, <String?>[null, null]);
    });
  });
}

/// Answers every request with a canned body and records what was sent.
class _RecordingAdapter implements HttpClientAdapter {
  String? sessionToken;
  final List<String?> sentSessionHeaders = <String?>[];
  final List<String?> sentPinHeaders = <String?>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    sentSessionHeaders.add(options.headers[kBackupSessionHeader] as String?);
    sentPinHeaders.add(options.headers[kBackupPinHeader] as String?);

    // The inventory endpoint answers with a list, everything else with an
    // object; the client rejects the wrong shape, so the stub has to match it.
    final Object body = options.path.endsWith('/health')
        ? <String, Object?>{
            'protocolVersion': 1,
            if (sessionToken != null) 'sessionToken': sessionToken,
          }
        : <Object?>[];

    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
