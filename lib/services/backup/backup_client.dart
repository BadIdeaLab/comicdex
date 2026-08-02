import 'dart:convert';
import 'dart:io';

import 'package:concept_nhv/services/backup/backup_connection.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

/// Protocol constants shared with the desktop server (`desktop_backup_server`).
const String kBackupPinHeader = 'X-Backup-Pin';
const String kBackupDeviceHeader = 'X-Device-Id';
const String kBackupSha256Header = 'X-Content-Sha256';
const String kBackupSchemaVersionHeader = 'X-Db-Schema-Version';

/// One device's backup partition as reported by `GET /devices`.
class RemoteBackupDevice {
  const RemoteBackupDevice({
    required this.deviceId,
    required this.fileCount,
    required this.totalBytes,
    this.lastSyncAt,
    this.latestDbSchemaVersion,
  });

  final String deviceId;
  final int fileCount;
  final int totalBytes;
  final DateTime? lastSyncAt;
  final int? latestDbSchemaVersion;

  factory RemoteBackupDevice.fromJson(Map<String, Object?> json) {
    final rawLastSync = json['lastSyncAt'];
    return RemoteBackupDevice(
      deviceId: json['deviceId'] as String? ?? '',
      fileCount: json['fileCount'] as int? ?? 0,
      totalBytes: json['totalBytes'] as int? ?? 0,
      lastSyncAt: rawLastSync is String ? DateTime.tryParse(rawLastSync) : null,
      latestDbSchemaVersion: json['latestDbSchemaVersion'] as int?,
    );
  }
}

/// Raised when the server answers, but not the way we need.
///
/// Carries the status code so the UI can distinguish "wrong PIN" (401) and
/// "locked out" (429) from a generic failure — those two need very different
/// advice.
class BackupServerException implements Exception {
  const BackupServerException(this.statusCode, this.message);

  final int? statusCode;
  final String message;

  bool get isUnauthorized => statusCode == HttpStatus.unauthorized;
  bool get isLockedOut => statusCode == HttpStatus.tooManyRequests;

  @override
  String toString() => 'BackupServerException($statusCode): $message';
}

/// The server was reachable and the PIN accepted, but it refused to open the
/// control connection.
///
/// Distinct from a connectivity failure on purpose: by the time this is thrown
/// the health check has already succeeded, so telling the user to check their
/// Wi-Fi and firewall would send them looking for a problem that is not there.
class BackupPairingRejectedException implements Exception {
  const BackupPairingRejectedException(this.details);

  final String details;

  @override
  String toString() => 'BackupPairingRejectedException: $details';
}

/// Talks to the desktop backup server.
///
/// An interface rather than a concrete class so the sync orchestration can be
/// tested without a live server, matching how [RemoteAssetFetcher] is set up.
abstract class BackupClient {
  Future<void> checkHealth(BackupConnection connection);

  Future<List<RemoteBackupDevice>> listDevices(BackupConnection connection);

  /// Relative path → size in bytes, for everything the server already holds.
  Future<Map<String, int>> fetchInventory(BackupConnection connection);

  Future<void> uploadFile({
    required BackupConnection connection,
    required String relativePath,
    required File file,
  });

  Future<void> uploadDatabase({
    required BackupConnection connection,
    required File snapshot,
    required int schemaVersion,
  });
}

class DioBackupClient implements BackupClient {
  DioBackupClient({Dio? dio}) : _dio = dio ?? _buildDio();

  final Dio _dio;

