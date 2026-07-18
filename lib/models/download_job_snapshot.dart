import 'package:concept_nhv/models/download_job_status.dart';

class DownloadJobSnapshot {
  const DownloadJobSnapshot({
    required this.comicId,
    required this.mediaId,
    required this.title,
    this.thumbnailPath,
    required this.status,
    required this.totalPages,
    required this.completedPages,
    required this.nextPageNumber,
    required this.requestedAt,
    required this.updatedAt,
    this.startedAt,
    this.completedAt,
    this.lastError,
    this.retryCount = 0,
  });

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
}
