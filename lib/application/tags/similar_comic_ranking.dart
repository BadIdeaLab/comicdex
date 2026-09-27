import 'package:concept_nhv/application/tags/comic_similarity.dart';
import 'package:concept_nhv/application/tags/tag_preference_vector.dart';
import 'package:concept_nhv/services/local_tag_catalog_service.dart';

/// How many similar comics to offer.
///
/// Never padded up to this number: recommendation quality falls away fast, so
/// filling a tablet's wider row with the twelfth-best match makes the list
/// worse rather than longer.
const int similarComicsLimit = 6;

/// How alike two comics have to be before one is worth offering.
///
/// Shared by the library and the online lookup **on purpose**. The two lists
/// sit next to each other on the same page, so a threshold tuned in one place
/// and forgotten in the other would show two visibly different standards with
/// nothing to flag it. Change it here and both move.
const double minimumComicSimilarity = 0.15;

/// Builds the similarity for a group of comics, reading each tag's site-wide
/// count from the catalog.
///
/// [tagGroups] is every comic's tag ids, including the one being compared
/// against: the weights have to cover both sides.
///
/// Tags the catalog cannot resolve are left out rather than given a weight of
/// zero, so "we both carry some id nobody can name" never counts as evidence
/// that two comics belong together.
ComicSimilarity buildComicSimilarity({
  required LocalTagCatalogService catalog,
  required Iterable<Iterable<int>> tagGroups,
}) {
  final siteCounts = <int, int>{};
  for (final tagIds in tagGroups) {
    for (final tagId in tagIds) {
      if (siteCounts.containsKey(tagId)) continue;
      final entry = catalog.entryById(tagId);
      if (entry == null) continue;
      siteCounts[tagId] = entry.count;
    }
  }
  return ComicSimilarity.fromSiteCounts(
    siteCounts,
    referenceCount: catalog.maxCount,
  );
}

/// A candidate with everything the ranking needs, whatever it was built from.
///
/// The library lookup carries stored rows and the online one carries API
/// results; keeping the scored shape identical is what lets them share one
/// comparator instead of maintaining two that have to agree.
class ScoredComic<T> {
  const ScoredComic({
    required this.subject,
    required this.id,
    required this.similarity,
    required this.sharedTagIds,
    required this.tagIds,
  });

  final T subject;
  final String id;
  final double similarity;

  /// The strongest shared tags, for the line explaining why this is here.
  final List<int> sharedTagIds;

  /// Every tag id on the candidate, used to score it against the reader's
  /// preferences.
  final List<int> tagIds;
}

/// Orders candidates and cuts the list to [similarComicsLimit].
///
/// Similarity decides; [preferences] only break ties. Multiplying preference
/// in would let a comic the reader merely likes displace one that actually
/// resembles what they just finished, which is the opposite of what this page
/// is for.
List<ScoredComic<T>> rankSimilar<T>(
  List<ScoredComic<T>> scored, {
  TagPreferenceVector? preferences,
  int limit = similarComicsLimit,
}) {
  double preferenceOf(ScoredComic<T> candidate) =>
      preferences?.scoreComic(candidate.tagIds) ?? 0;

  final ordered = List<ScoredComic<T>>.of(scored)
    ..sort((a, b) {
      final bySimilarity = b.similarity.compareTo(a.similarity);
      if (bySimilarity != 0) return bySimilarity;
      final byPreference = preferenceOf(b).compareTo(preferenceOf(a));
      // Falls back to the id so the order never depends on how the candidates
      // happened to be collected.
      return byPreference != 0 ? byPreference : a.id.compareTo(b.id);
    });
  return ordered.take(limit).toList(growable: false);
}
