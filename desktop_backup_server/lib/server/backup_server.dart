import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/backup_models.dart';
import '../storage/backup_exceptions.dart';
import '../storage/backup_library.dart';
import 'pin_guard.dart';

/// Bumped only when the wire format changes incompatibly, so the phone can fail
/// fast with a clear message instead of misbehaving.
const int kProtocolVersion = 1;

const String kPinHeader = 'X-Backup-Pin';
const String kDeviceHeader = 'X-Device-Id';
const String kSha256Header = 'X-Content-Sha256';
const String kSchemaVersionHeader = 'X-Db-Schema-Version';

const int kDefaultPort = 8787;

/// HTTP surface of the backup mirror.
///
/// Deliberately plain `dart:io` with no routing package: there are nine
/// endpoints and keeping the dependency surface small matters more than the
/// ergonomics of a router here.
class BackupServer {
  BackupServer({
    required this.library,
    required this.pinGuard,
    this.onActivity,
    this.onPruneRequest,
  });

  final BackupLibrary library;
  final PinGuard pinGuard;

  /// Human-readable progress for the desktop UI ("Received 177013/pages/1.webp").
  final void Function(String message)? onActivity;

  /// The phone asked what is stale. Nothing is deleted here — the UI holds these
  /// candidates until the user explicitly confirms.
  final void Function(PruneCandidates candidates)? onPruneRequest;

  HttpServer? _httpServer;

  /// Serialises mutating requests. The protocol has no notion of concurrent
  /// syncs, and letting an upload interleave with a prune would race over the
  /// same paths.
  bool _writeInProgress = false;

  int? get port => _httpServer?.port;
  bool get isRunning => _httpServer != null;

  /// Binds to [preferredPort], walking upward if it is taken so a port already
  /// claimed by something else does not block startup entirely.
  ///
  /// Pass `0` to let the OS pick (used by tests).
  Future<int> start({int preferredPort = kDefaultPort, int attempts = 20}) async {
    if (_httpServer != null) {
      return _httpServer!.port;
    }
    SocketException? lastError;
    for (var offset = 0; offset < attempts; offset++) {
      final candidate = preferredPort == 0 ? 0 : preferredPort + offset;
      try {
        final server = await HttpServer.bind(InternetAddress.anyIPv4, candidate);
        _httpServer = server;
        unawaited(_listen(server));
        return server.port;
      } on SocketException catch (error) {
        lastError = error;
        if (preferredPort == 0) {
          break;
        }
      }
    }
    throw StateError('Could not bind a port: $lastError');
  }

  Future<void> stop() async {
    final server = _httpServer;
    _httpServer = null;
    await server?.close(force: true);
  }

  Future<void> _listen(HttpServer server) async {
    await for (final request in server) {
      // Each request is handled independently; one failure must not tear down
      // the listen loop.
      unawaited(_handle(request));
    }
  }

  Future<void> _handle(HttpRequest request) async {
    final response = request.response;
    try {
      await _route(request);
    } on BackupLibraryException catch (error) {
      _writeJson(response, _statusForException(error), <String, Object?>{
        'error': error.message,
      });
    } catch (error) {
      _writeJson(response, HttpStatus.internalServerError, <String, Object?>{
        'error': '$error',
      });
    }
    try {
      await response.close();
    } on HttpException {
      // Client hung up mid-response; nothing useful left to do.
    }
  }

  static int _statusForException(BackupLibraryException error) {
    return switch (error) {
      InvalidBackupPathException() => HttpStatus.badRequest,
      DigestMismatchException() => HttpStatus.unprocessableEntity,
      BackupRootUnavailableException() => HttpStatus.serviceUnavailable,
      BackupStorageException() => HttpStatus.insufficientStorage,
    };
  }

