import 'package:concept_nhv/models/local_tag_catalog_entry.dart';

/// Two or three tags the user keeps together more often than each tag's own
/// frequency predicts (P83) — a taste combination, read as one line.
class TagCombination {
  const TagCombination({
    required this.members,
    required this.comicCount,
    required this.lift,
  });

  /// Two or three tags, in the order they should be read.
  final List<LocalTagCatalogEntry> members;

  /// Kept comics carrying all of them.
  final int comicCount;

  /// Observed share over the share expected if the tags landed on comics
  /// independently, both measured in the user's own library rather than
  /// site-wide: the question is whether *they* combine these tags, not
  /// whether the site does. 1.0 is exactly chance; the numerator is a Wilson
  /// lower bound, so a combination seen five times cannot outrank one seen
  /// fifty.
  final double lift;

  List<int> get tagIds => <int>[
    for (final member in members)
      if (member.id != null) member.id!,
  ];

  /// The home page ANDs multiple tag queries, so a combination is just its
  /// members' queries.
  List<String> get searchQueries =>
      members.map((member) => member.query).toList(growable: false);
}
