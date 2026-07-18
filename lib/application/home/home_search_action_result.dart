class HomeSearchActionResult {
  const HomeSearchActionResult({
    required this.openComicReader,
    this.comicId,
  });

  final bool openComicReader;
  final String? comicId;
}
