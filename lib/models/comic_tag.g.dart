// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comic_tag.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ComicTag _$ComicTagFromJson(Map<String, dynamic> json) => _ComicTag(
  id: (json['id'] as num?)?.toInt(),
  type: json['type'] as String?,
  name: json['name'] as String?,
  url: json['url'] as String?,
  count: (json['count'] as num?)?.toInt(),
);

Map<String, dynamic> _$ComicTagToJson(_ComicTag instance) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'name': instance.name,
  'url': instance.url,
  'count': instance.count,
};
