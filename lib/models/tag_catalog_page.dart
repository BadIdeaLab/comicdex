import 'package:concept_nhv/models/tag_catalog_item.dart';

class TagCatalogPage {
  const TagCatalogPage({
    required this.result,
    required this.numPages,
    required this.perPage,
    required this.page,
  });

  final List<TagCatalogItem> result;
  final int numPages;
  final int perPage;
  final int page;
}
