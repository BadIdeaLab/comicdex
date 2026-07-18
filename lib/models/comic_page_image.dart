import 'package:freezed_annotation/freezed_annotation.dart';

part 'comic_page_image.freezed.dart';
part 'comic_page_image.g.dart';

@freezed
abstract class ComicPageImage with _$ComicPageImage {
  factory ComicPageImage({
    String? t,
    int? w,
    int? h,
    String? path,
    String? thumbnailPath,
  }) = _ComicPageImage;

  factory ComicPageImage.fromJson(Map<String, dynamic> json) =>
      _$ComicPageImageFromJson(json);
}
