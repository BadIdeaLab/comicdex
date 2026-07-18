import 'package:concept_nhv/models/comic_tag.dart';
import 'package:concept_nhv/services/nhentai_api_client.dart';

class LoadComicMetaUseCase {
  const LoadComicMetaUseCase({required this.nhentaiGateway});

  final NhentaiGateway nhentaiGateway;

  Future<({List<ComicTag> tags, int? numFavorites, int? uploadDate})> execute(String comicId) {
    return nhentaiGateway.loadComicMeta(comicId);
  }
}
