import 'package:concept_nhv/application/search/blocked_tags_repository.dart';
import 'package:concept_nhv/application/tags/load_tag_preferences_use_case.dart';
import 'package:concept_nhv/application/tags/preference_statistics.dart';
import 'package:concept_nhv/models/local_tag_catalog_entry.dart';
import 'package:concept_nhv/models/tag_pair_preference.dart';
import 'package:concept_nhv/services/local_tag_catalog_service.dart';
import 'package:concept_nhv/storage/comic_tag_repository.dart';

/// Ranks tag pairs by how much more often they are kept together than each
/// tag's own frequency predicts. See .codex/phases/P81-analysis-page-and-cooccurrence.md.
class LoadTagCooccurrenceUseCase {
  const LoadTagCooccurrenceUseCase({
    required this.comicTagRepository,
    required this.localTagCatalogService,
    required this.blockedTagsRepository,
    this.limit = 30,
  });

  final ComicTagRepository comicTagRepository;
  final LocalTagCatalogService localTagCatalogService;
  final BlockedTagsRepository blockedTagsRepository;

  /// Pairs to return; the tail is a long list of near-chance combinations.
  final int limit;

  Future<List<TagPairPreference>> execute() async {
    final pairs = await comicTagRepository.loadTagPairCounts();
    if (pairs.isEmpty) return const <TagPairPreference>[];

    final keptComics = await comicTagRepository.loadKeptComicCount();
    if (keptComics <= 0) return const <TagPairPreference>[];

    final counts = <int, int>{
      for (final count in await comicTagRepository.loadTagSourceCounts())
        count.tagId: count.collectedCount,
    };
    final blocked = (await blockedTagsRepository.loadBlockedTags()).toSet();

    final ranked = <TagPairPreference>[];
    for (final pair in pairs) {
      final first = _rankableTag(pair.tagA, blocked);
      final second = _rankableTag(pair.tagB, blocked);
      if (first == null || second == null) continue;

      final countA = counts[pair.tagA] ?? 0;
      final countB = counts[pair.tagB] ?? 0;
      if (countA <= 0 || countB <= 0) continue;

      // Expected share if the two tags landed on comics independently.
      final expected = (countA / keptComics) * (countB / keptComics);
      if (expected <= 0) continue;

      ranked.add(
        TagPairPreference(
          first: first,
          second: second,
          comicCount: pair.comicCount,
          lift: wilsonLowerBound(pair.comicCount, keptComics) / expected,
        ),
      );
    }

    ranked.sort((a, b) {
      final byLift = b.lift.compareTo(a.lift);
      return byLift != 0 ? byLift : b.comicCount.compareTo(a.comicCount);
    });
    return ranked.take(limit).toList(growable: false);
  }

  /// Null when the tag has no catalog entry (`group`/`category`, which the
  /// catalog omits), is a language, or is blocked — the same exclusions the
  /// ranking applies, so the two sections cannot disagree about a tag.
  LocalTagCatalogEntry? _rankableTag(int tagId, Set<String> blocked) {
    final tag = localTagCatalogService.entryById(tagId);
    if (tag == null) return null;
    if (!LoadTagPreferencesUseCase.rankedTypes.contains(tag.type)) return null;
    if (blocked.contains(tag.query)) return null;
    return tag;
  }
}

/// Convenience for the search entry point: the home page ANDs multiple tag
/// queries, so a pair is just two queries.
extension TagPairQueries on TagPairPreference {
  List<String> get searchQueries => <String>[first.query, second.query];
}
