import 'package:concept_nhv/services/tag_search_query_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('build normalizes, deduplicates, and sorts tag queries', () {
    const builder = TagSearchQueryBuilder();

    final query = builder.build(<String>[
      ' tag:Full-Color ',
      'language:chinese',
      'tag:full-color',
      '',
    ]);

    expect(query, 'language:chinese tag:full-color');
  });
}
