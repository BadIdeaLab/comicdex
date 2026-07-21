import 'dart:io';
import 'dart:typed_data';

import 'package:concept_nhv/application/tags/tag_catalog_update_urls.dart';
import 'package:concept_nhv/application/tags/update_local_tag_catalog_use_case.dart';
import 'package:concept_nhv/models/local_tag_catalog_entry.dart';
import 'package:concept_nhv/services/local_tag_catalog_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_support/fakes/fake_remote_asset_fetcher.dart';
import '../../test_support/helpers/tag_catalog_encoding.dart';

void main() {
  late Directory tempDirectory;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('update_tag_catalog_use_case_test');
  });

  tearDown(() async {
    await tempDirectory.delete(recursive: true);
  });

  test('downloads and applies the full catalog, returning the new entry count', () async {
    final service = LocalTagCatalogService.fromEntries(
      const <LocalTagCatalogEntry>[],
      version: '2026-06-01',
      overrideDirectoryResolver: () async => tempDirectory,
    );
    final catalogBytes = encodeTagCatalog('2026-07-01', <Map<String, Object?>>[
      <String, Object?>{'t': 'tag', 'n': 'full color', 's': 'full-color', 'c': 10},
      <String, Object?>{'t': 'tag', 'n': 'big breasts', 's': 'big-breasts', 'c': 20},
    ]);
    final fetcher = FakeRemoteAssetFetcher(
      responses: <String, Uint8List>{tagCatalogReleaseUrl: catalogBytes},
    );
    final useCase = UpdateLocalTagCatalogUseCase(
      remoteAssetFetcher: fetcher,
      localTagCatalogService: service,
    );

    final count = await useCase.execute();

    expect(count, 2);
    expect(service.version, '2026-07-01');
    expect(service.isUsingOverride, isTrue);
    expect(fetcher.requestedUrls, <String>[tagCatalogReleaseUrl]);
  });

  test('propagates a download failure without applying a partial update', () async {
    final service = LocalTagCatalogService.fromEntries(
      const <LocalTagCatalogEntry>[],
      version: '2026-06-01',
      overrideDirectoryResolver: () async => tempDirectory,
    );
    final fetcher = FakeRemoteAssetFetcher(error: StateError('network down'));
    final useCase = UpdateLocalTagCatalogUseCase(
      remoteAssetFetcher: fetcher,
      localTagCatalogService: service,
    );

    await expectLater(useCase.execute(), throwsStateError);
    expect(service.isUsingOverride, isFalse);
    expect(service.version, '2026-06-01');
  });
}
