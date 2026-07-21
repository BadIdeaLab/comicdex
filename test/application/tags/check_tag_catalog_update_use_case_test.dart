import 'dart:convert';
import 'dart:typed_data';

import 'package:concept_nhv/application/tags/check_tag_catalog_update_use_case.dart';
import 'package:concept_nhv/application/tags/tag_catalog_update_urls.dart';
import 'package:concept_nhv/models/local_tag_catalog_entry.dart';
import 'package:concept_nhv/services/local_tag_catalog_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_support/fakes/fake_remote_asset_fetcher.dart';

void main() {
  test('returns the candidate version when it is newer', () async {
    final service = LocalTagCatalogService.fromEntries(
      const <LocalTagCatalogEntry>[],
      version: '2026-06-01',
    );
    final fetcher = FakeRemoteAssetFetcher(
      responses: <String, Uint8List>{
        tagCatalogVersionUrl: utf8.encode('2026-07-01'),
      },
    );
    final useCase = CheckTagCatalogUpdateUseCase(
      remoteAssetFetcher: fetcher,
      localTagCatalogService: service,
    );

    final result = await useCase.execute();

    expect(result, '2026-07-01');
    expect(fetcher.requestedUrls, <String>[tagCatalogVersionUrl]);
  });

  test('returns null when the candidate version is the same or older', () async {
    final service = LocalTagCatalogService.fromEntries(
      const <LocalTagCatalogEntry>[],
      version: '2026-06-01',
    );
    final fetcher = FakeRemoteAssetFetcher(
      responses: <String, Uint8List>{
        tagCatalogVersionUrl: utf8.encode('2026-06-01'),
      },
    );
    final useCase = CheckTagCatalogUpdateUseCase(
      remoteAssetFetcher: fetcher,
      localTagCatalogService: service,
    );

    final result = await useCase.execute();

    expect(result, isNull);
  });

  test('trims whitespace from the fetched version string', () async {
    final service = LocalTagCatalogService.fromEntries(
      const <LocalTagCatalogEntry>[],
      version: '2026-06-01',
    );
    final fetcher = FakeRemoteAssetFetcher(
      responses: <String, Uint8List>{
        tagCatalogVersionUrl: utf8.encode('2026-07-01\n'),
      },
    );
    final useCase = CheckTagCatalogUpdateUseCase(
      remoteAssetFetcher: fetcher,
      localTagCatalogService: service,
    );

    final result = await useCase.execute();

    expect(result, '2026-07-01');
  });
}
