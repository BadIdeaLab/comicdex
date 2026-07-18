import 'package:concept_nhv/models/comic_language.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ComicLanguage', () {
    test('returns primary query and fallback queries', () {
      expect(ComicLanguage.chinese.apiQuery, 'language:chinese');
      expect(ComicLanguage.chinese.fallbackQueries, const <String>[
        '-language:english -language:japanese',
      ]);
      expect(ComicLanguage.english.fallbackQueries, isEmpty);
    });
  });
}
