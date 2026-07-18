import 'package:flutter_test/flutter_test.dart';

import '../test_support/storage/sqlite_test_harness.dart';

void main() {
  group('SearchHistoryRepository', () {
    late SqliteTestHarness harness;

    setUp(() async {
      harness = SqliteTestHarness();
      await harness.initialize();
    });

    tearDown(() async {
      await harness.dispose();
    });

    test('saves and loads entries', () async {
      await harness.searchHistoryRepository.save('sample');

      final entries = await harness.searchHistoryRepository.load();

      expect(entries, hasLength(1));
      expect(entries.first.query, 'sample');
    });
  });
}
