import 'package:concept_nhv/models/comic.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'comic_search_response.freezed.dart';
part 'comic_search_response.g.dart';

@freezed
abstract class ComicSearchResponse with _$ComicSearchResponse {
  factory ComicSearchResponse({
    @Default(<Comic>[]) List<Comic> result,
    @JsonKey(name: 'num_pages') int? numPages,
    @JsonKey(name: 'per_page') int? perPage,
  }) = _ComicSearchResponse;

  factory ComicSearchResponse.fromJson(Map<String, dynamic> json) =>
      _$ComicSearchResponseFromJson(json);
}
