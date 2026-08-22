import 'dart:async';

import 'package:concept_nhv/application/reader/reader_launcher.dart';
import 'package:concept_nhv/services/download_asset_store.dart';
import 'package:concept_nhv/services/nhentai_cdn_config_service.dart';
import 'package:concept_nhv/state/download_manager_model.dart';
import 'package:concept_nhv/storage/download_settings_store.dart';
import 'package:concept_nhv/storage/options_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_support/fakes/fake_image_compression_service.dart';
import '../test_support/fakes/fake_nhentai_gateway.dart';
import '../test_support/fakes/fake_remote_asset_fetcher.dart';
import '../test_support/storage/sqlite_test_harness.dart';

void main() {
  group('ReaderLauncher', () {
    late SqliteTestHarness harness;
    late _FakeDownloadManagerModel downloadManagerModel;
    late ReaderLauncher launcher;

    setUp(() async {
      harness = SqliteTestHarness();
      await harness.initialize();
      downloadManagerModel = _FakeDownloadManagerModel(harness: harness);
      launcher = ReaderLauncher(downloadManagerModel: downloadManagerModel);
    });

    tearDown(() async {
      await harness.dispose();
    });

    test('a second request while the reader is open is ignored', () async {
      // The reader route stays on screen until `show` completes — exactly the
      // window a double tap used to slip through.
      final firstShow = Completer<void>();
      var shows = 0;

      final first = launcher.open(
        show: () {
          shows++;
          return firstShow.future;
        },
      );
      final second = launcher.open(show: () async => shows++);

      await second;
      expect(shows, 1, reason: 'the second tap must not push a route');

      firstShow.complete();
      await first;
      expect(shows, 1);
    });

    test('a second request after the first finished opens normally', () async {
      var shows = 0;
      Future<void> show() async => shows++;

      await launcher.open(show: show);
      await launcher.open(show: show);

      expect(shows, 2);
    });

    test('refreshes downloads once the reader closes', () async {
      // Reading updates last-read timestamps, so the Downloads list is stale
      // until this runs.
      await launcher.open(show: () async {});

      expect(downloadManagerModel.refreshCount, 1);
    });

    test('a show that throws still releases the guard', () async {
      // The failure mode this guards against is worse than the original bug:
      // a stuck flag would make every later attempt to open any comic silently
      // do nothing, with no error to explain it.
      await expectLater(
        launcher.open(show: () async => throw StateError('navigation failed')),
        throwsStateError,
      );

      expect(launcher.isOpening, isFalse);

      var shows = 0;
      await launcher.open(show: () async => shows++);
      expect(shows, 1, reason: 'the next open must still work');
    });
  });
}

class _FakeDownloadManagerModel extends DownloadManagerModel {
  _FakeDownloadManagerModel({required SqliteTestHarness harness})
      : super(
          nhentaiGateway: FakeNhentaiGateway(),
          cdnConfigService: NhentaiCdnConfigService(),
          downloadQueueRepository: harness.downloadQueueRepository,
          downloadedLibraryRepository: harness.downloadedLibraryRepository,
          downloadSettingsRepository: DownloadSettingsStore(
            optionsStore: OptionsStore(localDatabase: harness.localDatabase),
          ),
          downloadAssetStore: DownloadAssetStore(
            directoryResolver: () async => throw UnimplementedError(),
          ),
          imageCompressionService: FakeImageCompressionService(),
          remoteAssetFetcher: FakeRemoteAssetFetcher(),
        );

  int refreshCount = 0;

  @override
  Future<void> refresh() async {
    refreshCount++;
  }
}
