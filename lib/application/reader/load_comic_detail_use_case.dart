import 'package:concept_nhv/models/comic.dart';
import 'package:concept_nhv/services/nhentai_api_client.dart';

class LoadComicDetailUseCase {
  const LoadComicDetailUseCase({required this.nhentaiGateway});

  final NhentaiGateway nhentaiGateway;

  Future<Comic> execute(String comicId) {
    return nhentaiGateway.loadComicDetail(comicId);
  }
}
