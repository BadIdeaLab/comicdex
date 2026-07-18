import 'package:concept_nhv/models/download_page_status.dart';

class DownloadPageSnapshot {
  const DownloadPageSnapshot({
    required this.comicId,
    required this.mediaId,
    required this.pageNumber,
    required this.remotePath,
    required this.status,
    this.sourceServer,
    this.localPath,
    this.storedFormat,
    this.byteSize,
    this.downloadedAt,
    this.lastError,
  });

  final String comicId;
  final String mediaId;
  final int pageNumber;
  final String remotePath;
  final String? sourceServer;
  final String? localPath;
  final String? storedFormat;
  final int? byteSize;
  final DownloadPageStatus status;
  final DateTime? downloadedAt;
  final String? lastError;
}
