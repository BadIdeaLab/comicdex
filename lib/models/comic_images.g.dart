// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comic_images.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ComicImages _$ComicImagesFromJson(Map<String, dynamic> json) => _ComicImages(
  pages:
      (json['pages'] as List<dynamic>?)
          ?.map((e) => ComicPageImage.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ComicPageImage>[],
  cover: json['cover'] == null
      ? null
      : ComicPageImage.fromJson(json['cover'] as Map<String, dynamic>),
  thumbnail: json['thumbnail'] == null
      ? null
      : ComicPageImage.fromJson(json['thumbnail'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ComicImagesToJson(_ComicImages instance) =>
    <String, dynamic>{
      'pages': instance.pages,
      'cover': instance.cover,
      'thumbnail': instance.thumbnail,
    };
