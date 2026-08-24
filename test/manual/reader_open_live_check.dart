// Manual verification of the reader open path against the real nhentai API.
//
// NOT part of the automated suite: `flutter test` only collects `*_test.dart`
// under test/, so this file is skipped unless it is named explicitly:
//
//     flutter test test/manual/reader_open_live_check.dart
//
// Why it exists: every automated test here uses a fake gateway, so the reader
// has only ever been proven against instant, deterministic loads. Two things
// only a real load can show:
//
//   * how long the reader actually shows its loading state (P67 chose "screen
//     first, then load", so this is now visible to the user);
//   * that a real failure ends in the reader's error state rather than an
//     exception or an endless spinner.
//
// Requests are deliberately few and spaced by [_cooldown]. Do not turn this
// into a loop or a benchmark.

// Printing is this file's entire output — it is a report you read, not app code.
// ignore_for_file: avoid_print

import 'dart:async';

import 'package:concept_nhv/application/reader/load_comic_detail_use_case.dart';
import 'package:concept_nhv/application/reader/load_offline_comic_use_case.dart';
import 'package:concept_nhv/application/reader/open_comic_use_case.dart';
import 'package:concept_nhv/application/reader/reader_launcher.dart';
import 'package:concept_nhv/services/download_asset_store.dart';
import 'package:concept_nhv/services/nhentai_api_client.dart';
import 'package:concept_nhv/services/nhentai_cdn_config_service.dart';
import 'package:concept_nhv/state/download_manager_model.dart';
import 'package:concept_nhv/state/reader_session_model.dart';
import 'package:concept_nhv/storage/download_settings_store.dart';
import 'package:concept_nhv/storage/nhentai_api_key_store.dart';
import 'package:concept_nhv/storage/options_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_support/fakes/fake_image_compression_service.dart';
import '../test_support/fakes/fake_nhentai_gateway.dart';
import '../test_support/fakes/fake_reader_settings_repository.dart';
import '../test_support/fakes/fake_remote_asset_fetcher.dart';
import '../test_support/fakes/memory_secure_store.dart';
import '../test_support/storage/sqlite_test_harness.dart';

/// Spacing between phases, so a run never looks like a burst.
const Duration _cooldown = Duration(seconds: 3);

/// An id that cannot exist, used to force a real failing load.
const String _missingComicId = '999999999';

void main() {
  test(
    'the reader opens, guards and fails correctly against the real API',
    () async {
      final harness = SqliteTestHarness();
      await harness.initialize();

      final requests = <String>[];
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requests.add(options.uri.path);
              handler.next(options);
            },
          ),
        );

      final client = NhentaiApiClient(
        apiKeyStore: NhentaiApiKeyStore(
          secureStore: MemorySecureKeyValueStore(),
        ),
        cdnConfigService: NhentaiCdnConfigService(),
        dio: dio,
      );

      ReaderSessionModel newSession() => ReaderSessionModel(
        loadComicDetailUseCase: LoadComicDetailUseCase(nhentaiGateway: client),
        loadOfflineComicUseCase: LoadOfflineComicUseCase(
          downloadQueueRepository: harness.downloadQueueRepository,
          downloadedLibraryRepository: harness.downloadedLibraryRepository,
          downloadAssetStore: DownloadAssetStore(
            directoryResolver: () async => throw UnimplementedError(),
          ),
        ),
        openComicUseCase: OpenComicUseCase(
          comicRepository: harness.comicRepository,
          collectionRepository: harness.collectionRepository,
        ),
        readerSettingsRepository: FakeReaderSettingsRepository(),
        downloadedLibraryRepository: harness.downloadedLibraryRepository,
      );

      final launcher = ReaderLauncher(
        downloadManagerModel: _StubDownloadManagerModel(harness: harness),
      );

      // Phase 1: pick a real comic.
      // Taken from the live listing rather than hard-coded, so the run cannot
      // pass against an id that has since been removed.
      final listing = await client.searchComics(
        Uri.https('nhentai.net', '/api/v2/galleries', <String, String>{
          'page': '1',
        }),
      );
      expect(
        listing.result,
        isNotEmpty,
        reason: 'the live listing returned nothing — check connectivity first',
      );
      final comicId = listing.result.first.id;
      print('[1] live comic id: $comicId');

      await Future<void>.delayed(_cooldown);

      // Phase 2: how long the reader shows its loading state for real.
      final session = newSession();
      final stopwatch = Stopwatch()..start();
      await session.open(comicId: comicId, offline: false);
      stopwatch.stop();
      print('[2] loading state visible for ${stopwatch.elapsedMilliseconds}ms');
      expect(session.loadState, ReaderLoadState.ready);
      expect(session.currentComic?.id, comicId);
      session.dispose();

      await Future<void>.delayed(_cooldown);

      // Phase 3: a double tap must still produce exactly one reader route.
      // The guard is now purely about navigation — each route would build its
      // own session — but two readers for one tap is never what a user meant.
      var routes = 0;
      final firstShown = Completer<void>();
      final firstShowing = Completer<void>();

      final firstTap = launcher.open(
        show: () {
          routes++;
          firstShown.complete();
          return firstShowing.future;
        },
      );
      final secondTap = launcher.open(show: () async => routes++);

      await secondTap;
      await firstShown.future;
      expect(routes, 1, reason: 'only the first tap may reach the reader');
      firstShowing.complete();
      await firstTap;
      print('[3] double tap pushed $routes route(s)');

      await Future<void>.delayed(_cooldown);

      // Phase 4: a real 404 must land in the error state, not throw.
      // Before P67 the load happened before navigation, so a failure simply
      // meant no reader appeared. Now the reader is already on screen when the
      // request fails — if this threw, the user would be left staring at a
      // spinner with no way out.
      final failing = newSession();
      await failing.open(comicId: _missingComicId, offline: false);
      expect(failing.loadState, ReaderLoadState.failed);
      expect(failing.failure, ReaderLoadFailure.loadFailed);
      print('[4] live 404 produced ${failing.failure}');

      await Future<void>.delayed(_cooldown);

      // Phase 5: retrying the same session recovers.
      await failing.open(comicId: comicId, offline: false);
      expect(failing.loadState, ReaderLoadState.ready);
      print('[5] retry after the failure reached ${failing.loadState}');
      failing.dispose();

      print('[--] total HTTP requests this run: ${requests.length}');

      await harness.dispose();
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

class _StubDownloadManagerModel extends DownloadManagerModel {
  _StubDownloadManagerModel({required SqliteTestHarness harness})
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

  @override
  Future<void> refresh() async {}
}
