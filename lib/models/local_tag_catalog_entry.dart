import 'package:concept_nhv/models/tag_catalog_type.dart';

class LocalTagCatalogEntry {
  const LocalTagCatalogEntry({
    this.id,
    required this.type,
    required this.name,
    required this.slug,
    required this.count,
  });

  /// nhentai tag id — the same numbering as a gallery's `tag_ids`. Null when
  /// the catalog predates the `i` field (see P76).
  final int? id;
  final TagCatalogType type;
  final String name;
  final String slug;
  final int count;

  String get query => '${type.apiValue}:$slug';
}
