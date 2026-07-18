import 'package:freezed_annotation/freezed_annotation.dart';

part 'comic_tag.freezed.dart';
part 'comic_tag.g.dart';

@freezed
abstract class ComicTag with _$ComicTag {
  factory ComicTag({
    int? id,
    String? type,
    String? name,
    String? url,
    int? count,
  }) = _ComicTag;

  factory ComicTag.fromJson(Map<String, dynamic> json) =>
      _$ComicTagFromJson(json);
}

extension ComicTagQuery on ComicTag {
  /// Builds the search query string for this tag (e.g. `tag:full-color`).
  ///
  /// Prefers the slug extracted from [url] (the authoritative nhentai slug),
  /// falling back to a name-based computation when [url] is absent. This
  /// matches [LocalTagCatalogEntry.query], which uses the API-provided slug
  /// directly.
  String get query {
    final type = this.type ?? 'tag';
    final slug = _slugFromUrl(url) ?? _slugFromName(name);
    return '$type:$slug';
  }

  String get slug => _slugFromUrl(url) ?? _slugFromName(name);

  String? _slugFromUrl(String? tagUrl) {
    if (tagUrl == null || tagUrl.isEmpty) return null;
    final parts = tagUrl.split('/').where((s) => s.isNotEmpty).toList();
    return parts.length >= 2 ? parts.last : null;
  }

  String _slugFromName(String? tagName) {
    return (tagName ?? '').toLowerCase().replaceAll(' ', '-');
  }
}
