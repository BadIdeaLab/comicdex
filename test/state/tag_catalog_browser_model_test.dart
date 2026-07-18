import 'package:concept_nhv/models/local_tag_catalog_entry.dart';
import 'package:concept_nhv/models/tag_catalog_type.dart';
import 'package:concept_nhv/services/local_tag_catalog_service.dart';
import 'package:concept_nhv/services/tag_display_service.dart';
import 'package:concept_nhv/state/tag_catalog_browser_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const tagEntries = <LocalTagCatalogEntry>[
    LocalTagCatalogEntry(
      type: TagCatalogType.tag,
      name: 'full color',
      slug: 'full-color',
      count: 10,
    ),
    LocalTagCatalogEntry(
      type: TagCatalogType.tag,
      name: 'big breasts',
      slug: 'big-breasts',
      count: 20,
    ),
  ];
  const languageEntries = <LocalTagCatalogEntry>[
    LocalTagCatalogEntry(
      type: TagCatalogType.language,
      name: 'chinese',
      slug: 'chinese',
      count: 5,
    ),
  ];

  TagCatalogBrowserModel buildModel() {
    final service = LocalTagCatalogService.fromEntries(<LocalTagCatalogEntry>[
      ...tagEntries,
      ...languageEntries,
    ]);
    return TagCatalogBrowserModel(
      localTagCatalogService: service,
      tagDisplayService: TagDisplayService.fromMap({}),
    );
  }

  test('ensureLoaded populates results for the default type sorted by count', () {
    final model = buildModel();
    model.ensureLoaded();

    expect(model.type, TagCatalogType.tag);
    expect(model.results.map((e) => e.slug), <String>['big-breasts', 'full-color']);
  });

  test('setQuery ranks prefix matches above contains matches', () async {
    final model = buildModel();
    model.setQuery('full');
    await Future<void>.delayed(const Duration(milliseconds: 250));

    expect(model.results.single.slug, 'full-color');
  });

  test('setType switches category results without clearing selectedQueries', () {
    final model = buildModel();
    model.ensureLoaded();
    model.toggleSelection(tagEntries.first);

    model.setType(TagCatalogType.language);

    expect(model.type, TagCatalogType.language);
    expect(model.results.map((e) => e.slug), <String>['chinese']);
    expect(model.selectedQueries, <String>['tag:full-color']);
  });

  test('selecting tags across two different categories accumulates without clearing', () {
    final model = buildModel();
    model.ensureLoaded();
    model.toggleSelection(tagEntries.first);

    model.setType(TagCatalogType.language);
    model.toggleSelection(languageEntries.first);

    expect(
      model.selectedQueries,
      <String>['language:chinese', 'tag:full-color'],
    );
  });
}
