import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:concept_nhv/models/tag_catalog_type.dart';
import 'package:concept_nhv/services/nhentai_api_client.dart';
import 'package:concept_nhv/services/nhentai_cdn_config_service.dart';
import 'package:concept_nhv/storage/nhentai_api_key_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_support/fakes/memory_secure_store.dart';

void main() {
  group('NhentaiApiClient', () {
    late MemorySecureKeyValueStore secureStore;
    late NhentaiApiKeyStore apiKeyStore;

    setUp(() {
      secureStore = MemorySecureKeyValueStore();
      apiKeyStore = NhentaiApiKeyStore(secureStore: secureStore);
    });

    test('searchComics maps search payload and injects authorization header', () async {
      await secureStore.write('nhentai-api-key', 'key-123');
      final adapter = _QueueHttpClientAdapter(<_StubbedResponse>[
        _StubbedResponse(
          body: jsonEncode(<String, Object>{
            'image_servers': <String>['https://i1.nhentai.net'],
            'thumb_servers': <String>['https://t1.nhentai.net'],
          }),
        ),
        _StubbedResponse(
          body: jsonEncode(<String, Object>{
            'result': <Map<String, Object?>>[
              <String, Object?>{
                'id': 99,
                'media_id': '777',
                'english_title': 'Mapped Comic',
                'japanese_title': 'Mapped Comic JP',
                'thumbnail': 'galleries/777/thumb.webp',
                'thumbnail_width': 320,
                'thumbnail_height': 480,
                'num_pages': 12,
              },
            ],
            'num_pages': 5,
            'per_page': 25,
          }),
        ),
      ]);
      final dio = Dio()..httpClientAdapter = adapter;
      final client = NhentaiApiClient(
        apiKeyStore: apiKeyStore,
        cdnConfigService: NhentaiCdnConfigService(dio: dio),
        dio: dio,
      );

      final response = await client.searchComics(
        Uri.https('nhentai.net', '/api/v2/galleries', <String, String>{
          'page': '1',
        }),
      );

      expect(response.numPages, 5);
      expect(response.perPage, 25);
      expect(response.result, hasLength(1));
      expect(response.result.single.id, '99');
      expect(response.result.single.mediaId, '777');
      expect(response.result.single.title.english, 'Mapped Comic');
      expect(response.result.single.images.thumbnail?.path, 'galleries/777/thumb.webp');
      expect(response.result.single.images.thumbnail?.t, 'w');
      expect(
        adapter.requests.last.options.headers['Authorization'],
        'Key key-123',
      );
    });

    test('loadComicDetail maps page, cover, thumbnail, and tags', () async {
      final adapter = _QueueHttpClientAdapter(<_StubbedResponse>[
        _StubbedResponse(statusCode: 500, body: '{"error":"config"}'),
        _StubbedResponse(
          body: jsonEncode(<String, Object?>{
            'id': 123,
            'media_id': '456',
            'title': <String, Object?>{
              'english': 'Detail Comic',
              'japanese': 'Detail Comic JP',
              'pretty': 'Detail Comic Pretty',
            },
            'cover': <String, Object?>{
              'path': 'galleries/456/cover.png',
              'width': 400,
              'height': 600,
            },
            'thumbnail': <String, Object?>{
              'path': 'galleries/456/thumb.webp.webp',
              'width': 200,
              'height': 300,
            },
            'pages': <Map<String, Object?>>[
              <String, Object?>{
                'path': 'galleries/456/1.webp.webp',
                'thumbnail': 'galleries/456/thumb1.webp',
                'width': 1200,
                'height': 1800,
              },
            ],
            'tags': <Map<String, Object?>>[
              <String, Object?>{
                'id': 1,
                'type': 'tag',
                'name': 'sample',
                'url': '/tag/sample',
                'count': 3,
              },
            ],
            'num_pages': 1,
            'num_favorites': 10,
            'scanlator': 'tester',
            'upload_date': 1000,
          }),
        ),
      ]);
      final dio = Dio()..httpClientAdapter = adapter;
      final client = NhentaiApiClient(
        apiKeyStore: apiKeyStore,
        cdnConfigService: NhentaiCdnConfigService(dio: dio),
        dio: dio,
      );

      final result = await client.loadComicDetail('123');

      expect(result.headers, isNull);
      expect(result.comic.id, '123');
      expect(result.comic.mediaId, '456');
      expect(result.comic.title.english, 'Detail Comic');
      expect(result.comic.images.cover?.path, 'galleries/456/cover.png');
      expect(result.comic.images.cover?.t, 'p');
      expect(result.comic.images.thumbnail?.t, 'w');
      expect(result.comic.images.pages.single.thumbnailPath, 'galleries/456/thumb1.webp');
      expect(result.comic.images.pages.single.t, 'w');
      expect(result.comic.tags.single.name, 'sample');
      expect(result.comic.numFavorites, 10);
    });

    test('loadComicMeta returns tags and numFavorites, reuses cache on repeated requests', () async {
      final adapter = _QueueHttpClientAdapter(<_StubbedResponse>[
        _StubbedResponse(
          body: jsonEncode(<String, Object?>{
            'id': 123,
            'media_id': '456',
            'title': <String, Object?>{
              'english': 'Detail Comic',
              'japanese': 'Detail Comic JP',
              'pretty': 'Detail Comic Pretty',
            },
            'pages': <Map<String, Object?>>[],
            'tags': <Map<String, Object?>>[
              <String, Object?>{
                'id': 2,
                'type': 'language',
                'name': 'chinese',
                'slug': 'chinese',
                'url': '/language/chinese/',
                'count': 5,
              },
            ],
            'num_pages': 0,
            'num_favorites': 42,
          }),
        ),
      ]);
      final dio = Dio()..httpClientAdapter = adapter;
      final client = NhentaiApiClient(
        apiKeyStore: apiKeyStore,
        cdnConfigService: NhentaiCdnConfigService(dio: dio),
        dio: dio,
      );

      final first = await client.loadComicMeta('123');
      final second = await client.loadComicMeta('123');

      expect(first.tags.single.name, 'chinese');
      expect(first.numFavorites, 42);
      expect(second.tags.single.name, 'chinese');
      expect(second.numFavorites, 42);
      // Cache should prevent a second API request.
      expect(adapter.requests, hasLength(1));
    });

    test('loadTagCatalog maps tag catalog pagination payload', () async {
      final adapter = _QueueHttpClientAdapter(<_StubbedResponse>[
        _StubbedResponse(
          body: jsonEncode(<String, Object?>{
            'num_pages': 7,
            'per_page': 120,
            'result': <Map<String, Object?>>[
              <String, Object?>{
                'id': 29963,
                'type': 'language',
                'name': 'chinese',
                'slug': 'chinese',
                'url': '/language/chinese/',
                'count': 9,
              },
            ],
          }),
        ),
      ]);
      final dio = Dio()..httpClientAdapter = adapter;
      final client = NhentaiApiClient(
        apiKeyStore: apiKeyStore,
        cdnConfigService: NhentaiCdnConfigService(dio: dio),
        dio: dio,
      );

      final result = await client.loadTagCatalog(
        type: TagCatalogType.language,
        page: 3,
      );

      expect(result.page, 3);
      expect(result.numPages, 7);
      expect(result.perPage, 120);
      expect(result.result.single.query, 'language:chinese');
      expect(adapter.requests.single.options.uri.queryParameters['sort'], 'popular');
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