  Future<void> _route(HttpRequest request) async {
    final response = request.response;

    // --- PIN gate (before anything else touches disk) ---
    final address = request.connectionInfo?.remoteAddress.address ?? 'unknown';
    final pinResult = pinGuard.check(
      providedPin: request.headers.value(kPinHeader),
      address: address,
    );
    if (pinResult == PinCheckResult.lockedOut) {
      onActivity?.call('Blocked repeated wrong PIN from $address');
      _writeJson(response, HttpStatus.tooManyRequests, <String, Object?>{
        'error': 'Too many failed PIN attempts. Try again later.',
      });
      return;
    }
    if (pinResult == PinCheckResult.rejected) {
      _writeJson(response, HttpStatus.unauthorized, <String, Object?>{
        'error': 'Invalid PIN',
      });
      return;
    }

    final segments = request.uri.pathSegments;
    final method = request.method;

    if (segments.isEmpty) {
      _writeJson(response, HttpStatus.notFound, <String, Object?>{
        'error': 'Not found',
      });
      return;
    }

    // --- Endpoints that are not device-scoped ---
    if (segments.length == 1 && segments.first == 'health' && method == 'GET') {
      _writeJson(response, HttpStatus.ok, <String, Object?>{
        'protocolVersion': kProtocolVersion,
      });
      return;
    }
    if (segments.length == 1 && segments.first == 'devices' && method == 'GET') {
      final devices = await library.listDevices();
      _writeJson(
        response,
        HttpStatus.ok,
        devices.map((device) => device.toJson()).toList(growable: false),
      );
      return;
    }

    // --- Everything below is scoped to one device ---
    final deviceId = BackupLibrary.validateDeviceId(
      request.headers.value(kDeviceHeader),
    );

    switch (segments.first) {
      case 'inventory':
        if (segments.length == 1 && method == 'GET') {
          await _handleInventory(request, deviceId);
          return;
        }
      case 'files':
        if (segments.length >= 2) {
          final relativePath = segments.sublist(1).join('/');
          if (method == 'PUT') {
            await _handlePutFile(request, deviceId, relativePath);
            return;
          }
          if (method == 'GET') {
            await _handleGetFile(request, deviceId, relativePath);
            return;
          }
        }
      case 'database':
        if (segments.length == 1 && method == 'PUT') {
          await _handlePutDatabase(request, deviceId);
          return;
        }
        if (segments.length == 1 && method == 'GET') {
          await _handleGetDatabase(request, deviceId);
          return;
        }
        if (segments.length == 2 &&
            segments[1] == 'history' &&
            method == 'GET') {
          final snapshots = await library.listDbSnapshots(deviceId);
          _writeJson(
            response,
            HttpStatus.ok,
            snapshots.map((s) => s.toJson()).toList(growable: false),
          );
          return;
        }
      case 'prune':
        if (segments.length == 1 && method == 'POST') {
          await _handlePrune(request, deviceId);
          return;
        }
    }

    _writeJson(response, HttpStatus.notFound, <String, Object?>{
      'error': 'Not found',
    });
  }

  // ---------------------------------------------------------------------
  // Handlers
  // ---------------------------------------------------------------------

  Future<void> _handleInventory(HttpRequest request, String deviceId) async {
    final entries = await library.inventory(deviceId);
    final payload = utf8.encode(
      jsonEncode(entries.map((entry) => entry.toJson()).toList(growable: false)),
    );
    // Transparent transport compression: the client's HTTP stack unwraps this
    // automatically, unlike the database payload which is gzip *content*.
    final response = request.response;
    response.statusCode = HttpStatus.ok;
    response.headers.contentType = ContentType.json;
    response.headers.set(HttpHeaders.contentEncodingHeader, 'gzip');
    response.add(gzip.encode(payload));
  }

  Future<void> _handlePutFile(
    HttpRequest request,
    String deviceId,
    String relativePath,
  ) async {
    final expected = request.headers.value(kSha256Header);
    if (expected == null || expected.isEmpty) {
      throw const InvalidBackupPathException('Missing $kSha256Header header');
    }
    if (!_acquireWriteLock()) {
      _writeJson(request.response, HttpStatus.conflict, <String, Object?>{
        'error': 'Another sync is already in progress',
      });
      return;
    }
    try {
      final size = await library.writeDownloadFile(
        deviceId: deviceId,
        relativePath: relativePath,
        source: request,
        expectedSha256: expected,
      );
      onActivity?.call('Received $relativePath from $deviceId');
      _writeJson(request.response, HttpStatus.created, <String, Object?>{
        'path': relativePath,
        'sizeBytes': size,
      });
    } finally {
      _releaseWriteLock();
    }
  }

