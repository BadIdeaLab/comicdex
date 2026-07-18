import 'package:concept_nhv/models/comic_page_image.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'comic_images.freezed.dart';
part 'comic_images.g.dart';

@freezed
abstract class ComicImages with _$ComicImages {
  factory ComicImages({
    @Default(<ComicPageImage>[]) List<ComicPageImage> pages,
    ComicPageImage? cover,
    ComicPageImage? thumbnail,
  }) = _ComicImages;

  factory ComicImages.fromJson(Map<String, dynamic> json) =>
      _$ComicImagesFromJson(json);
}
