import 'package:concept_nhv/models/comic_tag.dart';

class DownloadedComicSnapshot {
  const DownloadedComicSnapshot({
    required this.comicId,
    required this.mediaId,
    required this.title,
    required this.rootDirectoryPath,
    required this.pageCount,
    required this.downloadedAt,
    required this.tags,
    this.coverLocalPath,
    this.lastReadAt,
    this.numFavorites,
  });

  final String comicId;
  final String mediaId;
  final String title;
  final String? coverLocalPath;
  final String rootDirectoryPath;
  final int pageCount;
  final DateTime downloadedAt;
  final DateTime? lastReadAt;
  final int? numFavorites;
  final List<ComicTag> tags;
}