  Future<void> _handleGetFile(
    HttpRequest request,
    String deviceId,
    String relativePath,
  ) async {
    final file = await library.findDownloadFile(deviceId, relativePath);
    if (file == null) {
      _writeJson(request.response, HttpStatus.notFound, <String, Object?>{
        'error': 'No such file: $relativePath',
      });
      return;
    }
    final response = request.response;
    response.statusCode = HttpStatus.ok;
    response.headers.contentType = ContentType.binary;
    response.headers.contentLength = await file.length();
    await response.addStream(file.openRead());
    onActivity?.call('Sent $relativePath to $deviceId');
  }

  Future<void> _handlePutDatabase(HttpRequest request, String deviceId) async {
    final expected = request.headers.value(kSha256Header);
    if (expected == null || expected.isEmpty) {
      throw const InvalidBackupPathException('Missing $kSha256Header header');
    }
    final rawSchema = request.headers.value(kSchemaVersionHeader);
    final schemaVersion = int.tryParse(rawSchema ?? '');
    if (schemaVersion == null) {
      throw const InvalidBackupPathException(
        'Missing or invalid $kSchemaVersionHeader header',
      );
    }
    if (!_acquireWriteLock()) {
      _writeJson(request.response, HttpStatus.conflict, <String, Object?>{
        'error': 'Another sync is already in progress',
      });
      return;
    }
    try {
      final snapshot = await library.writeDbSnapshot(
        deviceId: deviceId,
        gzippedSource: request,
        expectedSha256: expected,
        schemaVersion: schemaVersion,
      );
      onActivity?.call('Stored database snapshot for $deviceId');
      _writeJson(request.response, HttpStatus.created, snapshot.toJson());
    } finally {
      _releaseWriteLock();
    }
  }

  Future<void> _handleGetDatabase(HttpRequest request, String deviceId) async {
    final snapshot = await library.latestDbSnapshot(deviceId);
    if (snapshot == null) {
      _writeJson(request.response, HttpStatus.notFound, <String, Object?>{
        'error': 'No database snapshot for $deviceId',
      });
      return;
    }
    final file = library.dbSnapshotFile(deviceId, snapshot.filename);
    final response = request.response;
    response.statusCode = HttpStatus.ok;
    // gzip as payload format (not Content-Encoding): the client decompresses
    // explicitly and checks the digest of the decompressed bytes.
    response.headers.contentType = ContentType('application', 'gzip');
    response.headers.set(kSchemaVersionHeader, '${snapshot.schemaVersion}');
    await response.addStream(gzip.encoder.bind(file.openRead()));
    onActivity?.call('Sent database snapshot to $deviceId');
  }

  Future<void> _handlePrune(HttpRequest request, String deviceId) async {
    final body = await utf8.decodeStream(request);
    final decoded = body.isEmpty ? null : jsonDecode(body);
    if (decoded is! Map<String, Object?> || decoded['paths'] is! List) {
      throw const InvalidBackupPathException(
        'Expected a JSON body of {"paths": [...]}',
      );
    }
    final phonePaths = (decoded['paths']! as List)
        .whereType<String>()
        .toSet();
    final candidates = await library.pruneCandidates(
      deviceId: deviceId,
      phonePaths: phonePaths,
    );
    onPruneRequest?.call(candidates);
    onActivity?.call(
      'Prune requested by $deviceId: ${candidates.entries.length} stale files',
    );
    _writeJson(request.response, HttpStatus.ok, candidates.toJson());
  }

  // ---------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------

  bool _acquireWriteLock() {
    if (_writeInProgress) {
      return false;
    }
    _writeInProgress = true;
    return true;
  }

  void _releaseWriteLock() {
    _writeInProgress = false;
  }

  static void _writeJson(HttpResponse response, int status, Object? body) {
    response.statusCode = status;
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(body));
  }
}
