import 'package:concept_nhv/app/app_providers.dart';
import 'package:concept_nhv/application/feed/search_comics_use_case.dart';
import 'package:concept_nhv/application/home/home_shell_controller.dart';
import 'package:concept_nhv/services/local_tag_catalog_service.dart';
import 'package:concept_nhv/models/local_tag_catalog_entry.dart';
import 'package:concept_nhv/services/nhentai_api_client.dart';
import 'package:concept_nhv/services/tag_display_service.dart';
import 'package:concept_nhv/state/comic_feed_model.dart';
import 'package:concept_nhv/storage/local_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../test_support/storage/sqlite_test_harness.dart';

void main() {
  testWidgets(
    'buildAppProviders wires up representative types across every layer',
    (tester) async {
      final harness = SqliteTestHarness();
      await harness.initialize();
      addTearDown(harness.dispose);

      late BuildContext capturedContext;

      await tester.pumpWidget(
        MultiProvider(
          providers: buildAppProviders(
            harness.localDatabase,
            TagDisplayService.fromMap(const {}),
            LocalTagCatalogService.fromEntries(const <LocalTagCatalogEntry>[]),
          ),
          child: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      // Resolving NhentaiGateway transitively creates NhentaiCdnConfigService,
      // whose `create` callback fires an unawaited background refresh. Run
      // the reads inside `runAsync` so that real (non-fake-async) work isn't
      // flagged as a leaked timer when the test completes.
      await tester.runAsync(() async {
        // Infrastructure layer
        expect(capturedContext.read<LocalDatabase>(), isNotNull);
        // Service layer
        expect(capturedContext.read<NhentaiGateway>(), isNotNull);
        // Use case layer
        expect(capturedContext.read<SearchComicsUseCase>(), isNotNull);
        // State layer
        expect(capturedContext.read<ComicFeedModel>(), isNotNull);
        // Coordinator layer
        expect(capturedContext.read<HomeShellController>(), isNotNull);

        // Resolving the above transitively triggers a few fire-and-forget
        // async initializers (e.g. ComicReaderModel.loadSettings()). Give
        // them a moment to finish while the widget tree is still mounted,
        // so they don't call notifyListeners() on a disposed model once the
        // test tears down.
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
    },
  );
}
