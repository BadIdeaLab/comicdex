import 'dart:async';
import 'dart:typed_data';

import 'package:concept_nhv/models/collection_type.dart';
import 'package:concept_nhv/services/library_import_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_support/storage/sqlite_test_harness.dart';

void main() {
  group('LibraryImportService', () {
    late SqliteTestHarness harness;

    setUp(() async {
      harness = SqliteTestHarness();
      await harness.initialize();
    });

    tearDown(() async {
      await harness.dispose();
    });

    test('imports comics and collection memberships from the base url', () async {
      final dio = Dio()
        ..httpClientAdapter = _MapHttpClientAdapter(<String, String>{
          'https://example.com/library/comics.json':
              '[{"id":1,"mid":"9","title":"Imported Comic","pageTypes":"jj","numOfPages":2}]',
          'https://example.com/library/collections.json':
              '[{"id":1,"name":"Favorite","dateCreated":1704067200000}]',
        });
      final service = LibraryImportService(
        comicRepository: harness.comicRepository,
        collectionRepository: harness.collectionRepository,
        dio: dio,
      );

      await service.importFromBaseUrl('https://example.com/library');

      final comicRows = await harness.localDatabase
          .customSelect('SELECT title FROM Comic')
          .get();
      final favoriteIds = await harness.collectionRepository.loadCollectedComicIds(
        CollectionType.favorite,
      );

      expect(comicRows, hasLength(1));
      expect(comicRows.single.read<String>('title'), 'Imported Comic');
      expect(favoriteIds, <String>{'1'});
    });

    test('ignores unknown collection names during import', () async {
      final dio = Dio()
        ..httpClientAdapter = _MapHttpClientAdapter(<String, String>{
          'https://example.com/library/comics.json':
              '[{"id":1,"mid":"9","title":"Imported Comic","pageTypes":"jj","numOfPages":2}]',
          'https://example.com/library/collections.json':
              '[{"id":1,"name":"Archived","dateCreated":1704067200000}]',
        });
      final service = LibraryImportService(
        comicRepository: harness.comicRepository,
        collectionRepository: harness.collectionRepository,
        dio: dio,
      );

      await service.importFromBaseUrl('https://example.com/library');

      final favoriteIds = await harness.collectionRepository.loadCollectedComicIds(
        CollectionType.favorite,
      );
      final nextIds = await harness.collectionRepository.loadCollectedComicIds(
        CollectionType.next,
      );

      expect(favoriteIds, isEmpty);
      expect(nextIds, isEmpty);
    });
  });
}

class _MapHttpClientAdapter implements HttpClientAdapter {
  _MapHttpClientAdapter(this._responses);

  final Map<String, String> _responses;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = _responses[options.uri.toString()];
    if (body == null) {
      throw StateError('No stubbed response for ${options.uri}');
    }

    return ResponseBody.fromString(
      body,
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json'],
      },
    );
  }
}
