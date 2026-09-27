import 'package:concept_nhv/application/tags/similar_comic_ranking.dart';
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
    required this.tagIds,
  });

  final StoredComic comic;
  final double similarity;

  /// The strongest shared tags, for the line explaining why this is here.
  final List<int> sharedTagIds;

  /// Every tag id on this comic. A [StoredComic] carries none of its own, so
  /// without these the tile could not tell the reader what language it is in.
  final List<int> tagIds;
}

/// Finds comics in the user's own library that resemble the one just read.
///
/// See .codex/phases/P92-similar-comics-end-page.md.
class FindSimilarComicsUseCase {
  const FindSimilarComicsUseCase({
    required this.comicTagRepository,
    required this.comicRepository,
    required this.localTagCatalogService,
    this.limit = similarComicsLimit,
    this.minimumSimilarity = minimumComicSimilarity,
  });

  final ComicTagRepository comicTagRepository;
  final ComicRepository comicRepository;
  final LocalTagCatalogService localTagCatalogService;

  final int limit;
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

    final similarity = buildComicSimilarity(
      catalog: localTagCatalogService,
      tagGroups: <Iterable<int>>[sourceTags, ...tagsByComic.values],
    );

    final scored = <ScoredComic<String>>[];
    for (final entry in tagsByComic.entries) {
      final score = similarity.between(sourceTags, entry.value);
      if (score < minimumSimilarity) continue;
      scored.add(
        ScoredComic<String>(
          subject: entry.key,
          id: entry.key,
          similarity: score,
          sharedTagIds: similarity.strongestSharedTags(sourceTags, entry.value),
          tagIds: entry.value,
        ),
      );
    }
    if (scored.isEmpty) return const <SimilarComic>[];

    final top = rankSimilar(scored, preferences: preferences, limit: limit);
    final comics = await comicRepository.loadComicsByIds(<String>{
      for (final entry in top) entry.id,
    });

    return <SimilarComic>[
      for (final entry in top)
        if (comics[entry.id] case final comic?)
          SimilarComic(
            comic: comic,
            similarity: entry.similarity,
            sharedTagIds: entry.sharedTagIds,
            tagIds: entry.tagIds,
          ),
    ];
  }
}
