import 'package:concept_nhv/models/comic.dart';
import 'package:concept_nhv/models/comic_images.dart';
import 'package:concept_nhv/models/comic_page_image.dart';
import 'package:concept_nhv/models/comic_search_response.dart';
import 'package:concept_nhv/models/comic_tag.dart';
import 'package:concept_nhv/models/comic_title.dart';
import 'package:concept_nhv/services/nhentai_auth_service.dart';
import 'package:concept_nhv/services/rate_limit_retry.dart';
import 'package:concept_nhv/storage/nhentai_api_key_store.dart';
import 'package:dio/dio.dart';

class RemoteFavoriteAuthException implements Exception {
  const RemoteFavoriteAuthException(this.message);

  final String message;

  @override
  String toString() => 'RemoteFavoriteAuthException($message)';
}

abstract class RemoteFavoriteGateway {
  Future<List<Comic>> loadRemoteFavorites({
    void Function(int page, int totalPages)? onProgress,
    void Function(Duration retryIn)? onRateLimit,
  });

  Future<void> addRemoteFavorite(String comicId);

  Future<void> removeRemoteFavorite(String comicId);
}

class NhentaiApiRemoteFavoriteGateway implements RemoteFavoriteGateway {
  NhentaiApiRemoteFavoriteGateway({
    required this.apiKeyStore,
    required this.authService,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  final NhentaiApiKeyStore apiKeyStore;
  final NhentaiAuthService authService;
  final Dio _dio;

  static const Duration _favoritePageDelay = Duration(milliseconds: 2000);

  @override
  Future<List<Comic>> loadRemoteFavorites({
    void Function(int page, int totalPages)? onProgress,
    void Function(Duration retryIn)? onRateLimit,
  }) async {
    final comics = <Comic>[];
    var page = 1;

    while (true) {
      await Future<void>.delayed(_favoritePageDelay);
      final response = await _fetchFavoritesPage(page, onRateLimit: onRateLimit);
      final searchResponse = _mapFavoritesResponse(response.data ?? const {});
      comics.addAll(searchResponse.result);

      final numPages = searchResponse.numPages ?? 1;
      onProgress?.call(page, numPages);
      if (page >= numPages || searchResponse.result.isEmpty) {
        break;
      }
      page += 1;
    }

    return comics;
  }

  Future<Response<Map<String, dynamic>>> _fetchFavoritesPage(
    int page, {
    void Function(Duration retryIn)? onRateLimit,
  }) {
    final uri = Uri.https('nhentai.net', '/api/v2/favorites', <String, String>{
      'page': '$page',
    });
    return withRateLimitRetry(
      () => _withAuthRequest<Map<String, dynamic>>(uri),
      onRateLimit: onRateLimit,
    );
  }

  @override
  Future<void> addRemoteFavorite(String comicId) {
    return _withAuthRequest<void>(
      Uri.https('nhentai.net', '/api/v2/galleries/$comicId/favorite'),
      method: 'POST',
    );
  }

  @override
  Future<void> removeRemoteFavorite(String comicId) {
    return _withAuthRequest<void>(
      Uri.https('nhentai.net', '/api/v2/galleries/$comicId/favorite'),
      method: 'DELETE',
    );
  }

  Future<Response<T>> _withAuthRequest<T>(
    Uri uri, {
    String method = 'GET',
  }) async {
    final credential = await apiKeyStore.load();
    if (credential.isEmpty) {
      throw const RemoteFavoriteAuthException('No stored API key.');
    }

    try {
      return await _dio.requestUri<T>(
        uri,
        options: Options(
          method: method,
          headers: <String, String>{
            'Authorization': 'Key ${credential.apiKey}',
          },
        ),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await authService.clearApiKey();
        throw const RemoteFavoriteAuthException(
          'Saved API key is no longer valid.',
        );
      }
      rethrow;
    }
  }

  ComicSearchResponse _mapFavoritesResponse(Map<String, dynamic> json) {
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
        ),
      ),
      numPages: (json['num_pages'] as num?)?.toInt() ?? 0,
      tags: const <ComicTag>[],
    );
  }
}
