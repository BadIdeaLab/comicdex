import 'package:concept_nhv/application/tracking/check_tracked_artists_use_case.dart';
import 'package:concept_nhv/application/tracking/tracking_cooldown.dart';
import 'package:concept_nhv/models/comic.dart';
import 'package:concept_nhv/models/comic_search_response.dart';
import 'package:concept_nhv/models/local_tag_catalog_entry.dart';
import 'package:concept_nhv/models/tag_catalog_type.dart';
import 'package:concept_nhv/services/local_tag_catalog_service.dart';
import 'package:concept_nhv/services/search_query_builder.dart';
import 'package:concept_nhv/storage/options_store.dart';
import 'package:concept_nhv/storage/tracked_artist_repository.dart';
import 'package:concept_nhv/storage/tracking_state_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_support/fakes/fake_blocked_tags_repository.dart';
import '../../test_support/fakes/fake_nhentai_gateway.dart';
import '../../test_support/fixtures/sample_comic.dart';
import '../../test_support/storage/sqlite_test_harness.dart';

/// Answers every search with [response], or throws [error] instead.
class _SearchGateway extends FakeNhentaiGateway {
  _SearchGateway({this.response, this.error});

  final ComicSearchResponse? response;
  final DioException? error;
  int searchCount = 0;

  @override
  Future<ComicSearchResponse> searchComics(Uri uri) async {
    searchCount += 1;
    searchedUris.add(uri);
    if (error != null) throw error!;
    return response ?? ComicSearchResponse(result: const <Comic>[]);
  }
}

DioException rateLimited({String? retryAfter}) {
  return DioException(
    requestOptions: RequestOptions(path: '/'),
    response: Response<dynamic>(
      requestOptions: RequestOptions(path: '/'),
      statusCode: 429,
      headers: retryAfter == null
          ? null
          : Headers.fromMap(<String, List<String>>{
              'retry-after': <String>[retryAfter],
            }),
    ),
  );
}

