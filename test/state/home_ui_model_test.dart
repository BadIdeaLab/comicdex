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

    test('clears search text when leaving the index page', () {
      model.searchController.text = 'sample';

      model.setNavigationIndex(2);

      expect(model.navigationIndex, 2);
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
}
