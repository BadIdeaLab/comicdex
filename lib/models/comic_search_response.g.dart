// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comic_search_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ComicSearchResponse _$ComicSearchResponseFromJson(Map<String, dynamic> json) =>
    _ComicSearchResponse(
      result:
          (json['result'] as List<dynamic>?)
              ?.map((e) => Comic.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <Comic>[],
      numPages: (json['num_pages'] as num?)?.toInt(),
      perPage: (json['per_page'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ComicSearchResponseToJson(
  _ComicSearchResponse instance,
) => <String, dynamic>{
  'result': instance.result,
  'num_pages': instance.numPages,
  'per_page': instance.perPage,
};
