import 'dart:convert';

import 'package:concept_nhv/application/tags/tag_catalog_update_urls.dart';
import 'package:concept_nhv/services/local_tag_catalog_service.dart';
import 'package:concept_nhv/services/remote_asset_fetcher.dart';

/// Checks whether a newer tag catalog is available without downloading the
/// full dataset — only the small `tag_catalog.version` companion file is
/// fetched for comparison.
class CheckTagCatalogUpdateUseCase {
  const CheckTagCatalogUpdateUseCase({
    required this.remoteAssetFetcher,
    required this.localTagCatalogService,
  });

  final RemoteAssetFetcher remoteAssetFetcher;
  final LocalTagCatalogService localTagCatalogService;

  /// Returns the newer version string if an update is available, or `null`
  /// if the current tag catalog is already up to date.
  Future<String?> execute() async {
    final bytes = await remoteAssetFetcher.fetchBytes(tagCatalogVersionUrl);
    final candidateVersion = utf8.decode(bytes).trim();
    final isNewer = LocalTagCatalogService.isNewerVersion(
      candidateVersion,
      localTagCatalogService.version,
    );
    return isNewer ? candidateVersion : null;
  }
}
