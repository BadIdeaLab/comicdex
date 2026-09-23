import 'package:concept_nhv/state/home_ui_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomeUiModel', () {
    late HomeUiModel model;

    setUp(() {
      model = HomeUiModel();
    });

    tearDown(() {
      model.searchController.dispose();
      model.dispose();
    });

    test('keeps search text when leaving the index page', () {
      // Leaving used to clear it, which was harmless only while returning to
      // Home refetched from scratch. Now the results survive the trip, so
      // clearing the box would leave it empty above the very results it found.
      model.searchController.text = 'sample';

      model.setNavigationIndex(2);

      expect(model.navigationIndex, 2);
      expect(model.searchController.text, 'sample');
    });

    test('clears search text when tapping the index page while on it', () {
      // Still a deliberate gesture, and still the way back to the plain feed.
      model.searchController.text = 'sample';

      model.setNavigationIndex(0);

      expect(model.navigationIndex, 0);
      expect(model.searchController.text, isEmpty);
    });

    test('keeps search text when switching between non-index pages', () {
      model.setNavigationIndex(2);
      model.searchController.text = 'keep';

      model.setNavigationIndex(1);

      expect(model.navigationIndex, 1);
      expect(model.searchController.text, 'keep');
    });

    test('notifies listeners when loading state changes', () {
      var notificationCount = 0;
      model.addListener(() {
        notificationCount += 1;
      });

      model.setLoading(true);

      expect(model.isLoading, isTrue);
      expect(notificationCount, 1);
    });
  });

  group('downloads tag filters (P82)', () {
    test('adds ids once and switches to the Downloads tab', () {
      final model = HomeUiModel();
      addTearDown(model.dispose);

      model.filterDownloadsByTags(<int>[10, 11]);
      model.filterDownloadsByTags(<int>[10]);

      expect(model.downloadsTagIds, <int>[10, 11]);
      expect(model.navigationIndex, 1);
    });

    test('removing and clearing narrow back down', () {
      final model = HomeUiModel();
      addTearDown(model.dispose);
      model.filterDownloadsByTags(<int>[10, 11]);

      model.removeDownloadsTagFilter(10);
      expect(model.downloadsTagIds, <int>[11]);

      model.clearDownloadsTagFilters();
      expect(model.downloadsTagIds, isEmpty);
    });

    test('the exposed list cannot be mutated from outside', () {
      final model = HomeUiModel();
      addTearDown(model.dispose);
      model.filterDownloadsByTags(<int>[10]);

      expect(() => model.downloadsTagIds.add(11), throwsUnsupportedError);
    });

    test('notifies on every change', () {
      final model = HomeUiModel();
      addTearDown(model.dispose);
      var notifications = 0;
      model.addListener(() => notifications++);

      model.filterDownloadsByTags(<int>[10]);
      model.removeDownloadsTagFilter(10);
      model.clearDownloadsTagFilters(); // already empty: no notification

      expect(notifications, 2);
    });
  });
}
