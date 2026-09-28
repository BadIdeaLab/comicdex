import 'package:concept_nhv/models/comic.dart';
import 'package:concept_nhv/models/download_page_snapshot.dart';
import 'package:concept_nhv/services/download_asset_store.dart';
import 'package:concept_nhv/services/image_compression_service.dart';
import 'package:concept_nhv/services/nhentai_cdn_config_service.dart';
import 'package:concept_nhv/services/remote_asset_fetcher.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Extensions Flutter's built-in Skia codec can reliably decode via
/// `Image.file`/`Image.memory`. Anything outside this set (heif/avif/tiff/
/// unknown) is still transcoded to WebP so the reader never gets stuck on
/// an undecodable local file.
const Set<String> skiaSafeExtensions = <String>{
  'jpg',
  'jpeg',
  'png',
  'gif',
  'webp',
  'bmp',
};

/// One page saved to disk, and where it came from.
class PersistedAsset {
  const PersistedAsset({
    required this.sourceServer,
    required this.localPath,
    required this.storedFormat,
    required this.byteSize,
  });

  final String sourceServer;
  final String localPath;
  final String storedFormat;
  final int byteSize;
}

/// Bytes ready to be written, with the extension they should be written as.
class CompressedAsset {
  const CompressedAsset({required this.bytes, required this.extension});

  final Uint8List bytes;
  final String extension;
}

/// Fetches one page or cover from the CDN and puts it on disk.
///
/// Knows nothing about the download queue: given a page, it tries each host
/// in turn, transcodes what Flutter cannot decode, and saves the result.
/// That is the whole of its job, and separating it is what keeps CDN host
/// pools and image formats out of `DownloadManagerModel`.
class DownloadAssetFetcher {
  const DownloadAssetFetcher({
    required this.cdnConfigService,
    required this.downloadAssetStore,
    required this.imageCompressionService,
    required this.remoteAssetFetcher,
  });

  final NhentaiCdnConfigService cdnConfigService;
  final DownloadAssetStore downloadAssetStore;
  final ImageCompressionService imageCompressionService;
  final RemoteAssetFetcher remoteAssetFetcher;

  Future<List<String>> loadImageHosts() async {
    try {
      await cdnConfigService.load();
    } catch (_) {}
    return cdnConfigService.imageHosts;
  }

  /// Covers (and thumbnails) are served from a different CDN host pool than
  /// full-resolution page images — using [loadImageHosts] for covers
  /// consistently fails (e.g. connection reset) since that path doesn't
  /// exist on the page-image hosts.
  Future<List<String>> loadThumbnailHosts() async {
    try {
      await cdnConfigService.load();
    } catch (_) {}
    return cdnConfigService.thumbnailHosts;
  }

  /// Tries each host in [imageHosts] in order, and rethrows the last failure
  /// only once every one of them has been tried.
  Future<PersistedAsset> downloadAndPersistPage({
    required String comicId,
    required DownloadPageSnapshot page,
    required List<String> imageHosts,
  }) async {
    Object? lastError;
    for (final host in imageHosts) {
      final url = Uri.https(host, page.remotePath).toString();
      try {
        final originalBytes = await remoteAssetFetcher.fetchBytes(url);
        final compressed = await compressWithFallback(
          originalBytes,
          fallbackExtension: extensionFromPath(page.remotePath),
        );
        final localPath = await downloadAssetStore.savePage(
          comicId: comicId,
          pageNumber: page.pageNumber,
          bytes: compressed.bytes,
          extension: compressed.extension,
        );
        return PersistedAsset(
          sourceServer: host,
          localPath: localPath,
          storedFormat: compressed.extension,
          byteSize: compressed.bytes.length,
        );
      } catch (error) {
        lastError = error;
      }
    }

    throw lastError ?? StateError('Failed to download page ${page.pageNumber}');
  }

  /// Returns the saved cover's path, or null when every host failed or the
  /// comic carries no cover at all. A missing cover is not fatal to a
  /// download, so this reports rather than throws.
  Future<String?> downloadCover({
    required String comicId,
    required Comic comic,
    required List<String> thumbnailHosts,
  }) async {
    final coverPath = comic.images.cover?.path;
    if (coverPath == null || coverPath.isEmpty) {
      debugPrint(
        '[downloadCover] $comicId: comic.images.cover.path is null/empty.',
      );
      return null;
    }

    for (final host in thumbnailHosts) {
      final url = Uri.https(host, coverPath).toString();
      try {
        final originalBytes = await remoteAssetFetcher.fetchBytes(url);
        final compressed = await compressWithFallback(
          originalBytes,
          fallbackExtension: extensionFromPath(coverPath),
        );
        return downloadAssetStore.saveCover(
          comicId: comicId,
          bytes: compressed.bytes,
          extension: compressed.extension,
        );
      } catch (error) {
        debugPrint('[downloadCover] $comicId: $url failed: $error');
      }
    }

    return null;
  }

  /// Leaves a decodable format alone, transcodes anything else to WebP, and
  /// keeps the original when even that fails — an unconverted page still
  /// beats no page.
  Future<CompressedAsset> compressWithFallback(
    Uint8List originalBytes, {
    required String fallbackExtension,
  }) async {
    final normalizedExtension = fallbackExtension.toLowerCase();
    if (skiaSafeExtensions.contains(normalizedExtension)) {
      return CompressedAsset(
        bytes: originalBytes,
        extension: normalizedExtension,
      );
    }

    try {
      final compressed = await imageCompressionService.compressToWebp(
        originalBytes,
        quality: 80,
      );
      if (compressed.isNotEmpty) {
        return CompressedAsset(bytes: compressed, extension: 'webp');
      }
    } on UnsupportedError {
      // Keep original format below.
    } catch (_) {
      // Keep original format below.
    }

    return CompressedAsset(
      bytes: originalBytes,
      extension: normalizedExtension,
    );
  }

  /// The extension to store a file under, or `bin` for a name that carries
  /// none — something has to be written, and a bare name gives nothing to go
  /// on.
  static String extensionFromPath(String path) {
    final filename = p.basename(path);
    if (!filename.contains('.')) {
      return 'bin';
    }
    return filename.split('.').last.toLowerCase();
  }
}
