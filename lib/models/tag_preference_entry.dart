import 'package:concept_nhv/models/local_tag_catalog_entry.dart';

/// One ranked tag in the preference analysis (P78).
class TagPreferenceEntry {
  const TagPreferenceEntry({
    required this.tag,
    required this.comicCount,
    required this.favoriteCount,
    required this.downloadedCount,
  });

  final LocalTagCatalogEntry tag;

  /// Comics carrying this tag that are favorited or downloaded, counted once
  /// even when they are both.
  final int comicCount;

  final int favoriteCount;
  final int downloadedCount;

  /// How over-represented the tag is compared to the whole site: the share
  /// of galleries carrying it site-wide is [LocalTagCatalogEntry.count], so
  /// dividing ranks a tag the user keeps unusually often above one that is
  /// simply common everywhere. Within a type this orders the same way as a
  /// proper share-vs-share lift, since both denominators are constants.
  double get affinity => tag.count <= 0 ? 0 : comicCount / tag.count;
}

enum TagPreferenceSort {
  /// Most comics kept.
  count,

  /// Most over-represented against the whole site.
  affinity;

  static TagPreferenceSort fromName(String? value) {
    return TagPreferenceSort.values.firstWhere(
      (sort) => sort.name == value,
      orElse: () => TagPreferenceSort.count,
    );
  }
}
