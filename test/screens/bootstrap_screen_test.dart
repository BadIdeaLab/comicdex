import 'dart:async';
import 'dart:io';

import 'package:concept_nhv/application/feed/load_collection_summaries_use_case.dart';
import 'package:concept_nhv/application/feed/search_comics_use_case.dart';
import 'package:concept_nhv/models/comic_search_response.dart';
import 'package:concept_nhv/screens/bootstrap_screen.dart';
import 'package:concept_nhv/services/backup/restore_progress_flag.dart';
import 'package:concept_nhv/services/search_query_builder.dart';
import 'package:concept_nhv/state/comic_feed_model.dart';
import 'package:concept_nhv/state/home_ui_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../test_support/fakes/fake_blocked_tags_repository.dart';
import '../test_support/fakes/fake_nhentai_gateway.dart';
import '../test_support/helpers/localized_test_app.dart';
import '../test_support/storage/sqlite_test_harness.dart';

/// A site that accepted the connection and then said nothing — the case that
/// used to strand the user on the loading screen, and the one a timeout only
/// shortens rather than fixes.
class _SilentGateway extends FakeNhentaiGateway {
  final Completer<ComicSearchResponse> _never =
      Completer<ComicSearchResponse>();

  @override
  Future<ComicSearchResponse> searchComics(Uri uri) => _never.future;
}

void main() {
  group('BootstrapScreen', () {
    late SqliteTestHarness harness;
    late Directory tempDirectory;

    setUp(() async {
      harness = SqliteTestHarness();
      await harness.initialize();
      tempDirectory = await Directory.systemTemp.createTemp('nhv-bootstrap');
    });

    tearDown(() async {
      await harness.dispose();
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    Widget buildApp(FakeNhentaiGateway gateway) {
      final feed = ComicFeedModel(
        searchComicsUseCase: SearchComicsUseCase(
          nhentaiGateway: gateway,
          searchQueryBuilder: const SearchQueryBuilder(),
          // Nothing here is testing the backoff, and the real one would make
          // this test sit through it.
          retrySleep: (_) async {},
        ),
        loadCollectionSummariesUseCase: LoadCollectionSummariesUseCase(
          collectionRepository: harness.collectionRepository,
        ),
        blockedTagsRepository: FakeBlockedTagsRepository(),
      );

      final router = GoRouter(
        initialLocation: '/',
        routes: <RouteBase>[
          GoRoute(path: '/', builder: (_, _) => const BootstrapScreen()),
          GoRoute(
            path: '/index',
            builder: (_, _) =>
                const Scaffold(body: Center(child: Text('home tab'))),
          ),
        ],
      );

      return MultiProvider(
        providers: <SingleChildWidget>[
          Provider<RestoreProgressFlag>.value(
            value: RestoreProgressFlag(
              supportDirectory: () async => tempDirectory,
            ),
          ),
          ChangeNotifierProvider<HomeUiModel>(create: (_) => HomeUiModel()),
          ChangeNotifierProvider<ComicFeedModel>.value(value: feed),
        ],
        child: localizedTestRouterApp(routerConfig: router),
      );
    }

    testWidgets('reaches the home tab without waiting for the feed', (
      tester,
    ) async {
      // The bug this pins: the first page load was awaited *before*
      // navigating, so an unreachable site left the user on a spinner with no
      // back button, no error and no retry — because the screen carrying all
      // three was the one being waited for.
      await tester.pumpWidget(buildApp(_SilentGateway()));

      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('home tab'), findsOneWidget);
    });

    testWidgets('a reachable site still loads the feed', (tester) async {
      final gateway = FakeNhentaiGateway();

      await tester.pumpWidget(buildApp(gateway));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('home tab'), findsOneWidget);
      expect(
        gateway.searchedUris,
        isNotEmpty,
        reason: 'navigating first must not mean never loading',
      );
    });
  });
}
