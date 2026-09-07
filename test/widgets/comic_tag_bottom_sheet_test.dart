import 'package:concept_nhv/models/comic_tag.dart';
import 'package:concept_nhv/services/tag_display_service.dart';
import 'package:concept_nhv/state/blocked_tags_model.dart';
import 'package:concept_nhv/state/home_ui_model.dart';
import 'package:concept_nhv/widgets/comic_tag_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../test_support/fakes/fake_blocked_tags_repository.dart';

/// Wraps [child] in a [MaterialApp] with required providers,
/// matching the provider tree expected by [ComicTagBottomSheet].
Widget _wrap(Widget child) {
  return MultiProvider(
    providers: [
      Provider<TagDisplayService>.value(value: TagDisplayService.fromMap({})),
      ChangeNotifierProvider<BlockedTagsModel>(
        create: (_) => BlockedTagsModel(
          blockedTagsRepository: FakeBlockedTagsRepository(),
        ),
      ),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  testWidgets('supports multi-select tag search from the bottom sheet', (tester) async {
    List<String>? selectedQueries;

    await tester.pumpWidget(
      _wrap(
        ComicTagBottomSheet(
          title: 'Sample Comic',
          initialTags: <ComicTag>[
            ComicTag(
              id: 1,
              type: 'tag',
              name: 'full color',
              url: '/tag/full-color/',
              count: 1,
            ),
            ComicTag(
              id: 2,
              type: 'language',
              name: 'chinese',
              url: '/language/chinese/',
              count: 1,
            ),
          ],
          onSearchSelected: (queries) => selectedQueries = queries,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('full color'));
    await tester.tap(find.text('chinese'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Search 2 tags'));
    await tester.pumpAndSettle();

    expect(
      selectedQueries,
      <String>['language:chinese', 'tag:full-color'],
    );
  });

  testWidgets('shows downloadSlot widget when provided', (tester) async {
    var downloadTapped = false;

    await tester.pumpWidget(
      _wrap(
        ComicTagBottomSheet(
          title: 'Sample Comic',
          initialTags: const <ComicTag>[],
          onSearchSelected: (_) {},
          downloadSlot: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => downloadTapped = true,
              icon: const Icon(Icons.download_outlined),
              label: const Text('Download'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Download'), findsOneWidget);

    await tester.tap(find.text('Download'));
    await tester.pumpAndSettle();

    expect(downloadTapped, isTrue);
  });

  testWidgets('shows download status tile via downloadSlot', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ComicTagBottomSheet(
          title: 'Sample Comic',
          initialTags: const <ComicTag>[],
          onSearchSelected: (_) {},
          downloadSlot: const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.error_outline),
            title: Text('Failed'),
            subtitle: Text('Manage in Downloads tab'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Failed'), findsOneWidget);
    expect(find.text('Manage in Downloads tab'), findsOneWidget);
  });

  testWidgets('shows actionSlot widget when provided', (tester) async {
    var actionTapped = false;

    await tester.pumpWidget(
      _wrap(
        ComicTagBottomSheet(
          title: 'Sample Comic',
          initialTags: const <ComicTag>[],
          onSearchSelected: (_) {},
          actionSlot: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => actionTapped = true,
              child: const Text('Delete Download'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Delete Download'), findsOneWidget);

    await tester.tap(find.text('Delete Download'));
    await tester.pumpAndSettle();

    expect(actionTapped, isTrue);
  });

  testWidgets('shows no extra slots when neither downloadSlot nor actionSlot is provided',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        ComicTagBottomSheet(
          title: 'Sample Comic',
          initialTags: const <ComicTag>[],
          onSearchSelected: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Download'), findsNothing);
    expect(find.text('Manage in Downloads tab'), findsNothing);
    expect(find.text('Delete Download'), findsNothing);
  });

  group('favorite count', () {
    testWidgets('shows a count handed in without loading anything', (
      tester,
    ) async {
      // A downloaded comic arrives with its tags already stored, and the sheet
      // skips loading entirely in that case — so the count has to come from
      // the caller or it never appears at all, network or no network.
      var loadMetaCalls = 0;
      await tester.pumpWidget(
        _wrap(
          ComicTagBottomSheet(
            title: 'Downloaded Comic',
            initialTags: <ComicTag>[
              ComicTag(type: 'tag', name: 'full-color', url: '/tag/full-color/'),
            ],
            comicNumFavorites: 4821,
            loadMeta: () async {
              loadMetaCalls++;
              return (
                tags: const <ComicTag>[],
                numFavorites: null,
                uploadDate: null,
              );
            },
            onSearchSelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('4.8k'), findsOneWidget);
      expect(loadMetaCalls, 0, reason: 'stored tags mean no fetch');
    });

    testWidgets('shows nothing when no count is known', (tester) async {
      // Downloads made before the column existed have none. Absent must read
      // as absent — a zero would claim the comic has no favorites at all.
      await tester.pumpWidget(
        _wrap(
          ComicTagBottomSheet(
            title: 'Old Download',
            initialTags: <ComicTag>[
              ComicTag(type: 'tag', name: 'full-color', url: '/tag/full-color/'),
            ],
            onSearchSelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite), findsNothing);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('a fetch without a count does not wipe the one we had', (
      tester,
    ) async {
      // The loader runs when there are no stored tags. If it comes back with a
      // null count, the seeded value is still the best thing we know.
      await tester.pumpWidget(
        _wrap(
          ComicTagBottomSheet(
            title: 'Comic',
            initialTags: const <ComicTag>[],
            comicNumFavorites: 1200,
            loadMeta: () async => (
              tags: <ComicTag>[
                ComicTag(type: 'tag', name: 'romance', url: '/tag/romance/'),
              ],
              numFavorites: null,
              uploadDate: null,
            ),
            onSearchSelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1.2k'), findsOneWidget);
    });

    testWidgets('a fetched count replaces the seeded one', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ComicTagBottomSheet(
            title: 'Comic',
            initialTags: const <ComicTag>[],
            comicNumFavorites: 1200,
            loadMeta: () async => (
              tags: const <ComicTag>[],
              numFavorites: 3400,
              uploadDate: null,
            ),
            onSearchSelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('3.4k'), findsOneWidget);
      expect(find.text('1.2k'), findsNothing);
    });
  });

  testWidgets('long-pressing a tag offers to search it in Downloads', (
    tester,
  ) async {
    // Pushed as a route rather than built inline, because the action pops the
    // sheet on its way out — the production path, and the only one where that
    // pop means anything.
    final homeUiModel = HomeUiModel();
    addTearDown(homeUiModel.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<TagDisplayService>.value(
            value: TagDisplayService.fromMap(const {'full-color': '全彩'}),
          ),
          ChangeNotifierProvider<BlockedTagsModel>(
            create: (_) => BlockedTagsModel(
              blockedTagsRepository: FakeBlockedTagsRepository(),
            ),
          ),
          ChangeNotifierProvider<HomeUiModel>.value(value: homeUiModel),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => ComicTagBottomSheet.show(
                  context: context,
                  title: 'Comic',
                  tags: <ComicTag>[
                    ComicTag(
                      type: 'tag',
                      name: 'full-color',
                      url: '/tag/full-color/',
                    ),
                  ],
                  onSearchSelected: (_) {},
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.longPress(find.text('全彩'));
    await tester.pumpAndSettle();

    expect(find.text('Search "全彩" in Downloads'), findsOneWidget);

    await tester.tap(find.text('Search "全彩" in Downloads'));
    await tester.pumpAndSettle();

    // The displayed label, not the tag's `type:slug` query and not its raw
    // name: the Downloads filter is a substring match, so 'tag:full-color'
    // would sit in the box matching nothing at all.
    expect(homeUiModel.downloadsSearchQuery, '全彩');
    expect(homeUiModel.navigationIndex, 1, reason: 'and it switches tabs');
    expect(find.text('Comic'), findsNothing, reason: 'the sheet closed');
  });
}
