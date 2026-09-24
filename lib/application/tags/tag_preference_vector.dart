import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// How strongly a comic matches the user's taste, as shown on a cover badge.
///
/// Two tiers rather than a number: the score's scale depends on the size and
/// shape of the user's library, so "92" would tell them nothing. See
/// .codex/phases/P84-preference-scoring.md.
enum PreferenceTier {
  none,

  /// At or above the 80th percentile of the user's own kept comics.
  gold,

  /// At or above the 95th percentile — rare by construction.
  platinum,
}

/// A weight per tag plus the two badge thresholds, built from the preference
/// ranking by [BuildTagPreferenceVectorUseCase].
@immutable
class TagPreferenceVector {
  const TagPreferenceVector({
    required this.weights,
    required this.goldThreshold,
    required this.platinumThreshold,
  });

  const TagPreferenceVector.empty()
    : weights = const <int, double>{},
      goldThreshold = null,
      platinumThreshold = null;

  /// Tag id to a weight in 0..1.
  final Map<int, double> weights;

  /// Null when the library is too small for percentiles to mean anything —
  /// with twenty comics the "95th percentile" is simply the best one, and a
  /// badge for it would be a badge for nothing. No thresholds, no badges.
  final double? goldThreshold;
  final double? platinumThreshold;

  bool get isEmpty => weights.isEmpty;

  /// Whether this vector can hand out badges at all.
  bool get canRank => goldThreshold != null && platinumThreshold != null;

  /// The average weight of the ranked tags this comic carries, dampened by
  /// the square root of how many there are.
  ///
  /// A plain sum was the first attempt and it failed on the real library: it
  /// ranked anthologies, which carry seventy-odd tags because they collect
  /// seventy-odd artists, above everything the user actually reads. Dividing
  /// by the count outright goes too far the other way — hitting five of the
  /// user's tags should beat hitting one — so the square root sits between
  /// the two, the way cosine similarity normalises by length.
  ///
  /// Only tags that carry weight count toward the divisor. Language, group
  /// and category ids are not part of the taste model, so they must not
  /// dilute a comic that happens to list them.
  double scoreComic(Iterable<int> tagIds) {
    if (weights.isEmpty) return 0;
    var total = 0.0;
    var matched = 0;
    final counted = <int>{};
    for (final tagId in tagIds) {
      if (!counted.add(tagId)) continue;
      final weight = weights[tagId];
      if (weight == null) continue;
      total += weight;
      matched++;
    }
    if (matched == 0) return 0;
    return total / math.sqrt(matched);
  }

  PreferenceTier tierFor(Iterable<int> tagIds) {
    final gold = goldThreshold;
    final platinum = platinumThreshold;
    if (gold == null || platinum == null) return PreferenceTier.none;
    final score = scoreComic(tagIds);
    // A comic with no tag ids scores zero. Thresholds can themselves be zero
    // on a library whose tags barely overlap, and a badge on every untagged
    // comic would be worse than no badge at all.
    if (score <= 0) return PreferenceTier.none;
    if (score >= platinum) return PreferenceTier.platinum;
    if (score >= gold) return PreferenceTier.gold;
    return PreferenceTier.none;
  }
}
