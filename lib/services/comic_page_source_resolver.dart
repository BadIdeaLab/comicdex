import 'package:concept_nhv/models/comic.dart';
import 'package:concept_nhv/models/image_format.dart';

class ComicPageSourceResolver {
  const ComicPageSourceResolver();

  /// Returns the page source for the given [pageNumber].
  ///
  /// If [Comic.images.pages[pageNumber-1].path] is an absolute filesystem
  /// path (starts with `/`), the comic was opened from a local download and
  /// the path is returned as-is for use with `Image.file`.
  ///
  /// Otherwise a remote nhentai CDN URL is returned.
  String resolvePageUrl({
    required Comic comic,
    required int pageNumber,
  }) {
    final pageImage = comic.images.pages[pageNumber - 1];
    final path = pageImage.path;

    if (path != null && path.startsWith('/')) {
      return path;
    }

    if (path != null && path.isNotEmpty) {
      return 'https://i1.nhentai.net/$path';
    }

    return 'https://i1.nhentai.net/galleries/${comic.mediaId}/$pageNumber.${imageTypeCodeToExtension(pageImage.t)}';
  }

  /// Returns true when [url] refers to a local file rather than a remote URL.
  static bool isLocalPath(String url) => url.startsWith('/');
}
