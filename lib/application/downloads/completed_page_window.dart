/// Which slice of the completed downloads is on screen.
///
/// `[anchorPage, currentPage]` is a continuously-revealed range, not a single
/// page: jumping resets both to the same page, while scrolling to the end
/// only advances [currentPage], so pages already revealed stay visible. This
/// mirrors the home feed.
///
/// A value type rather than seven locals in `build`, because it is all
/// off-by-one arithmetic and the only way to reach it there is through a
/// widget test that happens to have the right number of comics.
class CompletedPageWindow {
  const CompletedPageWindow._({
    required this.totalPages,
    required this.anchorPage,
    required this.currentPage,
    required this.start,
    required this.end,
    required this.showPageBar,
  });

  /// [anchorPage] and [currentPage] are taken as the user left them and
  /// clamped here: the list shrinks under them whenever a filter is typed or
  /// a download is deleted, and neither is reset when it does.
  factory CompletedPageWindow.of({
    required int itemCount,
    required int anchorPage,
    required int currentPage,
    required int pageSize,
  }) {
    final totalPages = itemCount == 0
        ? 1
        : (itemCount + pageSize - 1) ~/ pageSize;
    final clampedAnchor = anchorPage.clamp(1, totalPages);
    final clampedCurrent = currentPage.clamp(1, totalPages);
    return CompletedPageWindow._(
      totalPages: totalPages,
      anchorPage: clampedAnchor,
      currentPage: clampedCurrent,
      start: (clampedAnchor - 1) * pageSize,
      end: (clampedCurrent * pageSize).clamp(0, itemCount),
      showPageBar: itemCount > pageSize,
    );
  }

  /// Always at least 1, so an empty list still reads as "page 1 of 1" rather
  /// than as a bar with no pages in it.
  final int totalPages;

  final int anchorPage;
  final int currentPage;

  /// Index bounds into the completed list.
  final int start;
  final int end;

  /// False when everything fits on one page: a jump bar that cannot jump
  /// anywhere is noise.
  final bool showPageBar;

  List<T> slice<T>(List<T> items) => items.sublist(start, end);
}
