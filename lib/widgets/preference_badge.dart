import 'package:concept_nhv/application/tags/tag_preference_vector.dart';
import 'package:flutter/material.dart';

/// Identify each tier directly, so tests assert on "a platinum badge" rather
/// than on the card happening to build one more decorated box.
const Key platinumBadgeKey = Key('comic-card-preference-platinum');
const Key goldBadgeKey = Key('comic-card-preference-gold');

/// Marks a comic whose tags score in the top of the user's own library (P84).
///
/// Placed bottom-right of the cover: top-left belongs to the language badge
/// (P70) and top-right to the selection circle, neither of which may be
/// covered.
class PreferenceBadge extends StatelessWidget {
  const PreferenceBadge({super.key, required this.tier});

  final PreferenceTier tier;

  /// A holographic sheen, not a rainbow.
  ///
  /// The white stops between the pastels are what makes the difference: a
  /// continuous run of hues reads as a printed rainbow, while hues separated
  /// by white read as light moving across a surface. Keeping the pastels
  /// desaturated matters for the same reason — at 20 logical pixels a
  /// saturated gradient turns into coloured mud.
  static const List<Color> _platinumSheen = <Color>[
    Color(0xF2FFFFFF),
    Color(0xE0C9ECF6),
    Color(0xF2FFFFFF),
    Color(0xE0DACFF3),
    Color(0xF7FFFFFF),
    Color(0xE0F8D6E6),
    Color(0xF2FFFFFF),
    Color(0xE0F2E8C9),
    Color(0xEAFFFFFF),
  ];

  static const List<Color> _goldPlate = <Color>[
    Color(0xFFFFF0B8),
    Color(0xFFF0C862),
    Color(0xFFD9A036),
    Color(0xFFC08A26),
  ];

  @override
  Widget build(BuildContext context) {
    if (tier == PreferenceTier.none) return const SizedBox.shrink();
    final isPlatinum = tier == PreferenceTier.platinum;

    return Positioned(
      right: 6,
      bottom: 6,
      child: IgnorePointer(
        child: Container(
          key: isPlatinum ? platinumBadgeKey : goldBadgeKey,
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            // 45°, so the sheen runs corner to corner across the plate.
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isPlatinum ? _platinumSheen : _goldPlate,
            ),
            borderRadius: BorderRadius.circular(6),
            // Both plates are light, and a cover can be any brightness at
            // all. Without the rim and the drop shadow the badge dissolves
            // into a pale cover — the same reason the language badge sits on
            // a dark plate.
            border: Border.all(
              color: isPlatinum
                  ? const Color(0xCCFFFFFF)
                  : const Color(0xCCFFF3CC),
            ),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x73000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Icon(
            // Different glyphs, not only different colours: gold and platinum
            // are indistinguishable to a colour-blind viewer, and a low
            // saturation sheen is hard to read at this size for anyone.
            isPlatinum ? Icons.diamond : Icons.star,
            size: 13,
            // Dark on a light plate. A white glyph, which the plan first
            // assumed, would vanish into the sheen.
            color: isPlatinum
                ? const Color(0xFF4A5A6B)
                : const Color(0xFF6B4A12),
          ),
        ),
      ),
    );
  }
}
