import 'dart:async';

import 'package:concept_nhv/application/tags/load_tag_catalog_use_case.dart';
import 'package:concept_nhv/models/comic.dart';
import 'package:concept_nhv/models/comic_search_response.dart';
import 'package:concept_nhv/models/comic_tag.dart';
import 'package:concept_nhv/models/tag_catalog_item.dart';
import 'package:concept_nhv/models/tag_catalog_page.dart';
import 'package:concept_nhv/models/tag_catalog_type.dart';
import 'package:concept_nhv/services/nhentai_api_client.dart';
import 'package:concept_nhv/state/tag_catalog_browser_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('setType resets selection and loads the first page for the new type', () async {
    final gateway = _FakeTagCatalogGateway();
    final model = TagCatalogBrowserModel(
      loadTagCatalogUseCase: LoadTagCatalogUseCase(nhentaiGateway: gateway),
    );

    await model.ensureLoaded();
    model.toggleSelection(
      const TagCatalogItem(
        id: 1,
        type: 'tag',
        name: 'sample',
        slug: 'sample',
        url: '/tag/sample/',
        count: 1,
      ),
    );

    await model.setType(TagCatalogType.language);

    expect(model.type, TagCatalogType.language);
    expect(model.selectedQueries, isEmpty);
    expect(model.currentPage?.page, 1);
    expect(gateway.requests, <String>['tag:1', 'language:1']);
  });

  test('ignores stale responses when a newer page request completes first', () async {
    final gateway = _SequencedTagCatalogGateway();
    final model = TagCatalogBrowserModel(
      loadTagCatalogUseCase: LoadTagCatalogUseCase(nhentaiGateway: gateway),
    );

    unawaited(model.loadPage(1));
    await model.loadPage(2);
    gateway.completePage(1, const TagCatalogPage(
      result: <TagCatalogItem>[],
      numPages: 3,
      perPage: 1,
      page: 1,
    ));
    await Future<void>.delayed(Duration.zero);
    expect(model.currentPage?.page, 2);
  });
}

class _FakeTagCatalogGateway implements NhentaiGateway {
  final List<String> requests = <String>[];

  @override
  Future<({List<ComicTag> tags, int? numFavorites, int? uploadDate})> loadComicMeta(
    String comicId,
  ) async =>
      (tags: const <ComicTag>[], numFavorites: null, uploadDate: null);

  @override
  Future<TagCatalogPage> loadTagCatalog({
    required TagCatalogType type,
    required int page,
  }) async {
    requests.add('${type.apiValue}:$page');
    return TagCatalogPage(
      result: <TagCatalogItem>[
        TagCatalogItem(
          id: page,
          type: type.apiValue,
          name: 'name-$page',
          slug: 'name-$page',
          url: '/${type.apiValue}/name-$page/',
          count: page,
        ),
      ],
      numPages: 3,
      perPage: 1,
      page: page,
    );
  }

  @override
  Future<({Comic comic, Map<String, String>? headers})> loadComicDetail(String comicId) {
    throw UnimplementedError();
  }

  @override
  Future<void> pingHomepage() async {}

  @override
  Future<ComicSearchResponse> searchComics(Uri uri) {
    throw UnimplementedError();
  }
}

class _SequencedTagCatalogGateway implements NhentaiGateway {
  final Map<int, Completer<TagCatalogPage>> _completers = <int, Completer<TagCatalogPage>>{
    1: Completer<TagCatalogPage>(),
    2: Completer<TagCatalogPage>()
      ..complete(
        const TagCatalogPage(
          result: <TagCatalogItem>[],
          numPages: 3,
          perPage: 1,
          page: 2,
        ),
      ),
  };

  void completePage(int page, TagCatalogPage result) {
    _completers[page]!.complete(result);
  }

  @override
  Future<({List<ComicTag> tags, int? numFavorites, int? uploadDate})> loadComicMeta(
    String comicId,
  ) async =>
      (tags: const <ComicTag>[], numFavorites: null, uploadDate: null);

  @override
  Future<TagCatalogPage> loadTagCatalog({
    required TagCatalogType type,
    required int page,
  }) {
    return _completers[page]!.future;
  }

  @override
  Future<({Comic comic, Map<String, String>? headers})> loadComicDetail(String comicId) {
    throw UnimplementedError();
  }

  @override
  Future<void> pingHomepage() async {}

  @override
  Future<ComicSearchResponse> searchComics(Uri uri) {
    throw UnimplementedError();
  }
}
