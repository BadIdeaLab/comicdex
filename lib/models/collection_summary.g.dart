// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collection_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CollectionSummary _$CollectionSummaryFromJson(Map<String, dynamic> json) =>
    _CollectionSummary(
      collectionName: json['collectionName'] as String,
      collectedCount: (json['collectedCount'] as num).toInt(),
      thumbnailUrl: json['thumbnailUrl'] as String,
      thumbnailWidth: (json['thumbnailWidth'] as num).toInt(),
      thumbnailHeight: (json['thumbnailHeight'] as num).toInt(),
    );

Map<String, dynamic> _$CollectionSummaryToJson(_CollectionSummary instance) =>
    <String, dynamic>{
      'collectionName': instance.collectionName,
      'collectedCount': instance.collectedCount,
      'thumbnailUrl': instance.thumbnailUrl,
      'thumbnailWidth': instance.thumbnailWidth,
      'thumbnailHeight': instance.thumbnailHeight,
    };
