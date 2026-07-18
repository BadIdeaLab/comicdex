import 'package:concept_nhv/models/comic.dart';
import 'package:concept_nhv/models/comic_search_response.dart';
import 'package:concept_nhv/models/comic_tag.dart';
import 'package:concept_nhv/models/tag_catalog_item.dart';
import 'package:concept_nhv/models/tag_catalog_page.dart';
import 'package:concept_nhv/models/tag_catalog_type.dart';
import 'package:concept_nhv/services/nhentai_api_client.dart';
import 'package:dio/dio.dart';

import '../fixtures/sample_comic.dart';

class FakeNhentaiGateway implements NhentaiGateway {
  FakeNhentaiGateway({
    this.pingError,
    this.searchResponse,
    this.detailComic,
    this.detailHeaders,
    this.comicTags,
    this.tagCatalogPage,
  });

  final DioException? pingError;
  final ComicSearchResponse? searchResponse;
  final Comic? detailComic;
  final Map<String, String>? detailHeaders;
  final List<ComicTag>? comicTags;
  final TagCatalogPage? tagCatalogPage;
  final List<Uri> searchedUris = <Uri>[];
  final List<String> loadedComicDetailIds = <String>[];
  final List<String> loadedComicMetaIds = <String>[];

  @override
  Future<void> pingHomepage() async {
    if (pingError != null) {
      throw pingError!;
    }
  }

  @override
  Future<ComicSearchResponse> searchComics(Uri uri) async {
    searchedUris.add(uri);
    if (searchResponse != null) {
      return searchResponse!;
    }

    return ComicSearchResponse(
      result: <Comic>[sampleComic()],
      numPages: 1,
      perPage: 25,
    );
  }

  @override
  Future<({Comic comic, Map<String, String>? headers})> loadComicDetail(
    String comicId,
  ) async {
    loadedComicDetailIds.add(comicId);
    return (
      comic: detailComic ?? sampleComic(id: comicId),
      headers: detailHeaders,
    );
  }

  @override
  Future<({List<ComicTag> tags, int? numFavorites, int? uploadDate})> loadComicMeta(
    String comicId,
  ) async {
    loadedComicMetaIds.add(comicId);
    final comic = detailComic ?? sampleComic(id: comicId);
    return (
      tags: comicTags ?? comic.tags,
      numFavorites: comic.numFavorites,
      uploadDate: comic.uploadDate,
    );
  }

  @override
  Future<TagCatalogPage> loadTagCatalog({
    required TagCatalogType type,
    required int page,
  }) async {
    return tagCatalogPage ??
        TagCatalogPage(
          result: const <TagCatalogItem>[],
          numPages: 1,
          perPage: 0,
          page: page,
        );
  }
}
