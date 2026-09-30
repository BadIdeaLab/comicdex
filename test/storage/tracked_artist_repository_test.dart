import 'package:concept_nhv/storage/tracked_artist_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_support/storage/sqlite_test_harness.dart';

void main() {
  group('TrackedArtistRepository', () {
    late SqliteTestHarness harness;
    late TrackedArtistRepository repository;

    setUp(() async {
      harness = SqliteTestHarness();
      await harness.initialize();
      repository = harness.trackedArtistRepository;
    });

    tearDown(() async {
      await harness.dispose();
    });

    test('tracking stores the watermark it was given', () async {
      // The caller passes the artist's newest upload time, so the first check
      // reports nothing rather than announcing the whole back catalogue.
      await repository.track(20, lastSeenUploadDate: 1700);

      final rows = await repository.loadAll();
      expect(rows.single.tagId, 20);
      expect(rows.single.lastSeenUploadDate, 1700);
      expect(rows.single.newCount, 0);
      expect(await repository.isTracked(20), isTrue);
      expect(await repository.isTracked(21), isFalse);
    });

    test('re-tracking does not rewind the watermark', () async {
      // Un-tracking and re-tracking should not replay what the user has
      // already been shown.
      await repository.track(20, lastSeenUploadDate: 1700);
      await repository.markSeen(tagId: 20, uploadDate: 1900);

      await repository.track(20, lastSeenUploadDate: 1000);

      final rows = await repository.loadAll();
      expect(rows.single.lastSeenUploadDate, 1900);
    });

    test('untracking removes the row', () async {
      await repository.track(20);
      await repository.untrack(20);

      expect(await repository.loadAll(), isEmpty);
    });

    group('loadStalest', () {
      test(
        'asks about a newly added artist before a recently checked one',
        () async {
          await repository.track(20);
          await repository.track(21);
          await repository.recordCheck(
            tagId: 20,
            checkedAt: DateTime.utc(2026, 9, 30),
            newCount: 0,
          );

          final stalest = await repository.loadStalest();

          expect(
            stalest.map((row) => row.tagId),
            <int>[21, 20],
            reason: 'never checked comes before checked',
          );
        },
      );

      test('orders by how long ago, and honours the budget', () async {
        for (var tagId = 1; tagId <= 5; tagId++) {
          await repository.track(tagId);
          await repository.recordCheck(
            tagId: tagId,
            // Higher tag id, checked more recently.
            checkedAt: DateTime.utc(2026, 9, 30).add(Duration(hours: tagId)),
            newCount: 0,
          );
        }

        final stalest = await repository.loadStalest(limit: 3);

        expect(stalest.map((row) => row.tagId), <int>[1, 2, 3]);
      });
    });

    test('a check records the count without moving the watermark', () async {
      // The watermark moves when the user has seen the works, not when they
      // were found — otherwise a check the user never looked at would erase
      // the very thing it found.
      await repository.track(20, lastSeenUploadDate: 1700);

      await repository.recordCheck(
        tagId: 20,
        checkedAt: DateTime.utc(2026, 9, 30),
        newCount: 3,
      );

      final row = (await repository.loadAll()).single;
      expect(row.newCount, 3);
      expect(row.lastSeenUploadDate, 1700);
      // Compared as an instant, not as a value: drift stores a DateTime as
      // unix seconds and hands it back in local time, so the UTC one written
      // here comes out offset by the zone while naming the same moment.
      expect(
        row.lastCheckedAt!.isAtSameMomentAs(DateTime.utc(2026, 9, 30)),
        isTrue,
      );
    });

    test('marking seen moves the watermark and clears the count', () async {
      await repository.track(20, lastSeenUploadDate: 1700);
      await repository.recordCheck(
        tagId: 20,
        checkedAt: DateTime.utc(2026, 9, 30),
        newCount: 3,
      );

      await repository.markSeen(tagId: 20, uploadDate: 1900);

      final row = (await repository.loadAll()).single;
      expect(row.lastSeenUploadDate, 1900);
      expect(row.newCount, 0);
    });
  });
}
