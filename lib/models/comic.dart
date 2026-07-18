import 'package:concept_nhv/models/comic_images.dart';
import 'package:concept_nhv/models/comic_tag.dart';
import 'package:concept_nhv/models/comic_title.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'comic.freezed.dart';
part 'comic.g.dart';

String _stringFromDynamic(Object? value) => '$value';

@freezed
abstract class Comic with _$Comic {
  factory Comic({
    @JsonKey(fromJson: _stringFromDynamic) required String id,
    @JsonKey(name: 'media_id', fromJson: _stringFromDynamic)
    required String mediaId,
    required ComicTitle title,
    required ComicImages images,
    String? scanlator,
    @JsonKey(name: 'upload_date') int? uploadDate,
    @Default(<ComicTag>[]) List<ComicTag> tags,
    @JsonKey(name: 'num_pages') required int numPages,
    @JsonKey(name: 'num_favorites') int? numFavorites,
  }) = _Comic;

  factory Comic.fromJson(Map<String, dynamic> json) => _$ComicFromJson(json);
}