void main() {
  group('CheckTrackedArtistsUseCase', () {
    late SqliteTestHarness harness;
    late TrackedArtistRepository artists;
    late TrackingStateStore state;

    final catalog = LocalTagCatalogService.fromEntries(<LocalTagCatalogEntry>[
      for (var id = 1; id <= 30; id++)
        LocalTagCatalogEntry(
          id: id,
          type: TagCatalogType.artist,
          name: 'artist$id',
          slug: 'artist$id',
          count: 40,
        ),
    ]);

    var clock = DateTime.utc(2026, 9, 30, 12);

    setUp(() async {
      harness = SqliteTestHarness();
      await harness.initialize();
      artists = harness.trackedArtistRepository;
      state = TrackingStateStore(
        optionsStore: OptionsStore(localDatabase: harness.localDatabase),
      );
      clock = DateTime.utc(2026, 9, 30, 12);
    });

    tearDown(() async {
      await harness.dispose();
    });

    CheckTrackedArtistsUseCase buildUseCase(_SearchGateway gateway) {
      return CheckTrackedArtistsUseCase(
        trackedArtistRepository: artists,
        trackingStateStore: state,
        nhentaiGateway: gateway,
        localTagCatalogService: catalog,
        blockedTagsRepository: FakeBlockedTagsRepository(),
        searchQueryBuilder: const SearchQueryBuilder(),
        now: () => clock,
        batchSleep: (_) async {},
      );
    }

    ComicSearchResponse withUploadDates(List<int> uploadDates) {
      return ComicSearchResponse(
        result: <Comic>[
          for (final (index, uploadDate) in uploadDates.indexed)
            sampleComic(id: 'c$index').copyWith(uploadDate: uploadDate),
        ],
      );
    }

    test(
      'sends at most one request per tracked artist, up to the budget',
      () async {
        // The whole traffic guarantee: tracking more artists must not mean more
        // requests at once, only more runs.
        for (var id = 1; id <= kTrackedArtistsPerRun + 5; id++) {
          await artists.track(id, lastSeenUploadDate: 1000);
        }
        final gateway = _SearchGateway();

        final result = await buildUseCase(gateway).execute();

        expect(gateway.searchCount, kTrackedArtistsPerRun);
        expect(result.checkedCount, kTrackedArtistsPerRun);
      },
    );

    test('the next run picks up where the last one stopped', () async {
      for (var id = 1; id <= kTrackedArtistsPerRun + 2; id++) {
        await artists.track(id, lastSeenUploadDate: 1000);
      }
      final first = _SearchGateway();
      await buildUseCase(first).execute();

      clock = clock.add(kTrackingRunInterval);
      final second = _SearchGateway();
      await buildUseCase(second).execute();

      // The second run takes the two the first never reached (they have no
      // check time at all) and then the eight oldest of the rest, leaving 9
      // and 10 as the ones whose turn comes next.
      final checkedInSecondRun = await artists.loadAll();
      for (final tagId in <int>[11, 12]) {
        expect(
          checkedInSecondRun
              .firstWhere((row) => row.tagId == tagId)
              .lastCheckedAt,
          isNotNull,
          reason: 'artist $tagId waited a whole run and must not wait another',
        );
      }
      expect(
        (await artists.loadStalest(limit: 2)).map((row) => row.tagId),
        <int>[9, 10],
      );
      expect(second.searchCount, kTrackedArtistsPerRun);
    });

    test('a run inside the interval does not start', () async {
      await artists.track(1, lastSeenUploadDate: 1000);
      await buildUseCase(_SearchGateway()).execute();

      clock = clock.add(const Duration(hours: 1));
      final gateway = _SearchGateway();
      final result = await buildUseCase(gateway).execute();

      expect(gateway.searchCount, 0);
      expect(result.skipped, isTrue);
    });

    test('pulling to refresh overrules our own interval', () async {
      await artists.track(1, lastSeenUploadDate: 1000);
      await buildUseCase(_SearchGateway()).execute();

      clock = clock.add(const Duration(minutes: 1));
      final gateway = _SearchGateway();
      await buildUseCase(gateway).execute(manual: true);

      expect(gateway.searchCount, 1);
    });

    group('when the site says to slow down', () {
      test('the rate-limited request is the last one the run sends', () async {
        for (var id = 1; id <= 5; id++) {
          await artists.track(id, lastSeenUploadDate: 1000);
        }
        final gateway = _SearchGateway(error: rateLimited());

        final result = await buildUseCase(gateway).execute();

        expect(gateway.searchCount, 1, reason: 'stopped, not retried');
        expect(result.rateLimited, isTrue);
      });

      test('nothing is sent again until it lifts, manual or not', () async {
        // The one rule the user cannot overrule: the site did not ask them.
        await artists.track(1, lastSeenUploadDate: 1000);
        await buildUseCase(_SearchGateway(error: rateLimited())).execute();

        clock = clock.add(
          kDefaultRateLimitCooldown - const Duration(minutes: 1),
        );
        final blockedRun = _SearchGateway();
        expect(
          (await buildUseCase(blockedRun).execute(manual: true)).skipped,
          isTrue,
        );
        expect(blockedRun.searchCount, 0);

        clock = clock.add(const Duration(minutes: 2));
        final allowed = _SearchGateway();
        await buildUseCase(allowed).execute(manual: true);
        expect(allowed.searchCount, 1);
      });

      test('a Retry-After is honoured over the default', () async {
        await artists.track(1, lastSeenUploadDate: 1000);
        await buildUseCase(
          _SearchGateway(error: rateLimited(retryAfter: '60')),
        ).execute();

        clock = clock.add(const Duration(minutes: 5));
        final gateway = _SearchGateway();
        await buildUseCase(gateway).execute(manual: true);

        expect(gateway.searchCount, 1);
      });
    });

    group('counting new work', () {
      test('counts only what is past the watermark', () async {
        await artists.track(1, lastSeenUploadDate: 1500);
        final gateway = _SearchGateway(
          response: withUploadDates(<int>[2000, 1800, 1500, 1200]),
        );

        final result = await buildUseCase(gateway).execute();

        expect(result.artistsWithNewWork, 1);
        final row = (await artists.loadAll()).single;
        expect(row.newCount, 2, reason: 'equal to the watermark is not new');
        expect(row.lastSeenUploadDate, 1500, reason: 'not moved by a check');
      });

      test(
        'a freshly tracked artist with no watermark reports nothing',
        () async {
          // Otherwise pressing "track" announces the entire back catalogue.
          await artists.track(1);
          final gateway = _SearchGateway(
            response: withUploadDates(<int>[2000, 1800]),
          );

          final result = await buildUseCase(gateway).execute();

          expect(result.artistsWithNewWork, 0);
          expect((await artists.loadAll()).single.newCount, 0);
        },
      );

      test(
        'the first check seeds the watermark, the second can report',
        () async {
          // Tracking carries no watermark, so the first check is what decides
          // where "new" begins. Without this the artist would report nothing
          // for ever, which looks exactly like tracking that does not work.
          await artists.track(1);
          await buildUseCase(
            _SearchGateway(response: withUploadDates(<int>[1800, 1500])),
          ).execute();

          expect((await artists.loadAll()).single.lastSeenUploadDate, 1800);

          clock = clock.add(kTrackingRunInterval);
          final result = await buildUseCase(
            _SearchGateway(response: withUploadDates(<int>[2500, 1800])),
          ).execute();

          expect(result.artistsWithNewWork, 1);
          expect((await artists.loadAll()).single.newCount, 1);
        },
      );

      test('a seeded watermark is not rewritten by a later check', () async {
        await artists.track(1);
        await buildUseCase(
          _SearchGateway(response: withUploadDates(<int>[1800])),
        ).execute();

        clock = clock.add(kTrackingRunInterval);
        await buildUseCase(
          // The site returned an older page this time, for whatever reason.
          _SearchGateway(response: withUploadDates(<int>[900])),
        ).execute();

        expect((await artists.loadAll()).single.lastSeenUploadDate, 1800);
      });

      test('an artist the catalog cannot name is not asked about', () async {
        // No slug means no query to send. It must still be marked checked, or
        // it sits at the front of every future run for ever.
        await artists.track(9999, lastSeenUploadDate: 1000);
        final gateway = _SearchGateway();

        await buildUseCase(gateway).execute();

        expect(gateway.searchCount, 0);
        expect((await artists.loadAll()).single.lastCheckedAt, isNotNull);
      });
    });

    test('nothing tracked leaves the cooldown untouched', () async {
      // An empty run is not a reason to make the next one wait.
      final result = await buildUseCase(_SearchGateway()).execute();

      expect(result.skipped, isTrue);
      expect((await state.load()).nextRunAt, isNull);
    });
  });

  group('countNewerThan', () {
    test('does not assume the results are newest-first', () async {
      // The site's default ordering appears to be recency, but this build
      // could not reach the site to confirm it. Comparing every entry means
      // the answer does not depend on being right about that.
      final comics = <Comic>[
        sampleComic(id: 'a').copyWith(uploadDate: 1200),
        sampleComic(id: 'b').copyWith(uploadDate: 2000),
        sampleComic(id: 'c').copyWith(uploadDate: 1800),
      ];

      expect(countNewerThan(comics, watermark: 1500), 2);
    });

    test('ignores entries with no upload date at all', () {
      final comics = <Comic>[
        sampleComic(id: 'a').copyWith(uploadDate: null),
        sampleComic(id: 'b').copyWith(uploadDate: 2000),
      ];

      expect(countNewerThan(comics, watermark: 1500), 1);
    });
  });

  group('newestUploadDate', () {
    test('is the newest whatever the order', () {
      final comics = <Comic>[
        sampleComic(id: 'a').copyWith(uploadDate: 1200),
        sampleComic(id: 'b').copyWith(uploadDate: 2000),
      ];

      expect(newestUploadDate(comics), 2000);
    });

    test('is null when nothing carries one', () {
      expect(newestUploadDate(const <Comic>[]), isNull);
    });
  });
}
