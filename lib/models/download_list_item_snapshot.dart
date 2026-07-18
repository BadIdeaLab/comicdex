import 'package:concept_nhv/models/comic_tag.dart';
import 'package:concept_nhv/models/download_job_snapshot.dart';
import 'package:concept_nhv/models/download_job_status.dart';
import 'package:concept_nhv/models/downloaded_comic_snapshot.dart';

class DownloadListItemSnapshot {
  const DownloadListItemSnapshot({
    required this.comicId,
    required this.mediaId,
    required this.title,
    required this.status,
    required this.totalPages,
    required this.completedPages,
    required this.nextPageNumber,
    required this.requestedAt,
    required this.updatedAt,
    required this.retryCount,
    this.thumbnailPath,
    this.startedAt,
    this.completedAt,
    this.lastError,
    this.coverLocalPath,
    this.pageCount,
    this.downloadedAt,
    this.lastReadAt,
    this.numFavorites,
    this.tags = const <ComicTag>[],
  });

  factory DownloadListItemSnapshot.fromJob(
    DownloadJobSnapshot job, {
    DownloadedComicSnapshot? downloadedComic,
  }) {
    return DownloadListItemSnapshot(
      comicId: job.comicId,
      mediaId: job.mediaId,
      title: downloadedComic?.title ?? job.title,
      thumbnailPath: job.thumbnailPath,
      status: job.status,
      totalPages: job.totalPages,
      completedPages: job.completedPages,
      nextPageNumber: job.nextPageNumber,
      requestedAt: job.requestedAt,
      updatedAt: job.updatedAt,
      startedAt: job.startedAt,
      completedAt: job.completedAt,
      lastError: job.lastError,
      retryCount: job.retryCount,
      coverLocalPath: downloadedComic?.coverLocalPath,
      pageCount: downloadedComic?.pageCount ?? job.totalPages,
      downloadedAt: downloadedComic?.downloadedAt,
      lastReadAt: downloadedComic?.lastReadAt,
      numFavorites: downloadedComic?.numFavorites,
      tags: downloadedComic?.tags ?? const <ComicTag>[],
    );
  }

  factory DownloadListItemSnapshot.fromDownloadedComic(
    DownloadedComicSnapshot downloadedComic,
  ) {
    return DownloadListItemSnapshot(
      comicId: downloadedComic.comicId,
      mediaId: downloadedComic.mediaId,
      title: downloadedComic.title,
      status: DownloadJobStatus.completed,
      totalPages: downloadedComic.pageCount,
      completedPages: downloadedComic.pageCount,
      nextPageNumber: downloadedComic.pageCount + 1,
      requestedAt: downloadedComic.downloadedAt,
      updatedAt: downloadedComic.lastReadAt ?? downloadedComic.downloadedAt,
      retryCount: 0,
      coverLocalPath: downloadedComic.coverLocalPath,
      pageCount: downloadedComic.pageCount,
      downloadedAt: downloadedComic.downloadedAt,
      lastReadAt: downloadedComic.lastReadAt,
      numFavorites: downloadedComic.numFavorites,
      tags: downloadedComic.tags,
    );
  }

  final String comicId;
  final String mediaId;
  final String title;
  final String? thumbnailPath;
  final DownloadJobStatus status;
  final int totalPages;
  final int completedPages;
  final int nextPageNumber;
  final DateTime requestedAt;
  final DateTime updatedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? lastError;
  final int retryCount;
  final String? coverLocalPath;
  final int? pageCount;
  final DateTime? downloadedAt;
  final DateTime? lastReadAt;
  final int? numFavorites;
  final List<ComicTag> tags;

  bool get isCompletedCard => status == DownloadJobStatus.completed;
}
