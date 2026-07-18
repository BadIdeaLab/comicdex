// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stored_comic.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StoredComic _$StoredComicFromJson(Map<String, dynamic> json) => _StoredComic(
  id: json['id'] as String,
  mediaId: json['mid'] as String,
  title: json['title'] as String,
  serializedImages: json['images'] as String,
  pages: (json['pages'] as num).toInt(),
);

Map<String, dynamic> _$StoredComicToJson(_StoredComic instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mid': instance.mediaId,
      'title': instance.title,
      'images': instance.serializedImages,
      'pages': instance.pages,
    };
