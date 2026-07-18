class TagSearchQueryBuilder {
  const TagSearchQueryBuilder();

  String build(Iterable<String> rawQueries) {
    final normalized = rawQueries
        .map((query) => query.trim().toLowerCase())
        .where((query) => query.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return normalized.join(' ');
  }
}
