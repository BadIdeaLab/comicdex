import 'package:concept_nhv/models/comic_tag.dart';

/// The slug nhentai uses for "this is a translation", which is filed under the
/// same `language` type as the real languages.
const String kTranslatedLanguageSlug = 'translated';

/// Every `language`-type tag nhentai defines, keyed by its numeric tag id.
///
/// The listing endpoint (`/api/v2/galleries`) returns **`tag_ids`** — bare
/// integers — and never the `tags` objects the detail endpoint returns, so a
/// card straight off the feed has nothing to read a language *name* out of.
/// The full set is small (fourteen entries, a single page of
/// `/api/v2/tags/language`) and these ids are immutable database keys, so the
/// table is bundled instead of fetched: no request, no cache, no schema.
///
/// If nhentai ever adds a language, comics tagged with it simply show no badge
/// until this map is extended. That failure mode is deliberate — an unknown id
/// can never be mislabelled as the wrong language, only omitted.
const Map<int, String> kLanguageTagIds = <int, String>{
  6346: 'japanese',
  17249: kTranslatedLanguageSlug,
  29963: 'chinese',
  12227: 'english',
  145695: 'ukrainian',
  165194: 'textless',
  165826: 'textless-narrative',
  160067: 'hebrew',
  141693: 'arabic',
  163209: 'khmer',
  158626: 'romanian',
  156976: 'greek',
  145530: 'turkish',
  142066: 'czech',
};

/// The comic's language tag, or null when it does not name one.
///
/// nhentai files `translated` under the `language` type alongside `japanese`,
/// `english` and `chinese`, so a Chinese scanlation carries **two** language
/// tags. Taking "the language tag" would therefore be a coin flip between the
/// answer the reader wants and a word that is true of thousands of comics.
///
/// Two things this deliberately does *not* do:
///
/// * It does not take the first or last entry and hope. `translated` has no
///   fixed position in the list, so an index-based shortcut would be right most
///   of the time and wrong without warning — the worst kind of bug to find.
/// * It does not invent a placeholder when nothing matches. A card with no
///   language should show nothing at all; "unknown" is noise on every untagged
///   comic in the grid.
ComicTag? primaryLanguageTag(List<ComicTag> tags) {
  for (final tag in tags) {
    if (tag.type != 'language') continue;
    if (tag.slug == kTranslatedLanguageSlug) continue;
    return tag;
  }
  return null;
}

/// The comic's language slug, or null when it does not name one.
///
/// Takes both shapes because the two endpoints disagree: search and favorites
/// listings carry [tagIds] only, while comic details (and anything opened from
/// the tag sheet) carry full [tags]. Named tags win when present — they are the
/// richer source, and they cover languages this build's [kLanguageTagIds] may
/// not know yet.
String? primaryLanguageSlug({
  List<ComicTag> tags = const <ComicTag>[],
  List<int> tagIds = const <int>[],
}) {
  final tag = primaryLanguageTag(tags);
  if (tag != null) {
    return tag.slug;
  }
  for (final id in tagIds) {
    final slug = kLanguageTagIds[id];
    if (slug == null || slug == kTranslatedLanguageSlug) continue;
    return slug;
  }
  return null;
}

/// ISO 639-1 codes for the languages worth badging, keyed by nhentai slug.
///
/// Deliberately not flags. A flag names a country, not a language: `chinese`
/// would have to pick between 🇨🇳 and 🇹🇼, `english` between 🇬🇧 and 🇺🇸, and
/// `arabic` between twenty-two of them — so the badge would be wrong for some
/// readers by construction. Two letters are also legible at 11 px, which a
/// tricolour is not, and they render identically on every platform.
///
/// `textless` and `textless-narrative` are absent on purpose: a comic with no
/// text has no language to name, so it gets no badge, the same as a comic that
/// names none at all. Anything missing here is likewise omitted rather than
/// guessed — the first two letters of a slug are the right ISO code often
/// enough to look reliable and not often enough to be (`spanish` is `es`,
/// `german` is `de`).
const Map<String, String> kLanguageCodes = <String, String>{
  'japanese': 'JA',
  'chinese': 'ZH',
  'english': 'EN',
  'ukrainian': 'UK',
  'hebrew': 'HE',
  'arabic': 'AR',
  'khmer': 'KM',
  'romanian': 'RO',
  'greek': 'EL',
  'turkish': 'TR',
  'czech': 'CS',
};

/// The two-letter code to badge this comic with, or null for no badge.
String? primaryLanguageCode({
  List<ComicTag> tags = const <ComicTag>[],
  List<int> tagIds = const <int>[],
}) {
  final slug = primaryLanguageSlug(tags: tags, tagIds: tagIds);
  if (slug == null) {
    return null;
  }
  return kLanguageCodes[slug];
}
