// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comic_page_image.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ComicPageImage _$ComicPageImageFromJson(Map<String, dynamic> json) =>
    _ComicPageImage(
      t: json['t'] as String?,
      w: (json['w'] as num?)?.toInt(),
      h: (json['h'] as num?)?.toInt(),
      path: json['path'] as String?,
      thumbnailPath: json['thumbnailPath'] as String?,
    );

Map<String, dynamic> _$ComicPageImageToJson(_ComicPageImage instance) =>
    <String, dynamic>{
      't': instance.t,
      'w': instance.w,
      'h': instance.h,
      'path': instance.path,
      'thumbnailPath': instance.thumbnailPath,
    };
