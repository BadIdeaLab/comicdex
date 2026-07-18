import 'package:concept_nhv/models/tag_catalog_page.dart';
import 'package:concept_nhv/models/tag_catalog_type.dart';
import 'package:concept_nhv/services/nhentai_api_client.dart';

class LoadTagCatalogUseCase {
  const LoadTagCatalogUseCase({required this.nhentaiGateway});

  final NhentaiGateway nhentaiGateway;

  Future<TagCatalogPage> execute({
    required TagCatalogType type,
    required int page,
  }) {
    return nhentaiGateway.loadTagCatalog(type: type, page: page);
  }
}
