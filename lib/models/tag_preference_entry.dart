import 'package:concept_nhv/models/local_tag_catalog_entry.dart';

/// One ranked tag in the preference analysis (P78).
class TagPreferenceEntry {
  const TagPreferenceEntry({
    required this.tag,
    required this.comicCount,
    required this.favoriteCount,
    required this.downloadedCount,
    required this.affinity,
  });

  final LocalTagCatalogEntry tag;

  /// Comics carrying this tag that are favorited or downloaded, counted once
  /// even when they are both.
  final int comicCount;

  final int favoriteCount;
  final int downloadedCount;

  /// How over-represented the tag is compared to the whole site, computed by
  /// [LoadTagPreferencesUseCase]: a conservative estimate of the user's share
  /// (Wilson lower bound) divided by the tag's site-wide count plus a prior,
  /// so neither a tag seen on three comics nor one that barely exists
  /// site-wide can top the ranking on thin evidence (P79). The site-wide
  /// grand total cancels out, which is just as well — it is not available.
  final double affinity;
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
