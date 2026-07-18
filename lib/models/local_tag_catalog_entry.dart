import 'package:concept_nhv/models/tag_catalog_type.dart';

class LocalTagCatalogEntry {
  const LocalTagCatalogEntry({
    required this.type,
    required this.name,
    required this.slug,
    required this.count,
  });

  final TagCatalogType type;
  final String name;
  final String slug;
  final int count;

  String get query => '${type.apiValue}:$slug';
}
