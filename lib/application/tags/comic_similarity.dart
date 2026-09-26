import 'dart:math' as math;

/// How alike two comics are, judged by the tags they share.
///
/// See .codex/phases/P92-similar-comics-end-page.md.
class ComicSimilarity {
  const ComicSimilarity({required Map<int, double> idfByTagId})
    : _idf = idfByTagId;

  /// Builds the weights from each tag's site-wide count.
  ///
  /// [referenceCount] is the largest count in the catalog, so the single most
  /// common tag on the site weighs nothing: two comics both being full colour
  /// says nothing about them being alike.
  factory ComicSimilarity.fromSiteCounts(
    Map<int, int> siteCountByTagId, {
    required int referenceCount,
  }) {
    return ComicSimilarity(
      idfByTagId: <int, double>{
        for (final entry in siteCountByTagId.entries)
          entry.key: tagIdf(
            siteCount: entry.value,
            referenceCount: referenceCount,
          ),
      },
    );
  }

  final Map<int, double> _idf;

  /// Cosine similarity of the two tag sets, each tag weighted by its idf.
  ///
  /// The division is what stops a comic being similar to everything. An
  /// anthology collects seventy-odd artists and so shares a tag with almost
  /// anything; without normalising by each side's own magnitude those
  /// anthologies take every top spot. P84 learned this the hard way when a
  /// plain sum put COMIC BAVEL above everything the user actually reads.
  ///
  /// Tags with no known site-wide count are skipped rather than treated as
  /// weightless, so "we both have some tag nobody can identify" never counts
  /// as evidence.
  double between(Iterable<int> a, Iterable<int> b) {
    final left = _weights(a);
    if (left.isEmpty) return 0;
    final right = _weights(b);
    if (right.isEmpty) return 0;

    var dot = 0.0;
    final smaller = left.length <= right.length ? left : right;
    final larger = identical(smaller, left) ? right : left;
    for (final entry in smaller.entries) {
      final other = larger[entry.key];
      if (other == null) continue;
      dot += entry.value * other;
    }
    if (dot <= 0) return 0;

    final norm = math.sqrt(_squaredNorm(left)) * math.sqrt(_squaredNorm(right));
    if (norm <= 0) return 0;
    return dot / norm;
  }

  /// The shared tags that contributed most, strongest first.
  ///
  /// Shown as the reason under a recommendation: a row of covers with no
  /// explanation reads as a random fill, and the answer is already computed.
  List<int> strongestSharedTags(
    Iterable<int> a,
    Iterable<int> b, {
    int limit = 2,
  }) {
    final left = _weights(a);
    final shared = <MapEntry<int, double>>[
      for (final tagId in _weights(b).keys)
        if (left.containsKey(tagId)) MapEntry(tagId, left[tagId]!),
    ]..sort((x, y) => y.value.compareTo(x.value));
    return <int>[for (final entry in shared.take(limit)) entry.key];
  }

  Map<int, double> _weights(Iterable<int> tagIds) {
    final weights = <int, double>{};
    for (final tagId in tagIds) {
      final idf = _idf[tagId];
      if (idf == null || idf <= 0) continue;
      weights[tagId] = idf;
    }
    return weights;
  }

  static double _squaredNorm(Map<int, double> weights) {
    var total = 0.0;
    for (final weight in weights.values) {
      total += weight * weight;
    }
    return total;
  }
}

/// Inverse document frequency for a tag.
///
/// Returns 0 for a tag at or above [referenceCount] — it cannot tell anything
/// apart — and grows as the tag gets rarer.
double tagIdf({required int siteCount, required int referenceCount}) {
  if (referenceCount <= 0 || siteCount < 0) return 0;
  final ratio = referenceCount / (siteCount + 1);
  return ratio <= 1 ? 0 : math.log(ratio);
}
