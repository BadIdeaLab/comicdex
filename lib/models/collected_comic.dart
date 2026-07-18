import 'package:concept_nhv/models/stored_comic.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'collected_comic.freezed.dart';
part 'collected_comic.g.dart';

@freezed
abstract class CollectedComic with _$CollectedComic {
  factory CollectedComic({
    required String collectionName,
    required String comicId,
    required DateTime dateCreated,
    required StoredComic comic,
  }) = _CollectedComic;

  factory CollectedComic.fromJson(Map<String, dynamic> json) =>
      _$CollectedComicFromJson(json);
}
