enum TagCatalogType {
  tag('tag'),
  language('language'),
  parody('parody'),
  character('character'),
  artist('artist');

  const TagCatalogType(this.apiValue);

  final String apiValue;
}
