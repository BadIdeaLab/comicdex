import 'package:concept_nhv/services/comic_page_source_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_support/fixtures/sample_comic.dart';

void main() {
  test('uses explicit page path when provided', () {
    const resolver = ComicPageSourceResolver();
    final comic = sampleComic().copyWith(
      images: sampleComic().images.copyWith(
        pages: <dynamic>[
          sampleComic().images.pages.first.copyWith(
            path: 'galleries/9/1.webp',
            t: 'w',
          ),
          sampleComic().images.pages[1],
        ].cast(),
      ),
    );

    final url = resolver.resolvePageUrl(comic: comic, pageNumber: 1);

    expect(url, 'https://i1.nhentai.net/galleries/9/1.webp');
  });

  test('builds gallery url from media id and page number when path is absent', () {
    const resolver = ComicPageSourceResolver();

    final url = resolver.resolvePageUrl(comic: sampleComic(mediaId: '42'), pageNumber: 2);

    expect(url, 'https://i1.nhentai.net/galleries/42/2.jpg');
  });

  test('returns local path as-is when path starts with /', () {
    const resolver = ComicPageSourceResolver();
    const localPath =
        '/data/user/0/com.example/files/downloads/1001/pages/1.jpg';
    final comic = sampleComic().copyWith(
      images: sampleComic().images.copyWith(
        pages: <dynamic>[
          sampleComic().images.pages.first.copyWith(path: localPath),
          sampleComic().images.pages[1],
        ].cast(),
      ),
    );

    final url = resolver.resolvePageUrl(comic: comic, pageNumber: 1);

    expect(url, localPath);
    expect(ComicPageSourceResolver.isLocalPath(url), isTrue);
  });

  test('isLocalPath returns false for remote URLs', () {
    expect(
      ComicPageSourceResolver.isLocalPath(
        'https://i1.nhentai.net/galleries/9/1.jpg',
      ),
      isFalse,
    );
  });
}
