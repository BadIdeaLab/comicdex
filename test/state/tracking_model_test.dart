import 'package:concept_nhv/application/tracking/check_tracked_artists_use_case.dart';
import 'package:concept_nhv/application/tracking/foreground_ticker.dart';
import 'package:concept_nhv/models/comic.dart';
import 'package:concept_nhv/models/comic_search_response.dart';
import 'package:concept_nhv/models/local_tag_catalog_entry.dart';
import 'package:concept_nhv/models/tag_catalog_type.dart';
import 'package:concept_nhv/services/local_tag_catalog_service.dart';
import 'package:concept_nhv/services/search_query_builder.dart';
import 'package:concept_nhv/state/tracking_model.dart';
import 'package:concept_nhv/storage/options_store.dart';
import 'package:concept_nhv/storage/tracking_state_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_support/fakes/fake_blocked_tags_repository.dart';
import '../test_support/fakes/fake_nhentai_gateway.dart';
import '../test_support/fixtures/sample_comic.dart';
import '../test_support/storage/sqlite_test_harness.dart';

class _SearchGateway extends FakeNhentaiGateway {
  _SearchGateway({this.uploadDates = const <int>[]});

  final List<int> uploadDates;
  int searchCount = 0;

  @override
  Future<ComicSearchResponse> searchComics(Uri uri) async {
    searchCount += 1;
    return ComicSearchResponse(
      result: <Comic>[
        for (final (index, uploadDate) in uploadDates.indexed)
          sampleComic(id: 'c$index').copyWith(uploadDate: uploadDate),
      ],
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TrackingModel', () {
    late SqliteTestHarness harness;
    var clock = DateTime.utc(2026, 9, 30, 12);

    final catalog = LocalTagCatalogService.fromEntries(<LocalTagCatalogEntry>[
      for (var id = 1; id <= 3; id++)
        LocalTagCatalogEntry(
          id: id,
          type: TagCatalogType.artist,
          name: 'artist$id',
          slug: 'artist$id',
          count: 40,
        ),
    ]);

    setUp(() async {
      harness = SqliteTestHarness();
      await harness.initialize();
      clock = DateTime.utc(2026, 9, 30, 12);
    });

    tearDown(() async {
      await harness.dispose();
    });

    TrackingModel buildModel(_SearchGateway gateway) {
      final model = TrackingModel(
        trackedArtistRepository: harness.trackedArtistRepository,
        checkTrackedArtistsUseCase: CheckTrackedArtistsUseCase(
          trackedArtistRepository: harness.trackedArtistRepository,
          trackingStateStore: TrackingStateStore(
            optionsStore: OptionsStore(localDatabase: harness.localDatabase),
          ),
          nhentaiGateway: gateway,
          localTagCatalogService: catalog,
          blockedTagsRepository: FakeBlockedTagsRepository(),
          searchQueryBuilder: const SearchQueryBuilder(),
          now: () => clock,
          batchSleep: (_) async {},
        ),
        localTagCatalogService: catalog,
        now: () => clock,
        // Started explicitly by initialize(), and a real one would leave a
        // pending timer behind every test.
        ticker: ForegroundTicker(
          onTick: () async {},
          interval: const Duration(days: 1),
        ),
      );
      addTearDown(model.dispose);
      return model;
    }

    test('tracking starts with no watermark', () async {
      // Pressing track must not be a request that can fail, so where "new"
      // begins is decided by the first check instead.
      final model = buildModel(_SearchGateway());

      await model.track(1);

      expect(model.isTracked(1), isTrue);
      expect(model.artists.single.artist.lastSeenUploadDate, isNull);
      expect(model.artistsWithNewWork, 0);
    });

    test('untracking removes it from the list', () async {
      final model = buildModel(_SearchGateway());
      await model.track(1);

      await model.untrack(1);

      expect(model.artists, isEmpty);
      expect(model.isTracked(1), isFalse);
    });

    test('artists with new work sort to the top', () async {
      // The list is what the tracking page shows, and what the user is there
      // for is at the top of it.
      final model = buildModel(_SearchGateway(uploadDates: <int>[2000]));
      await model.track(1);
      await model.track(2);
      await harness.trackedArtistRepository.seedWatermark(
        tagId: 2,
        uploadDate: 1000,
      );

      await model.check();

      expect(model.artists.first.tagId, 2);
      expect(model.artistsWithNewWork, 1);
    });

    test('the count is artists, not works', () async {
      // The bell says how many artists have something, because that is what
      // tapping it leads to a list of.
      final model = buildModel(_SearchGateway(uploadDates: <int>[3000, 2500]));
      await model.track(1);
      await harness.trackedArtistRepository.seedWatermark(
        tagId: 1,
        uploadDate: 1000,
      );

      await model.check();

      expect(model.artists.single.newCount, 2);
      expect(model.artistsWithNewWork, 1);
    });

    test('marking seen clears it', () async {
      final model = buildModel(_SearchGateway(uploadDates: <int>[2000]));
      await model.track(1);
      await harness.trackedArtistRepository.seedWatermark(
        tagId: 1,
        uploadDate: 1000,
      );
      await model.check();
      expect(model.artistsWithNewWork, 1);

      await model.markSeen(1);

      expect(model.artistsWithNewWork, 0);
    });

    test('a second check while one is running is dropped', () async {
      // Not a rule about the site — the cooldown owns that. This only stops
      // the model from running two of its own checks at once, which would
      // interleave two refreshes over the same rows.
      final gateway = _SearchGateway();
      final model = buildModel(gateway);
      await model.track(1);

      await Future.wait(<Future<void>>[model.check(), model.check()]);

      expect(gateway.searchCount, 1);
    });

    test('an artist the catalog cannot name still appears', () async {
      // Otherwise a renamed tag becomes a row that cannot be seen and
      // therefore cannot be un-tracked.
      final model = buildModel(_SearchGateway());

      await model.track(9999);

      expect(model.artists.single.catalogEntry, isNull);
      expect(model.artists.single.tagId, 9999);
    });
  });
}
