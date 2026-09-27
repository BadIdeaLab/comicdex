import 'package:concept_nhv/application/downloads/download_item_filter.dart';
import 'package:concept_nhv/models/comic_tag.dart';
import 'package:concept_nhv/models/download_job_status.dart';
import 'package:concept_nhv/models/download_list_item_snapshot.dart';
import 'package:concept_nhv/services/tag_display_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tagDisplayService = TagDisplayService.fromMap(const <String, String>{
    'full-color': '全彩',
  });

  DownloadListItemSnapshot item(
    String comicId, {
    String title = 'title',
    DownloadJobStatus status = DownloadJobStatus.completed,
    List<ComicTag> tags = const <ComicTag>[],
  }) {
    final now = DateTime.utc(2026);
    return DownloadListItemSnapshot(
      comicId: comicId,
      mediaId: 'm$comicId',
      title: title,
      status: status,
      totalPages: 10,
      completedPages: 10,
      nextPageNumber: 11,
      requestedAt: now,
      updatedAt: now,
      retryCount: 0,
      tags: tags,
    );
  }

  ComicTag fullColor() =>
      ComicTag(id: 1, type: 'tag', name: 'full color', url: '/tag/full-color/');

  List<String> idsOf(List<DownloadListItemSnapshot> items) =>
      items.map((item) => item.comicId).toList();

  group('filterDownloadItems', () {
    test('keeps everything when nothing is asked for', () {
      final items = <DownloadListItemSnapshot>[item('a'), item('b')];

      expect(
        idsOf(filterDownloadItems(items, tagDisplayService: tagDisplayService)),
        <String>['a', 'b'],
      );
    });

    test('matches the title case-insensitively', () {
      final items = <DownloadListItemSnapshot>[
        item('hit', title: 'The Blue Sky'),
        item('miss', title: 'Something else'),
      ];

      expect(
        idsOf(
          filterDownloadItems(
            items,
            query: 'BLUE',
            tagDisplayService: tagDisplayService,
          ),
        ),
        <String>['hit'],
      );
    });

    test('matches the translated tag name, not only the stored one', () {
      // Tags are stored in English; a reader searching in Chinese should
      // still find them.
      final items = <DownloadListItemSnapshot>[
        item('hit', tags: <ComicTag>[fullColor()]),
        item('miss'),
      ];

      expect(
        idsOf(
          filterDownloadItems(
            items,
            query: '全彩',
            tagDisplayService: tagDisplayService,
          ),
        ),
        <String>['hit'],
      );
    });

    test('requires every tag id, not any of them', () {
      final other = ComicTag(id: 2, type: 'tag', name: 'glasses');
      final items = <DownloadListItemSnapshot>[
        item('both', tags: <ComicTag>[fullColor(), other]),
        item('one', tags: <ComicTag>[fullColor()]),
      ];

      expect(
        idsOf(
          filterDownloadItems(
            items,
            tagIds: const <int>[1, 2],
            tagDisplayService: tagDisplayService,
          ),
        ),
        <String>['both'],
      );
    });

    test('a running download cannot survive a tag filter', () {
      // It has no tags yet, deliberately: there is nothing to match on.
      final items = <DownloadListItemSnapshot>[
        item('running', status: DownloadJobStatus.downloading),
      ];

      expect(
        filterDownloadItems(
          items,
          tagIds: const <int>[1],
          tagDisplayService: tagDisplayService,
        ),
        isEmpty,
      );
    });

    test('a query of only spaces is not a filter', () {
      final items = <DownloadListItemSnapshot>[item('a')];

      expect(
        idsOf(
          filterDownloadItems(
            items,
            query: '   ',
            tagDisplayService: tagDisplayService,
          ),
        ),
        <String>['a'],
      );
    });
  });
}
