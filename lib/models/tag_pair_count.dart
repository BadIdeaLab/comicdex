/// How many kept comics carry both tags. [tagA] is always the smaller id, so
/// each pair appears once.
class TagPairCount {
  const TagPairCount({
    required this.tagA,
    required this.tagB,
    required this.comicCount,
  });

  final int tagA;
  final int tagB;
  final int comicCount;
}
