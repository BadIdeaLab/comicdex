import 'package:concept_nhv/models/comic.dart';

class ComicDetailResult {
  const ComicDetailResult({required this.comic, required this.headers});

  final Comic comic;
  final Map<String, String>? headers;
}
