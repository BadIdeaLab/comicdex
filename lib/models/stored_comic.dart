import 'dart:convert';

import 'package:concept_nhv/models/comic.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'stored_comic.freezed.dart';
part 'stored_comic.g.dart';

@freezed
abstract class StoredComic with _$StoredComic {
  factory StoredComic({
    required String id,
    @JsonKey(name: 'mid') required String mediaId,
    required String title,
    @JsonKey(name: 'images') required String serializedImages,
    @JsonKey(name: 'pages') required int pages,
  }) = _StoredComic;

  factory StoredComic.fromJson(Map<String, dynamic> json) =>
      _$StoredComicFromJson(json);

  factory StoredComic.fromComic(Comic comic) => StoredComic(
    id: comic.id,
    mediaId: comic.mediaId,
    title: comic.title.english ?? comic.title.pretty ?? comic.id,
    serializedImages: jsonEncode(comic.images.toJson()),
    pages: comic.numPages,
  );
}
