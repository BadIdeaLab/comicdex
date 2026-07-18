import 'package:concept_nhv/models/comic.dart';
import 'package:concept_nhv/models/comic_images.dart';
import 'package:concept_nhv/models/comic_page_image.dart';
import 'package:concept_nhv/models/comic_title.dart';
import 'package:concept_nhv/models/download_page_status.dart';
import 'package:concept_nhv/services/download_asset_store.dart';
import 'package:concept_nhv/storage/download_queue_repository.dart';
import 'package:concept_nhv/storage/downloaded_library_repository.dart';

class LoadOfflineComicUseCase {
  const LoadOfflineComicUseCase({
    required this.downloadQueueRepository,
    required this.downloadedLibraryRepository,
    required this.downloadAssetStore,
  });

  final DownloadQueueRepository downloadQueueRepository;
  final DownloadedLibraryRepository downloadedLibraryRepository;
  final DownloadAssetStore downloadAssetStore;

  /// Reconstructs a [Comic] from locally stored download data.
  ///
  /// Page paths are resolved from [DownloadJobPage.localPath] (stored
  /// relative to the downloads root — see
  /// .codex/phases/P51-relative-download-paths.md — and resolved to an
  /// absolute path here since [ComicPageSourceResolver] distinguishes local
  /// files from remote URLs by an absolute `/`-prefixed path). Pages that
  /// were not fully downloaded fall back to [DownloadJobPage.remotePath] so
  /// the reader degrades gracefully to a network fetch for those pages.
  ///
  /// Returns null if no completed download record exists for [comicId].
  Future<Comic?> execute(String comicId) async {
    final snapshots = await downloadedLibraryRepository.loadDownloadedComics();
    final snapshot = snapshots.where((s) => s.comicId == comicId).firstOrNull;
    if (snapshot == null) {
      return null;
    }

    final pages = await downloadQueueRepository.loadPages(comicId);

    final pageImages = await Future.wait(pages.map((page) async {
      final isCompleted = page.status == DownloadPageStatus.completed;
      final localPath = page.localPath;
      final effectivePath =
          (isCompleted && localPath != null && localPath.isNotEmpty)
              ? await downloadAssetStore.resolveAbsolutePath(localPath)
              : page.remotePath;

      return ComicPageImage(path: effectivePath);
    }));

    return Comic(
      id: snapshot.comicId,
      mediaId: snapshot.mediaId,
      title: ComicTitle(
        english: snapshot.title,
        japanese: null,
        pretty: snapshot.title,
      ),
      images: ComicImages(pages: pageImages),
      tags: snapshot.tags,
      numPages: snapshot.pageCount,
      numFavorites: snapshot.numFavorites,
    );
  }
}
