import 'dart:convert';

import 'package:concept_nhv/models/comic.dart';
import 'package:concept_nhv/models/comic_images.dart';
import 'package:concept_nhv/models/comic_page_image.dart';
import 'package:concept_nhv/models/comic_tag.dart';
import 'package:concept_nhv/models/collection_summary.dart';
import 'package:concept_nhv/models/image_format.dart';
import 'package:concept_nhv/models/stored_comic.dart';

class ComicCardData {
  ComicCardData({
    required this.id,
    required this.mediaId,
    required this.title,
    required this.pages,
    required this.serializedImages,
    required this.thumbnailUrl,
    required this.thumbnailWidth,
    required this.thumbnailHeight,
    this.tags = const <ComicTag>[],
    this.uploadDate,
  });

  final String id;
  final String mediaId;
  final String title;
  final int pages;
  final String serializedImages;
  final String thumbnailUrl;
  final int thumbnailWidth;
  final int thumbnailHeight;
  final List<ComicTag> tags;
  final int? uploadDate;

  factory ComicCardData.fromComic(Comic comic) {
    final thumbnail = comic.images.thumbnail;
    return ComicCardData(
      id: comic.id,
      mediaId: comic.mediaId,
      title: comic.title.english ?? comic.title.pretty ?? comic.id,
      pages: comic.numPages,
      serializedImages: jsonEncode(comic.images.toJson()),
      thumbnailUrl: _buildThumbnailUrl(comic.mediaId, thumbnail),
      thumbnailWidth: thumbnail?.w ?? 9,
      thumbnailHeight: thumbnail?.h ?? 16,
      tags: comic.tags,
      uploadDate: comic.uploadDate,
    );
  }

  factory ComicCardData.fromStoredComic(StoredComic comic) {
    try {
      final images = ComicImages.fromJson(
        jsonDecode(comic.serializedImages) as Map<String, dynamic>,
      );
      final thumbnail = images.thumbnail;
      return ComicCardData(
        id: comic.id,
        mediaId: comic.mediaId,
        title: comic.title,
        pages: comic.pages,
        serializedImages: comic.serializedImages,
        thumbnailUrl: _buildThumbnailUrl(comic.mediaId, thumbnail),
        thumbnailWidth: thumbnail?.w ?? 9,
        thumbnailHeight: thumbnail?.h ?? 16,
      );
    } on FormatException {
      final legacyExt = comic.serializedImages.isEmpty
          ? 'jpg'
          : imageTypeCodeToExtension(comic.serializedImages[0]);
      return ComicCardData(
        id: comic.id,
        mediaId: comic.mediaId,
        title: comic.title,
        pages: comic.pages,
        serializedImages: comic.serializedImages,
        thumbnailUrl:
            'https://t.nhentai.net/galleries/${comic.mediaId}/thumb.$legacyExt',
        thumbnailWidth: 9,
        thumbnailHeight: 16,
      );
    }
  }

  StoredComic toStoredComic() {
    return StoredComic(
      id: id,
      mediaId: mediaId,
      title: title,
      serializedImages: serializedImages,
      pages: pages,
    );
  }

  static CollectionSummary placeholderSummary({
    required String collectionName,
  }) {
    return CollectionSummary(
      collectionName: collectionName,
      collectedCount: 0,
      thumbnailUrl:
          'https://placehold.co/720x720/png?text=${Uri.encodeComponent(collectionName)}',
      thumbnailWidth: 720,
      thumbnailHeight: 720,
    );
  }

  static String _buildThumbnailUrl(String mediaId, ComicPageImage? thumbnail) {
    final path = thumbnail?.path;
    if (path != null && path.isNotEmpty) {
      return 'https://t1.nhentai.net/$path';
    }

    final thumbnailExt = imageTypeCodeToExtension(thumbnail?.t);
    return 'https://t1.nhentai.net/galleries/$mediaId/thumb.$thumbnailExt';
  }
}
