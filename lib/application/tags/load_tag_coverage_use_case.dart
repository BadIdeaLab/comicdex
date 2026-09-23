import 'package:concept_nhv/storage/comic_tag_repository.dart';

/// How much of the kept library the tag analysis actually sees (P81).
class TagCoverage {
  const TagCoverage({required this.keptComics, required this.taggedComics});

  final int keptComics;
  final int taggedComics;

  /// 0..1; zero when nothing is kept yet.
  double get ratio => keptComics <= 0 ? 0 : taggedComics / keptComics;
}

class LoadTagCoverageUseCase {
  const LoadTagCoverageUseCase({required this.comicTagRepository});

  final ComicTagRepository comicTagRepository;

  Future<TagCoverage> execute() async {
    return TagCoverage(
      keptComics: await comicTagRepository.loadKeptComicCount(),
      taggedComics: await comicTagRepository.loadTaggedKeptComicCount(),
    );
  }
}
