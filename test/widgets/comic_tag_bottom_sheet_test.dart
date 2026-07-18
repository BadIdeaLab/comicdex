import 'package:concept_nhv/models/comic_tag.dart';
import 'package:concept_nhv/services/tag_display_service.dart';
import 'package:concept_nhv/state/blocked_tags_model.dart';
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
}
