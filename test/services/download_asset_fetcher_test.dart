import 'dart:typed_data';

import 'package:concept_nhv/services/download_asset_fetcher.dart';
import 'package:concept_nhv/services/download_asset_store.dart';
import 'package:concept_nhv/services/image_compression_service.dart';
import 'package:concept_nhv/services/nhentai_cdn_config_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_support/fakes/fake_image_compression_service.dart';
import '../test_support/fakes/fake_remote_asset_fetcher.dart';

void main() {
  final bytes = Uint8List.fromList(<int>[1, 2, 3]);

  DownloadAssetFetcher fetcherWith(ImageCompressionService compression) {
    return DownloadAssetFetcher(
      cdnConfigService: NhentaiCdnConfigService(),
      downloadAssetStore: DownloadAssetStore(
        directoryResolver: () async => throw UnimplementedError(),
      ),
      imageCompressionService: compression,
      remoteAssetFetcher: FakeRemoteAssetFetcher(),
    );
  }

  group('compressWithFallback', () {
    test('leaves a format Flutter can decode alone', () async {
      // Re-encoding a JPEG would cost time and quality for nothing.
      final compression = FakeImageCompressionService();

      final asset = await fetcherWith(compression).compressWithFallback(
        bytes,
        fallbackExtension: 'JPG',
      );

      expect(asset.extension, 'jpg', reason: 'normalized to lower case');
      expect(asset.bytes, bytes);
      expect(compression.callCount, 0);
    });

    test('transcodes anything else to WebP', () async {
      // heif/avif/tiff would leave the reader stuck on a file it cannot
      // decode.
      final asset = await fetcherWith(
        FakeImageCompressionService(),
      ).compressWithFallback(bytes, fallbackExtension: 'heif');

      expect(asset.extension, 'webp');
    });

    test('keeps the original when transcoding fails', () async {
      // An unconverted page still beats no page.
      final asset = await fetcherWith(
        FakeImageCompressionService(error: UnsupportedError('no codec')),
      ).compressWithFallback(bytes, fallbackExtension: 'heif');

      expect(asset.extension, 'heif');
      expect(asset.bytes, bytes);
    });

    test('keeps the original when transcoding returns nothing', () async {
      final asset = await fetcherWith(
        FakeImageCompressionService(result: Uint8List(0)),
      ).compressWithFallback(bytes, fallbackExtension: 'heif');

      expect(asset.extension, 'heif');
      expect(asset.bytes, bytes);
    });
  });

  group('extensionFromPath', () {
    test('takes the last segment, lower-cased', () {
      expect(DownloadAssetFetcher.extensionFromPath('/g/1/2.JPG'), 'jpg');
    });

    test('falls back to bin when there is no extension at all', () {
      // Something has to be written, and a bare name gives nothing to go on.
      expect(DownloadAssetFetcher.extensionFromPath('/g/1/2'), 'bin');
    });

    test('handles a doubled extension', () {
      expect(DownloadAssetFetcher.extensionFromPath('/g/1/2.jpg.jpg'), 'jpg');
    });
  });
}
