import 'package:concept_nhv/models/local_tag_catalog_entry.dart';

/// A pair of tags the user keeps together more often than each tag's own
/// frequency would predict (P81).
class TagPairPreference {
  const TagPairPreference({
    required this.first,
    required this.second,
    required this.comicCount,
    required this.lift,
  });

  final LocalTagCatalogEntry first;
  final LocalTagCatalogEntry second;

  /// Kept comics carrying both tags.
  final int comicCount;

  /// Observed share over the share expected if the two were independent,
  /// both measured in the user's own library rather than site-wide: the
  /// question is whether *they* pair these tags, not whether the site does.
  /// 1.0 means "exactly as often as chance"; the numerator is a Wilson lower
  /// bound, so a pair seen five times cannot outrank one seen fifty.
  final double lift;
}
