import 'package:concept_nhv/application/downloads/completed_page_window.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CompletedPageWindow window({
    required int itemCount,
    int anchorPage = 1,
    int? currentPage,
    int pageSize = 10,
  }) {
    return CompletedPageWindow.of(
      itemCount: itemCount,
      anchorPage: anchorPage,
      currentPage: currentPage ?? anchorPage,
      pageSize: pageSize,
    );
  }

  List<int> items(int count) => List<int>.generate(count, (i) => i);

  group('totalPages', () {
    test('is 1 for an empty list', () {
      // "Page 1 of 0" would be a jump bar with nowhere to jump.
      expect(window(itemCount: 0).totalPages, 1);
    });

    test('does not round a full page up to two', () {
      expect(window(itemCount: 10).totalPages, 1);
      expect(window(itemCount: 11).totalPages, 2);
      expect(window(itemCount: 20).totalPages, 2);
    });
  });

  group('the slice', () {
    test('is the whole list when it fits on one page', () {
      final w = window(itemCount: 7);

      expect(w.slice(items(7)), items(7));
      expect(w.showPageBar, isFalse, reason: 'nowhere to jump');
    });

    test('is one page when the reader jumped', () {
      // Jumping moves both ends, so only the page jumped to is shown.
      final w = window(itemCount: 25, anchorPage: 2);

      expect(w.slice(items(25)), <int>[10, 11, 12, 13, 14, 15, 16, 17, 18, 19]);
    });

    test('grows without moving its start when the reader scrolls on', () {
      // Revealing the next page must not hide the one above it, or the list
      // jumps under the reader's finger.
      final w = window(itemCount: 25, anchorPage: 2, currentPage: 3);

      expect(w.slice(items(25)).first, 10);
      expect(w.slice(items(25)).last, 24);
    });

    test('stops at the end of a partly filled last page', () {
      final w = window(itemCount: 23, anchorPage: 3);

      expect(w.slice(items(23)), <int>[20, 21, 22]);
    });

    test('survives the list shrinking under it', () {
      // Typing into the search field filters the list without resetting the
      // page, so the stored page can be past the end.
      final w = window(itemCount: 5, anchorPage: 9, currentPage: 9);

      expect(w.anchorPage, 1);
      expect(w.slice(items(5)), items(5));
    });

    test('is empty, not an error, for an empty list', () {
      expect(window(itemCount: 0, anchorPage: 4).slice(items(0)), isEmpty);
    });
  });

  group('showPageBar', () {
    test('appears only once there is a second page', () {
      expect(window(itemCount: 10).showPageBar, isFalse);
      expect(window(itemCount: 11).showPageBar, isTrue);
    });
  });
}
