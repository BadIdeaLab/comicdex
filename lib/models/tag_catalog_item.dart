class TagCatalogItem {
  const TagCatalogItem({
    required this.id,
    required this.type,
    required this.name,
    required this.slug,
    required this.url,
    required this.count,
  });

  final int id;
  final String type;
  final String name;
  final String slug;
  final String url;
  final int count;

  String get query => '$type:$slug';
}
