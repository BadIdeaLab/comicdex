import 'package:concept_nhv/models/comic_images.dart';
import 'package:concept_nhv/models/comic_tag.dart';
import 'package:concept_nhv/models/comic_title.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'comic.freezed.dart';
part 'comic.g.dart';

String _stringFromDynamic(Object? value) => '$value';

@freezed
abstract class Comic with _$Comic {
  factory Comic({
    @JsonKey(fromJson: _stringFromDynamic) required String id,
    @JsonKey(name: 'media_id', fromJson: _stringFromDynamic)
    required String mediaId,
    required ComicTitle title,
    required ComicImages images,
    String? scanlator,
    @JsonKey(name: 'upload_date') int? uploadDate,
    @Default(<ComicTag>[]) List<ComicTag> tags,

    /// Listings return bare tag ids where details return full [tags]; see
    /// `kLanguageTagIds` in models/comic_language.dart.
    @JsonKey(name: 'tag_ids') @Default(<int>[]) List<int> tagIds,
    @JsonKey(name: 'num_pages') required int numPages,
    @JsonKey(name: 'num_favorites') int? numFavorites,
  }) = _Comic;

  factory Comic.fromJson(Map<String, dynamic> json) => _$ComicFromJson(json);
}

extension ComicTagIdList on Comic {
  /// The comic's tag ids from whichever form it carries: listings (and the
  /// favorites endpoint) send bare [tagIds], details send full [tags].
  List<int> get effectiveTagIds {
    if (tagIds.isNotEmpty) return tagIds;
    return <int>[
      for (final tag in tags)
        if (tag.id != null) tag.id!,
    ];
  }
}
