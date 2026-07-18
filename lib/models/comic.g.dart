// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comic.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Comic _$ComicFromJson(Map<String, dynamic> json) => _Comic(
  id: _stringFromDynamic(json['id']),
  mediaId: _stringFromDynamic(json['media_id']),
  title: ComicTitle.fromJson(json['title'] as Map<String, dynamic>),
  images: ComicImages.fromJson(json['images'] as Map<String, dynamic>),
  scanlator: json['scanlator'] as String?,
  uploadDate: (json['upload_date'] as num?)?.toInt(),
  tags:
      (json['tags'] as List<dynamic>?)
          ?.map((e) => ComicTag.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ComicTag>[],
  numPages: (json['num_pages'] as num).toInt(),
  numFavorites: (json['num_favorites'] as num?)?.toInt(),
);

Map<String, dynamic> _$ComicToJson(_Comic instance) => <String, dynamic>{
  'id': instance.id,
  'media_id': instance.mediaId,
  'title': instance.title,
  'images': instance.images,
  'scanlator': instance.scanlator,
  'upload_date': instance.uploadDate,
  'tags': instance.tags,
  'num_pages': instance.numPages,
  'num_favorites': instance.numFavorites,
};
