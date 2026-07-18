import 'package:freezed_annotation/freezed_annotation.dart';

part 'collection_summary.freezed.dart';
part 'collection_summary.g.dart';

@freezed
abstract class CollectionSummary with _$CollectionSummary {
  factory CollectionSummary({
    required String collectionName,
    required int collectedCount,
    required String thumbnailUrl,
    required int thumbnailWidth,
    required int thumbnailHeight,
  }) = _CollectionSummary;

  factory CollectionSummary.fromJson(Map<String, dynamic> json) =>
      _$CollectionSummaryFromJson(json);
}
