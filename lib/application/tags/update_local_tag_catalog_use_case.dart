import 'package:concept_nhv/application/tags/tag_catalog_update_urls.dart';
import 'package:concept_nhv/services/local_tag_catalog_service.dart';
import 'package:concept_nhv/services/remote_asset_fetcher.dart';

/// Downloads the full tag catalog and applies it via
/// [LocalTagCatalogService.applyOverrideBytes]. Callers should only invoke
/// this after [CheckTagCatalogUpdateUseCase] confirms a newer version is
/// available (and the user has confirmed the download), since this fetches
/// the entire multi-megabyte dataset.
class UpdateLocalTagCatalogUseCase {
  const UpdateLocalTagCatalogUseCase({
    required this.remoteAssetFetcher,
    required this.localTagCatalogService,
  });

  final RemoteAssetFetcher remoteAssetFetcher;
  final LocalTagCatalogService localTagCatalogService;

  /// Returns the resulting entry count after applying the update.
  Future<int> execute() async {
    final bytes = await remoteAssetFetcher.fetchBytes(tagCatalogReleaseUrl);
    await localTagCatalogService.applyOverrideBytes(bytes);
    return localTagCatalogService.entryCount;
  }
}
