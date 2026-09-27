import 'package:concept_nhv/widgets/glass_container.dart';
import 'package:flutter/material.dart';

/// Formats a raw favorites count into a compact display string.
/// e.g. 345 → "345", 12345 → "12.3k", 1234567 → "1.2M"
@visibleForTesting
String formatFavorites(int? count) {
  if (count == null || count <= 0) return '0';
  if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
  if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
  return '$count';
}

/// Animated top app-bar for the comic reader.
///
/// Shows a back button, optional favorites count, and the current page
/// indicator. Fades and slides in/out based on [visible].
class ReaderTopBar extends StatelessWidget {
  const ReaderTopBar({
    super.key,
    required this.visible,
    required this.currentPage,
    required this.totalPages,
    this.numFavorites,
    this.trailing,
  });

  final bool visible;
  final int currentPage;
  final int totalPages;

  /// The site's own favourite count — how popular the comic is, not whether
  /// this reader has kept it.
  final int? numFavorites;

  /// Sits at the far end, where the reader's own "keep this" control goes.
  /// A slot rather than a callback: the bar has no business knowing about
  /// favourites, models or comics.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, -1),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        // Use GlassContainer + Row instead of AppBar.
        // AppBar uses Material which, under loose Stack constraints, can
        // expand to fill the entire screen and intercept tap events.
        child: GlassContainer.bar(
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: kToolbarHeight,
              child: Row(
                children: [
                  const BackButton(color: Colors.white),
                  const Spacer(),
                  if (numFavorites != null) ...[
                    const Icon(
                      Icons.favorite,
                      color: Colors.redAccent,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formatFavorites(numFavorites),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    '$currentPage / $totalPages',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  if (trailing == null)
                    const SizedBox(width: 16)
                  else ...<Widget>[
                    const SizedBox(width: 4),
                    trailing!,
                    const SizedBox(width: 4),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
