import 'dart:io';

import 'package:concept_nhv/application/downloads/download_settings_repository.dart';
import 'package:concept_nhv/models/downloads_sort_mode.dart';
import 'package:concept_nhv/services/download_asset_store.dart';
import 'package:concept_nhv/services/nhentai_cdn_config_service.dart';
import 'package:concept_nhv/state/download_manager_model.dart';
import 'package:concept_nhv/widgets/downloads_sort_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../test_support/fakes/fake_image_compression_service.dart';
import '../test_support/fakes/fake_nhentai_gateway.dart';
import '../test_support/fakes/fake_remote_asset_fetcher.dart';
import '../test_support/storage/sqlite_test_harness.dart';

void main() {
  group('DownloadsSortBottomSheet', () {
    late SqliteTestHarness harness;
    late Directory tempDirectory;
    late DownloadManagerModel model;

    setUp(() async {
      harness = SqliteTestHarness();
      await harness.initialize();
      tempDirectory = await Directory.systemTemp.createTemp('nhv-sort-test');
      model = DownloadManagerModel(
        nhentaiGateway: FakeNhentaiGateway(),
        cdnConfigService: NhentaiCdnConfigService(),
        downloadQueueRepository: harness.downloadQueueRepository,
        downloadedLibraryRepository: harness.downloadedLibraryRepository,
        downloadSettingsRepository: _FakeDownloadSettingsRepository(),
        downloadAssetStore: DownloadAssetStore(
          directoryResolver: () async => tempDirectory,
        ),
        imageCompressionService: FakeImageCompressionService(),
        remoteAssetFetcher: FakeRemoteAssetFetcher(),
      );
    });

    tearDown(() async {
      model.dispose();
      await harness.dispose();
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    testWidgets('applies selected sort mode and direction as soon as chips are tapped', (
      tester,
    ) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<DownloadManagerModel>.value(
          value: model,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return FilledButton(
                    onPressed: () => DownloadsSortBottomSheet.show(context),
                    child: const Text('Open Sort'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sort'));
      await tester.pumpAndSettle();

      expect(model.downloadsSortMode, DownloadsSortMode.latestDownloaded);
      expect(
        model.downloadsSortDirection,
        DownloadsSortDirection.descending,
      );
      expect(find.text('Most Favorited'), findsOneWidget);
      expect(find.text('Ascending'), findsOneWidget);

      await tester.tap(find.text('Most Favorited'));
      await tester.pumpAndSettle();

      expect(model.downloadsSortMode, DownloadsSortMode.mostFavorited);

      await tester.tap(find.text('Ascending'));
      await tester.pumpAndSettle();

      expect(model.downloadsSortDirection, DownloadsSortDirection.ascending);

      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      expect(model.downloadsSortMode, DownloadsSortMode.latestDownloaded);
      expect(
        model.downloadsSortDirection,
        DownloadsSortDirection.descending,
      );
    });
  });
}

class _FakeDownloadSettingsRepository implements DownloadSettingsRepository {
  @override
  Future<bool> loadAutoResumeEnabled() async => false;

  @override
  Future<void> saveAutoResumeEnabled(bool enabled) async {}

  @override
  Future<int> loadPageIntervalMs() async => 500;

  @override
  Future<void> savePageIntervalMs(int milliseconds) async {}
}
