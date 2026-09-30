import 'package:concept_nhv/application/tracking/check_tracked_artists_use_case.dart';
import 'package:concept_nhv/application/tracking/foreground_ticker.dart';
import 'package:concept_nhv/models/local_tag_catalog_entry.dart';
import 'package:concept_nhv/models/tag_catalog_type.dart';
import 'package:concept_nhv/services/local_tag_catalog_service.dart';
import 'package:concept_nhv/services/search_query_builder.dart';
import 'package:concept_nhv/state/tracking_model.dart';
import 'package:concept_nhv/storage/options_store.dart';
import 'package:concept_nhv/storage/tracking_state_store.dart';
import 'package:concept_nhv/widgets/tracking/tracking_bell_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../test_support/fakes/fake_blocked_tags_repository.dart';
import '../test_support/fakes/fake_nhentai_gateway.dart';
import '../test_support/helpers/localized_test_app.dart';
import '../test_support/storage/sqlite_test_harness.dart';

void main() {
  group('TrackingBellAction', () {
    late SqliteTestHarness harness;

    final catalog = LocalTagCatalogService.fromEntries(<LocalTagCatalogEntry>[
      const LocalTagCatalogEntry(
        id: 1,
        type: TagCatalogType.artist,
        name: 'artist',
        slug: 'artist',
        count: 40,
      ),
    ]);

    setUp(() async {
      harness = SqliteTestHarness();
      await harness.initialize();
    });

    tearDown(() async {
      await harness.dispose();
    });

    Future<TrackingModel> buildModel({required int newCount}) async {
      final model = TrackingModel(
        trackedArtistRepository: harness.trackedArtistRepository,
        checkTrackedArtistsUseCase: CheckTrackedArtistsUseCase(
          trackedArtistRepository: harness.trackedArtistRepository,
          trackingStateStore: TrackingStateStore(
            optionsStore: OptionsStore(localDatabase: harness.localDatabase),
          ),
          nhentaiGateway: FakeNhentaiGateway(),
          localTagCatalogService: catalog,
          blockedTagsRepository: FakeBlockedTagsRepository(),
          searchQueryBuilder: const SearchQueryBuilder(),
        ),
        localTagCatalogService: catalog,
        ticker: ForegroundTicker(
          onTick: () async {},
          interval: const Duration(days: 1),
        ),
      );
      addTearDown(model.dispose);

      await harness.trackedArtistRepository.track(1, lastSeenUploadDate: 1000);
      if (newCount > 0) {
        await harness.trackedArtistRepository.recordCheck(
          tagId: 1,
          checkedAt: DateTime.utc(2026, 9, 30),
          newCount: newCount,
        );
      }
      await model.refresh();
      return model;
    }

    /// The bell as it actually sits: inside a search bar's trailing row,
    /// beside the two buttons that are always there.
    Widget buildBar(TrackingModel model) {
      return ChangeNotifierProvider<TrackingModel>.value(
        value: model,
        child: localizedTestApp(
          home: Scaffold(
            appBar: AppBar(
              title: SearchBar(
                hintText: 'Search',
                trailing: <Widget>[
                  const TrackingBellAction(),
                  IconButton.filledTonal(
                    onPressed: () {},
                    icon: const Icon(Icons.refresh),
                  ),
                  IconButton.filledTonal(
                    onPressed: () {},
                    icon: const Icon(Icons.settings),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('is absent when nothing is new', (tester) async {
      final model = await buildModel(newCount: 0);

      await tester.pumpWidget(buildBar(model));
      await tester.pump();

      expect(find.byIcon(Icons.notifications_outlined), findsNothing);
    });

    testWidgets('appears with a count when something is', (tester) async {
      final model = await buildModel(newCount: 3);

      await tester.pumpWidget(buildBar(model));
      await tester.pump();

      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(find.text('1'), findsOneWidget, reason: 'one artist, not three');
    });

    testWidgets('leaves the search field usable at phone width', (
      tester,
    ) async {
      // A 390dp phone with three icons in the trailing row: this is exactly
      // where the reader's recommendation grid broke (P92), and the reason
      // the bell is not a permanent fourth control.
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final model = await buildModel(newCount: 3);
      await tester.pumpWidget(buildBar(model));
      await tester.pump();

      expect(tester.takeException(), isNull, reason: 'no overflow');
      final bell = tester.getRect(find.byIcon(Icons.notifications_outlined));
      expect(bell.left, greaterThanOrEqualTo(0));
      expect(bell.right, lessThanOrEqualTo(390));
    });
  });
}
