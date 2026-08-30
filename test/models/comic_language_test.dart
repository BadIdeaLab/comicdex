import 'package:concept_nhv/models/comic_language.dart';
import 'package:concept_nhv/models/comic_tag.dart';
import 'package:flutter_test/flutter_test.dart';

ComicTag _tag(String type, String slug) {
  return ComicTag(type: type, name: slug, url: '/$type/$slug/');
}

void main() {
  group('primaryLanguageTag', () {
    test('finds the language among tags of other types', () {
      final tag = primaryLanguageTag(<ComicTag>[
        _tag('artist', 'someone'),
        _tag('tag', 'full-color'),
        _tag('language', 'chinese'),
        _tag('category', 'doujinshi'),
      ]);

      expect(tag?.slug, 'chinese');
    });

    test('skips translated and returns the real language', () {
      // A Chinese scanlation carries both, which is the whole reason this
      // function exists.
      final tag = primaryLanguageTag(<ComicTag>[
        _tag('language', 'chinese'),
        _tag('language', 'translated'),
      ]);

      expect(tag?.slug, 'chinese');
    });

    test('skips translated even when it comes first', () {
      // `translated` has no fixed position, so anything index-based would be
      // right most of the time and silently wrong the rest — exactly the kind
      // of bug that never gets reported.
      final tag = primaryLanguageTag(<ComicTag>[
        _tag('language', 'translated'),
        _tag('language', 'chinese'),
      ]);

      expect(tag?.slug, 'chinese');
    });

    test('returns null when translated is the only language tag', () {
      expect(
        primaryLanguageTag(<ComicTag>[_tag('language', 'translated')]),
        isNull,
      );
    });

    test('returns null when there is no language tag at all', () {
      expect(
        primaryLanguageTag(<ComicTag>[
          _tag('artist', 'someone'),
          _tag('tag', 'full-color'),
        ]),
        isNull,
      );
    });

    test('returns null for an empty tag list', () {
      // The ordinary case for cards built from stored comics, which carry no
      // tags at all.
      expect(primaryLanguageTag(const <ComicTag>[]), isNull);
    });

    test('takes the first of several real languages rather than crowding', () {
      // Rare, but two full names side by side would overflow the metadata row.
      final tag = primaryLanguageTag(<ComicTag>[
        _tag('language', 'japanese'),
        _tag('language', 'english'),
      ]);

      expect(tag?.slug, 'japanese');
    });

    test('tolerates a tag with no url by falling back to its name', () {
      final tag = primaryLanguageTag(<ComicTag>[
        ComicTag(type: 'language', name: 'chinese'),
      ]);

      expect(tag?.slug, 'chinese');
    });
  });

  group('primaryLanguageSlug', () {
    test('reads the language out of listing tag ids', () {
      // Search and favorites listings send `tag_ids` and no `tags` at all, so
      // this path is what every card on the home grid actually goes through.
      expect(primaryLanguageSlug(tagIds: <int>[29963]), 'chinese');
    });

    test('skips the translated id and keeps looking', () {
      expect(
        primaryLanguageSlug(tagIds: <int>[17249, 12227]),
        'english',
      );
    });

    test('resolves a real listing payload', () {
      // Verbatim `tag_ids` from GET /api/v2/galleries?page=1 for a gallery
      // titled "... [English] [XO Manga]". This exact list used to produce no
      // badge at all, because the mapper was reading a `tags` field the
      // endpoint never sends.
      final slug = primaryLanguageSlug(
        tagIds: <int>[
          166978, 141098, 138277, 35763, 35762, 33172, 29859, 29224,
          20925, 17249, 16643, 15782, 15408, 13720, 12227, 7240, 2515,
        ],
      );

      expect(slug, 'english');
    });

    test('prefers named tags over ids when both are present', () {
      // Named tags cover languages this build's id table may not know yet, so
      // they must not be shadowed by a stale table.
      final slug = primaryLanguageSlug(
        tags: <ComicTag>[_tag('language', 'japanese')],
        tagIds: <int>[29963],
      );

      expect(slug, 'japanese');
    });

    test('falls back to ids when the named tags name no language', () {
      final slug = primaryLanguageSlug(
        tags: <ComicTag>[_tag('tag', 'full-color')],
        tagIds: <int>[29963],
      );

      expect(slug, 'chinese');
    });

    test('returns null for ids that are not languages', () {
      // Ordinary content tags share the same id space; none of them may be
      // mistaken for a language.
      expect(primaryLanguageSlug(tagIds: <int>[166978, 35763]), isNull);
    });

    test('returns null when translated is the only language id', () {
      expect(primaryLanguageSlug(tagIds: <int>[17249, 35763]), isNull);
    });

    test('returns null when nothing is supplied at all', () {
      expect(primaryLanguageSlug(), isNull);
    });

    test('maps every bundled id to a non-empty slug', () {
      // Guards against a typo turning an id into an empty or duplicated label.
      expect(kLanguageTagIds.values.every((slug) => slug.isNotEmpty), isTrue);
      expect(
        kLanguageTagIds.values.toSet().length,
        kLanguageTagIds.length,
        reason: 'two ids must not claim the same language',
      );
    });
  });

  group('primaryLanguageCode', () {
    test('badges a listing payload with a two-letter code', () {
      expect(primaryLanguageCode(tagIds: <int>[17249, 29963]), 'ZH');
    });

    test('badges named tags too', () {
      expect(
        primaryLanguageCode(tags: <ComicTag>[_tag('language', 'japanese')]),
        'JA',
      );
    });

    test('gives textless no badge', () {
      // A comic with no text has no language to name, so it gets the same
      // nothing as a comic that names none — not an invented placeholder.
      expect(
        primaryLanguageCode(tags: <ComicTag>[_tag('language', 'textless')]),
        isNull,
      );
    });

    test('omits rather than guesses a code it does not know', () {
      // Guessing from the slug would be wrong often enough to matter and right
      // often enough to look trustworthy: `spanish` is `es`, `german` is `de`.
      expect(
        primaryLanguageCode(tags: <ComicTag>[_tag('language', 'spanish')]),
        isNull,
      );
    });

    test('returns null when there is no language at all', () {
      expect(primaryLanguageCode(), isNull);
    });

    test('every code is two upper-case letters and unique', () {
      for (final entry in kLanguageCodes.entries) {
        expect(
          entry.value,
          matches(RegExp(r'^[A-Z]{2}$')),
          reason: '${entry.key} has a malformed code',
        );
      }
      expect(
        kLanguageCodes.values.toSet().length,
        kLanguageCodes.length,
        reason: 'two languages must not share a code',
      );
    });

    test('every code names a language the id table can resolve', () {
      // Guards the two tables drifting apart: a code for a slug no id maps to
      // would never appear on a card from the home feed.
      final slugs = kLanguageTagIds.values.toSet();
      for (final slug in kLanguageCodes.keys) {
        expect(slugs, contains(slug), reason: '$slug has no tag id');
      }
    });
  });
}
