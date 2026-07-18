import 'package:freezed_annotation/freezed_annotation.dart';

part 'comic_title.freezed.dart';
part 'comic_title.g.dart';

@freezed
abstract class ComicTitle with _$ComicTitle {
  factory ComicTitle({String? english, String? japanese, String? pretty}) =
      _ComicTitle;

  factory ComicTitle.fromJson(Map<String, dynamic> json) =>
      _$ComicTitleFromJson(json);
}
