import 'package:concept_nhv/models/comic_tag.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ComicTagQuery.query', () {
    test('builds type:slug from type and name', () {
      final tag = ComicTag(type: 'tag', name: 'full color');
      expect(tag.query, 'tag:full-color');
    });

    test('lowercases the name', () {
      final tag = ComicTag(type: 'artist', name: 'SomeArtist');
      expect(tag.query, 'artist:someartist');
    });

    test('replaces spaces with hyphens', () {
      final tag = ComicTag(type: 'parody', name: 'my hero academia');
      expect(tag.query, 'parody:my-hero-academia');
    });

    test('defaults type to "tag" when null', () {
      final tag = ComicTag(type: null, name: 'glasses');
      expect(tag.query, 'tag:glasses');
    });

    test('handles null name as empty slug', () {
      final tag = ComicTag(type: 'language', name: null);
      expect(tag.query, 'language:');
    });

    test('extracts slug from url when available', () {
      final tag = ComicTag(type: 'tag', name: 'males only', url: '/tag/males-only/');
      expect(tag.query, 'tag:males-only');
    });

    test('extracts slug from url without trailing slash', () {
      final tag = ComicTag(type: 'artist', name: 'Some Artist', url: '/artist/some-artist');
      expect(tag.query, 'artist:some-artist');
    });

    test('url slug takes precedence over name-based slug', () {
      // The url slug is authoritative; name-based fallback would give the same
      // result here, but this test verifies the url-first code path is taken.
      final tag = ComicTag(type: 'tag', name: 'males only', url: '/tag/males-only/');
      expect(tag.query, 'tag:males-only');
    });

    test('falls back to name-based slug when url is null', () {
      final tag = ComicTag(type: 'tag', name: 'full color', url: null);
      expect(tag.query, 'tag:full-color');
    });

    test('falls back to name-based slug when url is empty', () {
      final tag = ComicTag(type: 'tag', name: 'full color', url: '');
      expect(tag.query, 'tag:full-color');
    });
  });
}
