import 'package:concept_nhv/application/reader/load_comic_detail_use_case.dart';
import 'package:concept_nhv/application/reader/load_offline_comic_use_case.dart';
import 'package:concept_nhv/application/reader/open_comic_use_case.dart';
import 'package:concept_nhv/services/download_asset_store.dart';
import 'package:concept_nhv/services/image_url_resolver.dart';
import 'package:concept_nhv/state/reader_session_model.dart';
import 'package:concept_nhv/storage/options_store.dart';
import 'package:concept_nhv/storage/reader_progress_store.dart';
import 'package:concept_nhv/widgets/fallback_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../test_support/fakes/fake_nhentai_gateway.dart';
import '../test_support/fakes/fake_reader_settings_repository.dart';
import '../test_support/storage/sqlite_test_harness.dart';

void main() {
  group('FallbackCachedNetworkImage', () {
    late SqliteTestHarness harness;
    late ReaderSessionModel readerModel;

    setUp(() async {
      // Built here rather than inside testWidgets: drift's real async work does
      // not advance inside the widget-test fake async zone.
      harness = SqliteTestHarness();
      await harness.initialize();
      readerModel = ReaderSessionModel(
        loadComicDetailUseCase: LoadComicDetailUseCase(
          nhentaiGateway: FakeNhentaiGateway(),
        ),
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
        readerProgressRepository: ReaderProgressStore(
          optionsStore: OptionsStore(localDatabase: harness.localDatabase),
        ),
        readerSettingsRepository: FakeReaderSettingsRepository(),
        downloadedLibraryRepository: harness.downloadedLibraryRepository,
      );
    });

    tearDown(() async {
      readerModel.dispose();
      await harness.dispose();
    });

    testWidgets('does not rebuild when the reader model notifies', (
      tester,
    ) async {
      // This widget draws every comic cover in the app — feed cards, collection
      // cells, download covers. It used to watch ComicReaderModel just to read
      // `currentHeaders`, so a reader page turn rebuilt every visible cover on
      // the routes underneath (measured: 12 covers x 5 turns = 60 rebuilds) to
      // obtain a value that is always null. Covers must not depend on which
      // comic happens to be open.
      var builds = 0;

      await tester.pumpWidget(
        ChangeNotifierProvider<ReaderSessionModel>.value(
          value: readerModel,
          child: MaterialApp(
            home: FallbackCachedNetworkImage(
              url: 'https://t1.nhentai.net/galleries/1/thumb.webp',
              width: 9,
              height: 16,
              imageUrlResolver: const ImageUrlResolver(),
              imageBuilder: (context, url, headers, placeholder, error) {
                builds++;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(builds, 1);

      // The signal a page turn emits.
      readerModel.toggleControls();
      await tester.pump();
      readerModel.toggleControls();
      await tester.pump();

      expect(
        builds,
        1,
        reason: 'covers must not rebuild because the reader changed page',
      );
    });
  });
}