  /// Timeouts are set explicitly because the defaults are tuned for small API
  /// calls: a multi-megabyte page over slow Wi-Fi would be cut off mid-transfer.
  /// Connect still fails fast — "cannot reach the machine" should not hang — but
  /// an established, slowly-progressing transfer is never killed on a clock.
  static Dio _buildDio() {
    return Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        sendTimeout: Duration.zero,
        receiveTimeout: Duration.zero,
      ),
    );
  }

  Options _options(
    BackupConnection connection, {
    Map<String, String> extraHeaders = const <String, String>{},
    ResponseType responseType = ResponseType.json,
  }) {
    return Options(
      responseType: responseType,
      headers: <String, String>{
        kBackupPinHeader: connection.pin,
        kBackupDeviceHeader: connection.deviceId,
        ...extraHeaders,
      },
      // Let every status through so failures surface as BackupServerException
      // with their code intact rather than as an opaque DioException.
      validateStatus: (_) => true,
    );
  }

  Never _fail(Response<Object?> response) {
    final data = response.data;
    var message = 'HTTP ${response.statusCode}';
    if (data is Map && data['error'] is String) {
      message = data['error'] as String;
    } else if (data is String && data.isNotEmpty) {
      message = data;
    }
    throw BackupServerException(response.statusCode, message);
  }

  @override
  Future<void> checkHealth(BackupConnection connection) async {
    final response = await _dio.getUri<Object?>(
      connection.baseUri.replace(path: '/health'),
      options: _options(connection),
    );
    if (response.statusCode != HttpStatus.ok) {
      _fail(response);
    }
  }

  @override
  Future<List<RemoteBackupDevice>> listDevices(
    BackupConnection connection,
  ) async {
    final response = await _dio.getUri<Object?>(
      connection.baseUri.replace(path: '/devices'),
      options: _options(connection),
    );
    if (response.statusCode != HttpStatus.ok) {
      _fail(response);
    }
    final data = _decodeJson(response.data);
    if (data is! List) {
      throw const BackupServerException(null, 'Malformed device list');
    }
    return data
        .whereType<Map<String, Object?>>()
        .map(RemoteBackupDevice.fromJson)
        .toList(growable: false);
  }

  @override
  Future<Map<String, int>> fetchInventory(BackupConnection connection) async {
    final response = await _dio.getUri<Object?>(
      connection.baseUri.replace(path: '/inventory'),
      options: _options(connection),
    );
    if (response.statusCode != HttpStatus.ok) {
      _fail(response);
    }
    final data = _decodeJson(response.data);
    if (data is! List) {
      throw const BackupServerException(null, 'Malformed inventory');
    }
    final inventory = <String, int>{};
    for (final entry in data.whereType<Map<String, Object?>>()) {
      final path = entry['path'];
      final size = entry['sizeBytes'];
      if (path is String && size is int) {
        inventory[path] = size;
      }
    }
    return inventory;
  }

  @override
  Future<void> uploadFile({
    required BackupConnection connection,
    required String relativePath,
    required File file,
  }) async {
    // The digest has to accompany the request, so the file is read once to hash
    // and again to stream. For page images (a few hundred KB) that is cheaper
    // and far simpler than buffering the whole thing to hash in flight.
    final digest = await _digestOf(file);
    final length = await file.length();
    final response = await _dio.putUri<Object?>(
      connection.baseUri.replace(
        pathSegments: <String>['files', ...relativePath.split('/')],
      ),
      data: file.openRead(),
      options: _options(
        connection,
        extraHeaders: <String, String>{
          kBackupSha256Header: digest,
          Headers.contentLengthHeader: '$length',
          Headers.contentTypeHeader: 'application/octet-stream',
        },
      ),
    );
    if (response.statusCode != HttpStatus.created) {
      _fail(response);
    }
  }

  @override
  Future<void> uploadDatabase({
    required BackupConnection connection,
    required File snapshot,
    required int schemaVersion,
  }) async {
    // Digest is of the *uncompressed* bytes; the body is gzipped because the
    // database compresses well, unlike the already-compressed page images.
    final digest = await _digestOf(snapshot);
    final compressed = gzip.encode(await snapshot.readAsBytes());
    final response = await _dio.putUri<Object?>(
      connection.baseUri.replace(path: '/database'),
      data: Stream<List<int>>.value(compressed),
      options: _options(
        connection,
        extraHeaders: <String, String>{
          kBackupSha256Header: digest,
          kBackupSchemaVersionHeader: '$schemaVersion',
          Headers.contentLengthHeader: '${compressed.length}',
          Headers.contentTypeHeader: 'application/gzip',
        },
      ),
    );
    if (response.statusCode != HttpStatus.created) {
      _fail(response);
    }
  }

  static Future<String> _digestOf(File file) async {
    final output = AccumulatorSink<Digest>();
    final input = sha256.startChunkedConversion(output);
    await for (final chunk in file.openRead()) {
      input.add(chunk);
    }
    input.close();
    return output.events.single.toString();
  }

  /// Dio hands back either decoded JSON or a raw string depending on the
  /// response's content type, and the server's gzip responses can arrive as
  /// the latter.
  static Object? _decodeJson(Object? data) {
    if (data is String) {
      return jsonDecode(data);
    }
    return data;
  }
}

/// Local copy of `package:convert`'s sink so the app does not gain a dependency
/// for one small helper.
class AccumulatorSink<T> implements Sink<T> {
  final List<T> events = <T>[];

  @override
  void add(T event) => events.add(event);

  @override
  void close() {}
}
