import 'package:concept_nhv/application/downloads/download_list_sorter.dart';
import 'package:concept_nhv/application/tags/tag_preference_vector.dart';
import 'package:concept_nhv/models/comic_tag.dart';
import 'package:concept_nhv/models/download_job_status.dart';
import 'package:concept_nhv/models/download_list_item_snapshot.dart';
import 'package:concept_nhv/models/downloads_sort_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// A timestamp [minutes] after a fixed epoch, so the ordering a test sets
  /// up is readable as small numbers.
  DateTime at(int minutes) =>
      DateTime.utc(2026).add(Duration(minutes: minutes));

  DownloadListItemSnapshot item(
    String comicId, {
    DownloadJobStatus status = DownloadJobStatus.completed,
    String title = 'title',
    int requestedAt = 0,
    int updatedAt = 0,
    int? downloadedAt,
    int? lastReadAt,
    int? numFavorites,
    List<ComicTag> tags = const <ComicTag>[],
  }) {
    return DownloadListItemSnapshot(
      comicId: comicId,
      mediaId: 'm$comicId',
      title: title,
      status: status,
      totalPages: 10,
      completedPages: 10,
      nextPageNumber: 11,
      requestedAt: at(requestedAt),
      updatedAt: at(updatedAt),
      retryCount: 0,
      downloadedAt: downloadedAt == null ? null : at(downloadedAt),
      lastReadAt: lastReadAt == null ? null : at(lastReadAt),
      numFavorites: numFavorites,
      tags: tags,
    );
  }

  DownloadListSorter sorter({
    DownloadsSortMode mode = DownloadsSortMode.latestDownloaded,
    DownloadsSortDirection direction = DownloadsSortDirection.descending,
    TagPreferenceVector preferences = const TagPreferenceVector.empty(),
  }) {
    return DownloadListSorter(
      mode: mode,
      direction: direction,
      preferences: preferences,
    );
  }

  List<String> idsOf(List<DownloadListItemSnapshot> items) =>
      items.map((item) => item.comicId).toList();

  group('DownloadListSorter.sort', () {
    test('active jobs come before the library, whatever the mode', () {
      // Burying a running download under an alphabetical list would hide the
      // thing that is actually happening.
      final ordered = sorter(mode: DownloadsSortMode.title).sort(
        <DownloadListItemSnapshot>[
          item('done', title: 'aaa'),
          item('running', status: DownloadJobStatus.downloading, title: 'zzz'),
        ],
      );

      expect(idsOf(ordered), <String>['running', 'done']);
    });

    test('active jobs sort by status, then newest request first', () {
      final ordered = sorter().sort(<DownloadListItemSnapshot>[
        item('paused', status: DownloadJobStatus.paused),
        item('old-queued', status: DownloadJobStatus.queued, requestedAt: 1),
        item('new-queued', status: DownloadJobStatus.queued, requestedAt: 2),
        item('failed', status: DownloadJobStatus.failed),
        item('downloading', status: DownloadJobStatus.downloading),
      ]);

      expect(idsOf(ordered), <String>[
        'downloading',
        'new-queued',
        'old-queued',
        'failed',
        'paused',
      ]);
    });

    test('the returned list cannot be modified', () {
      final ordered = sorter().sort(<DownloadListItemSnapshot>[item('a')]);

      expect(() => ordered.add(item('b')), throwsUnsupportedError);
    });
  });

  group('DownloadListSorter.compareCompleted', () {
    test('latestDownloaded falls back to updatedAt', () {
      final ordered = sorter().sort(<DownloadListItemSnapshot>[
        item('no-timestamp', updatedAt: 30),
        item('downloaded', downloadedAt: 20, updatedAt: 1),
      ]);

      expect(idsOf(ordered), <String>['no-timestamp', 'downloaded']);
    });

    test('lastRead prefers lastReadAt, then downloadedAt, then updatedAt', () {
      final ordered = sorter(mode: DownloadsSortMode.lastRead)
          .sort(<DownloadListItemSnapshot>[
            item('only-updated', updatedAt: 5),
            item('read', downloadedAt: 1, lastReadAt: 30),
            item('only-downloaded', downloadedAt: 10),
          ]);

      expect(idsOf(ordered), <String>[
        'read',
        'only-downloaded',
        'only-updated',
      ]);
    });

    test(
      'mostFavorited pushes unknown counts to the end of either direction',
      () {
        // Ascending must not let "no data" masquerade as the least favourited.
        for (final direction in DownloadsSortDirection.values) {
          final ordered =
              sorter(
                mode: DownloadsSortMode.mostFavorited,
                direction: direction,
              ).sort(<DownloadListItemSnapshot>[
                item('unknown'),
                item('few', numFavorites: 5),
                item('many', numFavorites: 500),
              ]);

          expect(idsOf(ordered).last, 'unknown', reason: '$direction');
        }
      },
    );

    test('author falls back from artist to group, and to the title', () {
      ComicTag tag(String type, String name) =>
          ComicTag(type: type, name: name);

      final ordered =
          sorter(
            mode: DownloadsSortMode.author,
            direction: DownloadsSortDirection.ascending,
          ).sort(<DownloadListItemSnapshot>[
            item('no-author', title: 'aaa'),
            item('group-only', tags: <ComicTag>[tag('group', 'circle b')]),
            item(
              'artist',
              // Both present: the artist wins, which the ordering shows.
              tags: <ComicTag>[tag('group', 'zzz'), tag('artist', 'artist a')],
            ),
          ]);

      expect(idsOf(ordered), <String>['artist', 'group-only', 'no-author']);
    });

    test('an empty artist name does not count as an author', () {
      final ordered =
          sorter(
            mode: DownloadsSortMode.author,
            direction: DownloadsSortDirection.ascending,
          ).sort(<DownloadListItemSnapshot>[
            item(
              'blank-artist',
              title: 'zzz',
              tags: <ComicTag>[ComicTag(type: 'artist', name: '')],
            ),
            item(
              'named',
              tags: <ComicTag>[ComicTag(type: 'artist', name: 'a')],
            ),
          ]);

      expect(idsOf(ordered), <String>['named', 'blank-artist']);
    });

    test('preference scores by tag, and breaks ties by recency', () {
      const preferences = TagPreferenceVector(
        weights: <int, double>{7: 1.0},
        goldThreshold: 0.4,
        platinumThreshold: 0.55,
      );

      final ordered =
          sorter(
            mode: DownloadsSortMode.preference,
            preferences: preferences,
          ).sort(<DownloadListItemSnapshot>[
            item('older-unscored', downloadedAt: 1),
            item('newer-unscored', downloadedAt: 2),
            item('liked', downloadedAt: 0, tags: <ComicTag>[ComicTag(id: 7)]),
          ]);

      expect(idsOf(ordered), <String>[
        'liked',
        'newer-unscored',
        'older-unscored',
      ]);
    });

    test('sorts with no preference data at all', () {
      // The vector arrives in the background; the list must still sort before
      // it does, by everything except preference.
      final ordered = sorter(mode: DownloadsSortMode.preference).sort(
        <DownloadListItemSnapshot>[
          item('older', downloadedAt: 1),
          item('newer', downloadedAt: 2),
        ],
      );

      expect(idsOf(ordered), <String>['newer', 'older']);
    });
  });

  group('DownloadListSorter.authorName', () {
    test('is null when neither an artist nor a group tag is present', () {
      expect(
        DownloadListSorter.authorName(
          item(
            'x',
            tags: <ComicTag>[ComicTag(type: 'tag', name: 'glasses')],
          ),
        ),
        isNull,
      );
    });
  });
}
