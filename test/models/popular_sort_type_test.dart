import 'package:concept_nhv/models/popular_sort_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PopularSortType', () {
    test('exposes API values', () {
      expect(PopularSortType.allTime.apiValue, 'popular');
      expect(PopularSortType.month.apiValue, 'popular-month');
    });
  });
}
