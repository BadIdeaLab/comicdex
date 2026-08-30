import 'package:flutter/material.dart';

/// Identifies the language chip so tests can assert on its presence directly,
/// rather than on "the card happens to build exactly one Container".
const Key languageBadgeKey = Key('comic-card-language');

/// The comic's language, drawn over the top-left corner of its cover.
///
/// It started out beside the page count and could not stay there. The metadata
/// row is bounded by two `IconButton`s, and keeping the page count exactly
/// centred leaves the chip only half of what remains: about 31 px on a 180 px
/// card, and roughly 10 px on the 133 px cards a phone shows in portrait. The
/// first attempt squeezed the chip to its own padding and rendered a row of
/// **empty grey boxes** — and `find.text` still reported the label as present,
/// so every widget test passed.
///
/// Over the cover there is no such competition: the badge is legible at any
/// column count, the page count keeps the exact centring it always had, and the
/// language sits where the eye already is while scanning covers.
class ComicLanguageBadge extends StatelessWidget {
  const ComicLanguageBadge({super.key, required this.label});

  /// A two-letter ISO 639-1 code — see `kLanguageCodes`.
  final String label;

  @override
  Widget build(BuildContext context) {
    // Dark plate rather than a theme colour: this sits on artwork of unknown
    // brightness, so it cannot rely on the surface it happens to land on.
    return Positioned(
      top: 6,
      left: 6,
      child: IgnorePointer(
        child: Container(
          key: languageBadgeKey,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(150),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            maxLines: 1,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              height: 1.1,
              fontWeight: FontWeight.w600,
              // Latin caps this small read as a block without tracking.
              letterSpacing: 0.6,
            ),
          ),
        ),
      ),
    );
  }
}
