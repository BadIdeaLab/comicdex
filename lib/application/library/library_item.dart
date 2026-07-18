class LibraryItem {
  const LibraryItem({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.thumbnailWidth,
    required this.thumbnailHeight,
  });

  final String id;
  final String title;
  final String thumbnailUrl;
  final int thumbnailWidth;
  final int thumbnailHeight;
}
