import 'package:concept_nhv/models/comic.dart';
import 'package:concept_nhv/models/comic_images.dart';
import 'package:concept_nhv/models/comic_page_image.dart';
import 'package:concept_nhv/models/comic_search_response.dart';
import 'package:concept_nhv/models/comic_tag.dart';
import 'package:concept_nhv/models/comic_title.dart';
import 'package:concept_nhv/services/nhentai_cdn_config_service.dart';
import 'package:concept_nhv/storage/nhentai_api_key_store.dart';
import 'package:dio/dio.dart';

abstract class NhentaiGateway {
  Future<void> pingHomepage();

  Future<ComicSearchResponse> searchComics(Uri uri);

  Future<({Comic comic, Map<String, String>? headers})> loadComicDetail(
    String comicId,
  );

  Future<({List<ComicTag> tags, int? numFavorites, int? uploadDate})> loadComicMeta(
    String comicId,
  );
}

class NhentaiApiClient implements NhentaiGateway {
  NhentaiApiClient({
    required this.apiKeyStore,
    required this.cdnConfigService,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  final NhentaiApiKeyStore apiKeyStore;
  final NhentaiCdnConfigService cdnConfigService;
  final Dio _dio;
  final Map<String, List<ComicTag>> _comicTagCache = <String, List<ComicTag>>{};
  final Map<String, int?> _comicFavoritesCache = <String, int?>{};
  final Map<String, int?> _comicUploadDateCache = <String, int?>{};

  @override
  Future<void> pingHomepage() async {
    await _get(Uri.https('nhentai.net', '/api/v2'));
  }

  @override
  Future<ComicSearchResponse> searchComics(Uri uri) async {
    try {
      await cdnConfigService.load();
    } catch (_) {}
    final response = await _get(uri);
    return _mapSearchResponse(response.data as Map<String, dynamic>);
  }

  @override
  Future<({Comic comic, Map<String, String>? headers})> loadComicDetail(
    String comicId,
  ) async {
    try {
      await cdnConfigService.load();
    } catch (_) {}
    final result = await _get(
      Uri.https('nhentai.net', '/api/v2/galleries/$comicId'),
    );
    return (
      comic: _mapComicDetail(result.data as Map<String, dynamic>),
      headers: null,
    );
  }

  @override
  Future<({List<ComicTag> tags, int? numFavorites, int? uploadDate})> loadComicMeta(
    String comicId,
  ) async {
    final cached = _comicTagCache[comicId];
    if (cached != null) {
      return (tags: cached, numFavorites: _comicFavoritesCache[comicId], uploadDate: _comicUploadDateCache[comicId]);
    }

    final result = await _get(
      Uri.https('nhentai.net', '/api/v2/galleries/$comicId'),
    );
    final comic = _mapComicDetail(result.data as Map<String, dynamic>);
    _comicTagCache[comic.id] = comic.tags;
    _comicFavoritesCache[comic.id] = comic.numFavorites;
    _comicUploadDateCache[comic.id] = comic.uploadDate;
    return (tags: comic.tags, numFavorites: comic.numFavorites, uploadDate: comic.uploadDate);
  }

  Future<Response<dynamic>> _get(Uri uri) async {
    return _dio.getUri(
      uri,
      options: Options(headers: await _buildHeaders()),
    );
  }

  Future<Map<String, String>> _buildHeaders() async {
    final credential = await apiKeyStore.load();
    if (credential.isEmpty) {
      return const <String, String>{};
    }
    return <String, String>{'Authorization': 'Key ${credential.apiKey}'};
  }

  ComicSearchResponse _mapSearchResponse(Map<String, dynamic> json) {
    final result = List<Map<String, dynamic>>.from(
      json['result'] as List<dynamic>? ?? const <dynamic>[],
    );

    return ComicSearchResponse(
      result: result.map(_mapListComic).toList(growable: false),
      numPages: (json['num_pages'] as num?)?.toInt(),
      perPage: (json['per_page'] as num?)?.toInt(),
    );
  }

  Comic _mapListComic(Map<String, dynamic> json) {
    return Comic(
      id: '${json['id']}',
      mediaId: '${json['media_id']}',
      title: ComicTitle(
        english: json['english_title'] as String?,
        japanese: json['japanese_title'] as String?,
        pretty: json['english_title'] as String?,
      ),
      images: ComicImages(
        thumbnail: ComicPageImage(
          path: json['thumbnail'] as String?,
          w: (json['thumbnail_width'] as num?)?.toInt(),
          h: (json['thumbnail_height'] as num?)?.toInt(),
          t: _extensionToTypeCode(json['thumbnail'] as String?),
        ),
      ),
      numPages: (json['num_pages'] as num?)?.toInt() ?? 0,
      uploadDate: (json['upload_date'] as num?)?.toInt(),
      tags: (json['tags'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(ComicTag.fromJson)
          .toList(growable: false),
    );
  }

  Comic _mapComicDetail(Map<String, dynamic> json) {
    final tags = List<Map<String, dynamic>>.from(
      json['tags'] as List<dynamic>? ?? const <dynamic>[],
    );
    final pages = List<Map<String, dynamic>>.from(
      json['pages'] as List<dynamic>? ?? const <dynamic>[],
    );
    final cover = json['cover'] as Map<String, dynamic>?;
    final thumbnail = json['thumbnail'] as Map<String, dynamic>?;

    final comic = Comic(
      id: '${json['id']}',
      mediaId: '${json['media_id']}',
      title: ComicTitle.fromJson(json['title'] as Map<String, dynamic>),
      images: ComicImages(
        cover: _mapCoverInfo(cover),
        thumbnail: _mapCoverInfo(thumbnail),
        pages: pages.map(_mapPageInfo).toList(growable: false),
      ),
      scanlator: json['scanlator'] as String?,
      uploadDate: (json['upload_date'] as num?)?.toInt(),
      tags: tags.map(ComicTag.fromJson).toList(growable: false),
      numPages: (json['num_pages'] as num?)?.toInt() ?? pages.length,
      numFavorites: (json['num_favorites'] as num?)?.toInt(),
    );
    _comicTagCache[comic.id] = comic.tags;
    return comic;
  }

  ComicPageImage _mapPageInfo(Map<String, dynamic> json) {
    final path = json['path'] as String?;
    return ComicPageImage(
      path: path,
      thumbnailPath: json['thumbnail'] as String?,
      w: (json['width'] as num?)?.toInt(),
      h: (json['height'] as num?)?.toInt(),
      t: _extensionToTypeCode(path),
    );
  }

  ComicPageImage? _mapCoverInfo(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    final path = json['path'] as String?;
    return ComicPageImage(
      path: path,
      w: (json['width'] as num?)?.toInt(),
      h: (json['height'] as num?)?.toInt(),
      t: _extensionToTypeCode(path),
    );
  }

  String _extensionToTypeCode(String? path) {
    final segment = path?.split('/').last ?? '';
    final sanitized = segment.endsWith('.webp.webp')
        ? segment.substring(0, segment.length - 5)
        : segment;
    final extension = sanitized.contains('.')
        ? sanitized.split('.').last.toLowerCase()
        : '';

    return switch (extension) {
      'jpg' || 'jpeg' => 'j',
      'png' => 'p',
      'gif' => 'g',
      'webp' => 'w',
      'tiff' || 'tif' => 't',
      'bmp' => 'b',
      'heif' || 'heic' => 'h',
      'avif' => 'a',
      _ => 'j',
    };
  }
}
