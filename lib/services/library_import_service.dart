import 'dart:convert';

import 'package:concept_nhv/models/collection_type.dart';
import 'package:concept_nhv/models/stored_comic.dart';
import 'package:concept_nhv/storage/collection_repository.dart';
import 'package:concept_nhv/storage/comic_repository.dart';
import 'package:dio/dio.dart';

class LibraryImportService {
  LibraryImportService({
    required this.comicRepository,
    required this.collectionRepository,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  final ComicRepository comicRepository;
  final CollectionRepository collectionRepository;
  final Dio _dio;

  Future<void> importFromBaseUrl(String baseUrl) async {
    final comicResponse = await _dio.get<String>('$baseUrl/comics.json');
    final collectionResponse = await _dio.get<String>(
      '$baseUrl/collections.json',
    );

    final comicJson = List<Map<String, dynamic>>.from(
      jsonDecode(comicResponse.data!) as List<dynamic>,
    );
    final collectionJson = List<Map<String, dynamic>>.from(
      jsonDecode(collectionResponse.data!) as List<dynamic>,
    );

    for (final json in comicJson) {
      await comicRepository.upsertComic(
        StoredComic(
          id: '${json['id']}',
          mediaId: json['mid'] as String,
          title: json['title'] as String,
          serializedImages: json['pageTypes'] as String,
          pages: json['numOfPages'] as int,
        ),
      );
    }

    for (final json in collectionJson) {
      final collectionType = CollectionType.fromStorageName(
        json['name'] as String,
      );
      if (collectionType == null) {
        continue;
      }

      await collectionRepository.addComicToCollection(
        collectionType: collectionType,
        comicId: '${json['id']}',
        dateCreated: DateTime.fromMillisecondsSinceEpoch(
          json['dateCreated'] as int,
        ).toIso8601String(),
      );
    }
  }
}
