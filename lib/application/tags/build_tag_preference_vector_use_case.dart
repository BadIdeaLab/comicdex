import 'dart:math' as math;

import 'package:concept_nhv/application/tags/load_tag_preferences_use_case.dart';
import 'package:concept_nhv/application/tags/tag_preference_vector.dart';
import 'package:concept_nhv/models/tag_preference_entry.dart';
import 'package:concept_nhv/storage/comic_tag_repository.dart';

/// Turns the tag ranking into a scoring vector. See
/// .codex/phases/P84-preference-scoring.md.
class BuildTagPreferenceVectorUseCase {
  const BuildTagPreferenceVectorUseCase({
    required this.loadTagPreferencesUseCase,
    required this.comicTagRepository,
    this.minimumLibrary = 50,
    this.weightPercentile = 0.90,
  });

  final LoadTagPreferencesUseCase loadTagPreferencesUseCase;
  final ComicTagRepository comicTagRepository;

  /// Below this many kept comics no badge is awarded: a ranking built
  /// from a handful of comics describes the handful, not a taste.
  final int minimumLibrary;

  /// The affinity that counts as a full-weight tag; anything above it is
  /// capped. See [_buildWeights].
  final double weightPercentile;

  /// Badge thresholds, measured against the population the badges are shown
  /// to: the home feed.
  ///
  /// The first attempt cut them from the kept library — the 80th and 95th
  /// percentile of what the user already keeps — and no comic on the home
  /// feed ever reached them. That is not a bug in the numbers, it is the
  /// wrong population: a library is by construction full of its owner's
  /// favourite tags, so "the top 5% of your library" is a bar the open site
  /// almost never clears. Measured over 300 comics of real feed, the same
  /// statistic scored median 0.20, p90 0.32, p98 0.45, max 0.62, against a
  /// library-derived gold bar of 0.72.
  ///
  /// These two land near the feed's 95th and 99th percentile. In use that
  /// came out slightly rarer — a gold or platinum every few pages — and
  /// around two thirds of what they marked were comics the user would open.
  ///
  /// They are calibrated constants, not derived ones, so as the library
  /// grows and the weights shift they will drift. Re-measuring means scoring
  /// a few hundred feed comics against the current weights; the throwaway
  /// readout that did it the first time is in the P84 plan's history.
  static const double goldThreshold = 0.40;
  static const double platinumThreshold = 0.55;

  Future<TagPreferenceVector> execute() async {
    final grouped = await loadTagPreferencesUseCase.execute();
    final entries = <TagPreferenceEntry>[
      for (final bucket in grouped.values) ...bucket,
    ];
    final weights = _buildWeights(entries);
    if (weights.isEmpty) return const TagPreferenceVector.empty();

    final keptComics = await comicTagRepository.loadKeptComicCount();
    if (keptComics < minimumLibrary) {
      // Scoring still works — Downloads can sort by it — but a badge claims
      // the comic stands out, and a handful of comics cannot support that.
      return TagPreferenceVector(
        weights: weights,
        goldThreshold: null,
        platinumThreshold: null,
      );
    }

    return TagPreferenceVector(
      weights: weights,
      goldThreshold: goldThreshold,
      platinumThreshold: platinumThreshold,
    );
  }

  /// `affinity / p90(affinity)`, capped at 1.
  ///
  /// The point of ranking by affinity (P79) is that a tag on two hundred
  /// thousand galleries site-wide says almost nothing about taste, so its
  /// weight should be almost nothing. Measured on the real library, this
  /// keeps it that way: `full-color` lands at 0.04 and `big-breasts` at
  /// 0.01, against 0.34 and 0.16 under the log scale this replaced.
  ///
  /// Dividing by the maximum instead of a high percentile was the other
  /// candidate, and it hands the single rarest artist a weight of 1.0 while
  /// everything else collapses toward zero. The percentile lets the whole top
  /// of the ranking count as "strongly yours" without one outlier setting the
  /// scale for everyone.
  Map<int, double> _buildWeights(List<TagPreferenceEntry> entries) {
    final affinities = <double>[
      for (final entry in entries)
        if (entry.tag.id != null && entry.affinity > 0) entry.affinity,
    ]..sort();
    if (affinities.isEmpty) return const <int, double>{};

    final pivot =
        affinities[((affinities.length - 1) * weightPercentile).round()];
    if (pivot <= 0) return const <int, double>{};

    return <int, double>{
      for (final entry in entries)
        if (entry.tag.id != null && entry.affinity > 0)
          entry.tag.id!: math.min(1.0, entry.affinity / pivot),
    };
  }
}
