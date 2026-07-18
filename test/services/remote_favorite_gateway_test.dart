import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:concept_nhv/services/remote_favorite_gateway.dart';
import 'package:concept_nhv/storage/nhentai_api_key_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_support/fakes/fake_nhentai_auth_service.dart';
import '../test_support/fakes/memory_secure_store.dart';

void main() {
  group('NhentaiApiRemoteFavoriteGateway', () {
    late MemorySecureKeyValueStore secureStore;
    late NhentaiApiKeyStore apiKeyStore;
    late FakeNhentaiAuthService authService;

    setUp(() {
      secureStore = MemorySecureKeyValueStore();
      apiKeyStore = NhentaiApiKeyStore(secureStore: secureStore);
      authService = FakeNhentaiAuthService(apiKeyStore);
    });

    test('loadRemoteFavorites paginates and injects authorization header', () async {
      await secureStore.write('nhentai-api-key', 'key-123');
      final adapter = _QueueHttpClientAdapter(<_StubbedResponse>[
        _StubbedResponse(
          body: jsonEncode(<String, Object>{
            'result': <Map<String, Object?>>[
              <String, Object?>{
                'id': 1,
                'media_id': '11',
                'english_title': 'Favorite A',
                'thumbnail': 'galleries/11/thumb.jpg',
                'thumbnail_width': 120,
                'thumbnail_height': 180,
                'num_pages': 2,
              },
            ],
            'num_pages': 2,
          }),
        ),
        _StubbedResponse(
          body: jsonEncode(<String, Object>{
            'result': <Map<String, Object?>>[
              <String, Object?>{
                'id': 2,
                'media_id': '22',
                'english_title': 'Favorite B',
                'thumbnail': 'galleries/22/thumb.webp',
                'thumbnail_width': 120,
                'thumbnail_height': 180,
                'num_pages': 3,
              },
            ],
            'num_pages': 2,
          }),
        ),
      ]);
      final dio = Dio()..httpClientAdapter = adapter;
      final gateway = NhentaiApiRemoteFavoriteGateway(
        apiKeyStore: apiKeyStore,
        authService: authService,
        dio: dio,
      );

      final comics = await gateway.loadRemoteFavorites();

      expect(comics.map((comic) => comic.id), <String>['1', '2']);
      expect(
        adapter.requests.map((request) => request.options.uri.queryParameters['page']),
        <String?>['1', '2'],
      );
      expect(
        adapter.requests.first.options.headers['Authorization'],
        'Key key-123',
      );
    });

    test('uses the correct http methods for add and remove operations', () async {
      await secureStore.write('nhentai-api-key', 'key-123');
      final adapter = _QueueHttpClientAdapter(<_StubbedResponse>[
        const _StubbedResponse(body: '{}'),
        const _StubbedResponse(body: '{}'),
      ]);
      final dio = Dio()..httpClientAdapter = adapter;
      final gateway = NhentaiApiRemoteFavoriteGateway(
        apiKeyStore: apiKeyStore,
        authService: authService,
        dio: dio,
      );

      await gateway.addRemoteFavorite('7');
      await gateway.removeRemoteFavorite('7');

      expect(adapter.requests[0].options.method, 'POST');
      expect(adapter.requests[1].options.method, 'DELETE');
      expect(adapter.requests[0].options.uri.path, '/api/v2/galleries/7/favorite');
      expect(adapter.requests[1].options.uri.path, '/api/v2/galleries/7/favorite');
    });

    test('clears stored credentials and throws auth exception on unauthorized response', () async {
      await secureStore.write('nhentai-api-key', 'key-123');
      final adapter = _QueueHttpClientAdapter(<_StubbedResponse>[
        _StubbedResponse(statusCode: 401, body: '{"error":"unauthorized"}'),
      ]);
      final dio = Dio()..httpClientAdapter = adapter;
      final gateway = NhentaiApiRemoteFavoriteGateway(
        apiKeyStore: apiKeyStore,
        authService: authService,
        dio: dio,
      );

      await expectLater(
        () => gateway.addRemoteFavorite('7'),
        throwsA(isA<RemoteFavoriteAuthException>()),
      );

      expect(authService.clearCount, 1);
      expect((await apiKeyStore.load()).isEmpty, isTrue);
    });
  });
}

class _RecordedRequest {
  _RecordedRequest(this.options);

  final RequestOptions options;
}

class _StubbedResponse {
  const _StubbedResponse({
    this.statusCode = 200,
    required this.body,
  });

  final int statusCode;
  final String body;
}

class _QueueHttpClientAdapter implements HttpClientAdapter {
  _QueueHttpClientAdapter(this._responses);

  final List<_StubbedResponse> _responses;
  final List<_RecordedRequest> requests = <_RecordedRequest>[];
  var _index = 0;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(_RecordedRequest(options));
    final response = _responses[_index++];
    return ResponseBody.fromString(
      response.body,
      response.statusCode,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json'],
      },
    );
  }
}
