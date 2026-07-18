import 'package:concept_nhv/application/reader/comic_detail_result.dart';
import 'package:concept_nhv/services/nhentai_api_client.dart';

class LoadComicDetailUseCase {
  const LoadComicDetailUseCase({required this.nhentaiGateway});

  final NhentaiGateway nhentaiGateway;

  Future<ComicDetailResult> execute(String comicId) async {
    final result = await nhentaiGateway.loadComicDetail(comicId);
    return ComicDetailResult(comic: result.comic, headers: result.headers);
  }
}
