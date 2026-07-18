import 'dart:async';
import 'dart:typed_data';

import 'package:concept_nhv/models/nhentai_api_credential.dart';
import 'package:concept_nhv/services/nhentai_auth_service.dart';
import 'package:concept_nhv/storage/nhentai_api_key_store.dart';
import 'package:concept_nhv/storage/secure_key_value_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _MemorySecureKeyValueStore secureStore;
  late NhentaiApiKeyStore apiKeyStore;

  setUp(() {
    secureStore = _MemorySecureKeyValueStore();
    apiKeyStore = NhentaiApiKeyStore(secureStore: secureStore);
  });

  test('saveAndValidateApiKey stores validated username and timestamp', () async {
    final dio = Dio()
      ..httpClientAdapter = _FakeHttpClientAdapter(
        statusCode: 200,
        body: '{"username":"tester"}',
      );
    final service = NhentaiAuthService(apiKeyStore: apiKeyStore, dio: dio);

    final credential = await service.saveAndValidateApiKey('key-123');
    final stored = await apiKeyStore.load();

    expect(credential.username, 'tester');
    expect(stored.apiKey, 'key-123');
    expect(stored.username, 'tester');
    expect(stored.lastValidatedAt, isNotNull);
  });

  test('validateStoredApiKey returns false for unauthorized responses', () async {
    await apiKeyStore.save(
      const NhentaiApiCredential(apiKey: 'bad-key'),
    );
    final dio = Dio()
      ..httpClientAdapter = _FakeHttpClientAdapter(
        statusCode: 401,
        body: '{"error":"unauthorized"}',
      );
    final service = NhentaiAuthService(apiKeyStore: apiKeyStore, dio: dio);

    final isValid = await service.validateStoredApiKey();

    expect(isValid, isFalse);
  });
}

class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter({required this.statusCode, required this.body});

  final int statusCode;
  final String body;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json'],
      },
    );
  }
}

class _MemorySecureKeyValueStore implements SecureKeyValueStore {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }

  @override
  Future<String?> read(String key) async {
    return _values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }
}
