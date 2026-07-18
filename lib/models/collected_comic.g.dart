// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collected_comic.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CollectedComic _$CollectedComicFromJson(Map<String, dynamic> json) =>
    _CollectedComic(
      collectionName: json['collectionName'] as String,
      comicId: json['comicId'] as String,
      dateCreated: DateTime.parse(json['dateCreated'] as String),
      comic: StoredComic.fromJson(json['comic'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CollectedComicToJson(_CollectedComic instance) =>
    <String, dynamic>{
      'collectionName': instance.collectionName,
      'comicId': instance.comicId,
      'dateCreated': instance.dateCreated.toIso8601String(),
      'comic': instance.comic,
    };
