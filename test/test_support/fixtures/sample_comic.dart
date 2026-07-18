import 'package:concept_nhv/models/comic.dart';
import 'package:concept_nhv/models/comic_images.dart';
import 'package:concept_nhv/models/comic_page_image.dart';
import 'package:concept_nhv/models/comic_tag.dart';
import 'package:concept_nhv/models/comic_title.dart';

Comic sampleComic({String id = '1001', String mediaId = '9'}) {
  return Comic(
    id: id,
    mediaId: mediaId,
    title: ComicTitle(
      english: 'Sample Comic',
      japanese: 'Sample Comic JP',
      pretty: 'Sample Comic',
    ),
    images: ComicImages(
      pages: <ComicPageImage>[
        ComicPageImage(
          t: 'j',
          w: 1200,
          h: 1800,
          path: 'galleries/$mediaId/1.jpg',
        ),
        ComicPageImage(
          t: 'j',
          w: 1200,
          h: 1800,
          path: 'galleries/$mediaId/2.jpg',
        ),
      ],
      cover: ComicPageImage(
        t: 'j',
        w: 350,
        h: 500,
        path: 'galleries/$mediaId/cover.jpg',
      ),
      thumbnail: ComicPageImage(
        t: 'w',
        w: 350,
        h: 500,
        path: 'galleries/$mediaId/thumb.webp',
      ),
    ),
    scanlator: null,
    uploadDate: 0,
    tags: <ComicTag>[
      ComicTag(
        id: 1,
        type: 'tag',
        name: 'sample',
        url: '/tag/sample',
        count: 1,
      ),
    ],
    numPages: 2,
    numFavorites: 1,
  );
}
