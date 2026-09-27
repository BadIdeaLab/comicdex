import 'package:concept_nhv/application/feed/search_comics_use_case.dart';
import 'package:concept_nhv/application/search/blocked_tags_repository.dart';
import 'package:concept_nhv/application/tags/similar_comic_ranking.dart';
import 'package:concept_nhv/application/tags/tag_preference_vector.dart';
import 'package:concept_nhv/models/comic.dart';
import 'package:concept_nhv/models/local_tag_catalog_entry.dart';
import 'package:concept_nhv/services/local_tag_catalog_service.dart';
import 'package:concept_nhv/storage/comic_tag_repository.dart';

/// One comic found on the site, with what it has in common with the one just
/// read.
class OnlineSimilarComic {
  const OnlineSimilarComic({
    required this.comic,
    required this.similarity,
    required this.sharedTagIds,
  });

  final Comic comic;
  final double similarity;
  final List<int> sharedTagIds;
}

class OnlineSimilarResult {
  const OnlineSimilarResult({
    required this.comics,
    required this.searchedTag,
    required this.failed,
  });

  const OnlineSimilarResult.unavailable()
    : comics = const <OnlineSimilarComic>[],
      searchedTag = null,
      failed = true;

  final List<OnlineSimilarComic> comics;

  /// The tag the site was asked about, so the page can say where this came
  /// from rather than presenting an unexplained list.
  final LocalTagCatalogEntry? searchedTag;

  final bool failed;
}

/// Asks the site for more comics like the one just read (P93).
///
/// One request per call. The query is deliberately broad — a single tag —
/// because the site sorts by date or popularity, not by similarity: the
/// search only has to produce a plausible pool, and the ordering that
/// matters is done here with the same similarity used for the library.
class FindSimilarComicsOnlineUseCase {
  const FindSimilarComicsOnlineUseCase({
    required this.searchComicsUseCase,
    required this.comicTagRepository,
    required this.localTagCatalogService,
    required this.blockedTagsRepository,
    this.limit = similarComicsLimit,
    this.minimumSimilarity = minimumComicSimilarity,
  });

  final SearchComicsUseCase searchComicsUseCase;
  final ComicTagRepository comicTagRepository;
  final LocalTagCatalogService localTagCatalogService;
  final BlockedTagsRepository blockedTagsRepository;

  final int limit;
  final double minimumSimilarity;

  Future<OnlineSimilarResult> execute(
    String comicId, {
    TagPreferenceVector? preferences,
  }) async {
    final sourceTags = await comicTagRepository.loadTagIds(comicId);
    final searchTag = _mostDistinctiveTag(sourceTags);
    if (searchTag == null) {
      return const OnlineSimilarResult.unavailable();
    }

    final blocked = await blockedTagsRepository.loadBlockedTags();
    final result = await searchComicsUseCase.execute(
      query: searchTag.query,
      page: 1,
      blockedTagQueries: blocked,
    );
    if (result.hasFailed) {
      return const OnlineSimilarResult.unavailable();
    }

    final owned = await comicTagRepository.loadOwnedComicIds();
    final similarity = buildComicSimilarity(
      catalog: localTagCatalogService,
      tagGroups: <Iterable<int>>[
        sourceTags,
        for (final comic in result.comics) comic.effectiveTagIds,
      ],
    );

    final scored = <ScoredComic<Comic>>[];
    for (final comic in result.comics) {
      // Already in the library, or the comic that was just read.
      if (comic.id == comicId || owned.contains(comic.id)) continue;
      final tagIds = comic.effectiveTagIds;
      final score = similarity.between(sourceTags, tagIds);
      if (score < minimumSimilarity) continue;
      scored.add(
        ScoredComic<Comic>(
          subject: comic,
          id: comic.id,
          similarity: score,
          sharedTagIds: similarity.strongestSharedTags(sourceTags, tagIds),
          tagIds: tagIds,
        ),
      );
    }

    return OnlineSimilarResult(
      comics: <OnlineSimilarComic>[
        for (final entry in rankSimilar(
          scored,
          preferences: preferences,
          limit: limit,
        ))
          OnlineSimilarComic(
            comic: entry.subject,
            similarity: entry.similarity,
            sharedTagIds: entry.sharedTagIds,
          ),
      ],
      searchedTag: searchTag,
      failed: false,
    );
  }

  /// The rarest tag this comic carries — usually its artist, which is what
  /// "more like this" most often means.
  ///
  /// Two or three tags combined would narrow the search so far that it often
  /// returns nothing; one rare tag returns a pool worth ranking.
  LocalTagCatalogEntry? _mostDistinctiveTag(Set<int> tagIds) {
    LocalTagCatalogEntry? best;
    for (final tagId in tagIds) {
      final entry = localTagCatalogService.entryById(tagId);
      if (entry == null || entry.count <= 0) continue;
      if (best == null || entry.count < best.count) best = entry;
    }
    return best;
  }
}
