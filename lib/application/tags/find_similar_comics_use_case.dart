import 'package:concept_nhv/application/tags/comic_similarity.dart';
import 'package:concept_nhv/application/tags/tag_preference_vector.dart';
import 'package:concept_nhv/models/stored_comic.dart';
import 'package:concept_nhv/services/local_tag_catalog_service.dart';
import 'package:concept_nhv/storage/comic_repository.dart';
import 'package:concept_nhv/storage/comic_tag_repository.dart';

/// One comic in the reader's end-of-comic list.
class SimilarComic {
  const SimilarComic({
    required this.comic,
    required this.similarity,
    required this.sharedTagIds,
  });

  final StoredComic comic;
  final double similarity;

  /// The strongest shared tags, for the line explaining why this is here.
  final List<int> sharedTagIds;
}

/// Finds comics in the user's own library that resemble the one just read.
///
/// See .codex/phases/P92-similar-comics-end-page.md.
class FindSimilarComicsUseCase {
  const FindSimilarComicsUseCase({
    required this.comicTagRepository,
    required this.comicRepository,
    required this.localTagCatalogService,
    this.limit = 6,
    this.minimumSimilarity = 0.15,
  });

  final ComicTagRepository comicTagRepository;
  final ComicRepository comicRepository;
  final LocalTagCatalogService localTagCatalogService;

  /// At most this many, and fewer whenever fewer clear [minimumSimilarity].
  ///
  /// Never padded up to this number: recommendation quality falls away fast,
  /// so filling a tablet's wider row with the twelfth-best match makes the
  /// list worse, not longer.
  final int limit;

  /// Below this, the pair share little beyond coincidence. A guess until
  /// measured against a real library.
  final double minimumSimilarity;

  Future<List<SimilarComic>> execute(
    String comicId, {
    TagPreferenceVector? preferences,
  }) async {
    final sourceTags = await comicTagRepository.loadTagIds(comicId);
    if (sourceTags.isEmpty) return const <SimilarComic>[];

    // minimumTagComics: 1 — unlike the ranking, a tag on two comics is not
    // noise here. An artist the user kept twice is among the strongest
    // signals that two comics belong together.
    final assignments = await comicTagRepository.loadKeptTagAssignments(
      minimumTagComics: 1,
    );

    final tagsByComic = <String, List<int>>{};
    for (final assignment in assignments) {
      if (assignment.comicId == comicId) continue;
      (tagsByComic[assignment.comicId] ??= <int>[]).add(assignment.tagId);
    }
    if (tagsByComic.isEmpty) return const <SimilarComic>[];

    final similarity = _buildSimilarity(sourceTags, tagsByComic);

    final scored = <({String id, double score, List<int> shared})>[];
    for (final entry in tagsByComic.entries) {
      final score = similarity.between(sourceTags, entry.value);
      if (score < minimumSimilarity) continue;
      scored.add((
        id: entry.key,
        score: score,
        shared: similarity.strongestSharedTags(sourceTags, entry.value),
      ));
    }
    if (scored.isEmpty) return const <SimilarComic>[];

    scored.sort((a, b) {
      final bySimilarity = b.score.compareTo(a.score);
      if (bySimilarity != 0) return bySimilarity;
      // Only a tie-break. Multiplying preference in would let a comic the
      // user merely likes displace one that actually resembles this one.
      final preferred = _preferenceOf(b.id, tagsByComic, preferences)
          .compareTo(_preferenceOf(a.id, tagsByComic, preferences));
      return preferred != 0 ? preferred : a.id.compareTo(b.id);
    });

    final top = scored.take(limit).toList(growable: false);
    final comics = await comicRepository.loadComicsByIds(
      <String>{for (final entry in top) entry.id},
    );

    return <SimilarComic>[
      for (final entry in top)
        if (comics[entry.id] != null)
          SimilarComic(
            comic: comics[entry.id]!,
            similarity: entry.score,
            sharedTagIds: entry.shared,
          ),
    ];
  }

  ComicSimilarity _buildSimilarity(
    Set<int> sourceTags,
    Map<String, List<int>> tagsByComic,
  ) {
    final involved = <int>{
      ...sourceTags,
      for (final tags in tagsByComic.values) ...tags,
    };
    final siteCounts = <int, int>{};
    for (final tagId in involved) {
      final entry = localTagCatalogService.entryById(tagId);
      // Left out rather than defaulted: an id the catalog cannot resolve must
      // not become a tag that two comics "share".
      if (entry == null) continue;
      siteCounts[tagId] = entry.count;
    }
    return ComicSimilarity.fromSiteCounts(
      siteCounts,
      referenceCount: localTagCatalogService.maxCount,
    );
  }

  double _preferenceOf(
    String comicId,
    Map<String, List<int>> tagsByComic,
    TagPreferenceVector? preferences,
  ) {
    if (preferences == null) return 0;
    return preferences.scoreComic(tagsByComic[comicId] ?? const <int>[]);
  }
}
