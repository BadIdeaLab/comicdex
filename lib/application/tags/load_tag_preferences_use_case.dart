import 'package:concept_nhv/application/search/blocked_tags_repository.dart';
import 'package:concept_nhv/application/tags/preference_statistics.dart';
import 'package:concept_nhv/models/tag_catalog_type.dart';
import 'package:concept_nhv/models/tag_preference_entry.dart';
import 'package:concept_nhv/services/local_tag_catalog_service.dart';
import 'package:concept_nhv/storage/comic_tag_repository.dart';

/// Ranks the tags of the comics the user kept — favorited or downloaded —
/// grouped by tag type. See .codex/phases/P78-tag-preference-analysis.md.
class LoadTagPreferencesUseCase {
  const LoadTagPreferencesUseCase({
    required this.comicTagRepository,
    required this.localTagCatalogService,
    required this.blockedTagsRepository,
    this.minimumComics = 3,
  });

  final ComicTagRepository comicTagRepository;
  final LocalTagCatalogService localTagCatalogService;
  final BlockedTagsRepository blockedTagsRepository;

  /// Tags on fewer comics than this are noise, not preference.
  final int minimumComics;

  /// Added to a tag's site-wide count before dividing, so a tag that barely
  /// exists site-wide cannot top the ranking on three comics.
  ///
  /// The Wilson bound only discounts *the user's* small sample; the divisor
  /// is a small sample too. An artist with five galleries site-wide is a
  /// genuine find when the user kept all five, and noise when they kept
  /// three — this asks rare tags for more evidence instead of cutting them
  /// off at a threshold.
  static const int siteWidePrior = 30;

  /// Types worth ranking. `language` says nothing about taste, and
  /// `group`/`category` ids resolve to nothing because the catalog omits them.
  static const List<TagCatalogType> rankedTypes = <TagCatalogType>[
    TagCatalogType.tag,
    TagCatalogType.artist,
    TagCatalogType.parody,
    TagCatalogType.character,
  ];

  Future<Map<TagCatalogType, List<TagPreferenceEntry>>> execute({
    TagPreferenceSort sort = TagPreferenceSort.count,
  }) async {
    final counts = await comicTagRepository.loadTagSourceCounts();
    final keptComics = await comicTagRepository.loadKeptComicCount();
    final blocked = (await blockedTagsRepository.loadBlockedTags()).toSet();

    final grouped = <TagCatalogType, List<TagPreferenceEntry>>{
      for (final type in rankedTypes) type: <TagPreferenceEntry>[],
    };

    for (final count in counts) {
      if (count.collectedCount < minimumComics) continue;
      final tag = localTagCatalogService.entryById(count.tagId);
      if (tag == null) continue;
      final bucket = grouped[tag.type];
      if (bucket == null) continue;
      if (blocked.contains(tag.query)) continue;
      bucket.add(
        TagPreferenceEntry(
          tag: tag,
          comicCount: count.collectedCount,
          favoriteCount: count.favoriteCount,
          downloadedCount: count.downloadedCount,
          affinity: tag.count <= 0
              ? 0
              : wilsonLowerBound(count.collectedCount, keptComics) /
                    (tag.count + siteWidePrior),
        ),
      );
    }

    for (final entries in grouped.values) {
      entries.sort((a, b) {
        final primary = sort == TagPreferenceSort.count
            ? b.comicCount.compareTo(a.comicCount)
            : b.affinity.compareTo(a.affinity);
        if (primary != 0) return primary;
        // Ties look arbitrary otherwise; the more-kept tag reads as "higher".
        final byCount = b.comicCount.compareTo(a.comicCount);
        return byCount != 0 ? byCount : a.tag.name.compareTo(b.tag.name);
      });
    }

    return grouped;
  }
}
