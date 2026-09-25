import 'package:concept_nhv/models/local_tag_catalog_entry.dart';
import 'package:concept_nhv/models/tag_catalog_type.dart';
import 'package:concept_nhv/models/tag_preference_entry.dart';
import 'package:concept_nhv/services/tag_display_service.dart';
import 'package:concept_nhv/widgets/tag_preference_sliver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_support/helpers/localized_test_app.dart';
import 'package:provider/provider.dart';

void main() {
  TagPreferenceEntry entry(String slug, int count) => TagPreferenceEntry(
    tag: LocalTagCatalogEntry(
      id: slug.hashCode,
      type: TagCatalogType.tag,
      name: slug,
      slug: slug,
      count: 1000,
    ),
    comicCount: count,
    favoriteCount: count,
    downloadedCount: count,
    affinity: count / 1000,
  );

  Future<void> pump(
    WidgetTester tester, {
    required Map<TagCatalogType, List<TagPreferenceEntry>> preferences,
    void Function(LocalTagCatalogEntry tag, String displayName)? onTagTap,
    void Function(LocalTagCatalogEntry tag, String displayName)? onLongPress,
    ValueChanged<TagPreferenceSort>? onSortChanged,
    VoidCallback? onOpenFullAnalysis,
  }) {
    return tester.pumpWidget(
      Provider<TagDisplayService>.value(
        value: TagDisplayService.fromMap(const <String, String>{
          'tag-1': '標籤一',
        }),
        child: localizedTestApp(
          home: CustomScrollView(
            slivers: <Widget>[
              TagPreferenceSliver(
                preferences: preferences,
                sort: TagPreferenceSort.count,
                onSortChanged: onSortChanged ?? (_) {},
                onTagTap: onTagTap ?? (_, _) {},
                onTagLongPress: onLongPress ?? (_, _) {},
                onOpenFullAnalysis: onOpenFullAnalysis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('shows the localized tag name and its comic count', (
    tester,
  ) async {
    await pump(
      tester,
      preferences: <TagCatalogType, List<TagPreferenceEntry>>{
        TagCatalogType.tag: <TagPreferenceEntry>[entry('tag-1', 42)],
      },
    );

    expect(find.text('標籤一'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
  });

  testWidgets('collapses long sections behind Show more', (tester) async {
    await pump(
      tester,
      preferences: <TagCatalogType, List<TagPreferenceEntry>>{
        TagCatalogType.tag: <TagPreferenceEntry>[
          for (var i = 0; i < 12; i++) entry('tag-$i', 12 - i),
        ],
      },
    );

    expect(find.text('tag-9'), findsOneWidget);
    expect(find.text('tag-10'), findsNothing);

    await tester.tap(find.text('Show 2 more'));
    await tester.pumpAndSettle();

    // The list builds lazily, so the newly revealed tail is off-screen until
    // scrolled to — that laziness is what keeps the uncapped analysis page
    // from building every tag at once.
    await tester.scrollUntilVisible(find.text('Show less'), 200);
    await tester.pumpAndSettle();

    expect(find.text('tag-11'), findsOneWidget);
    expect(find.text('Show less'), findsOneWidget);
  });

  testWidgets('reports taps, long presses and sort changes', (tester) async {
    String? tapped;
    String? longPressed;
    TagPreferenceSort? requestedSort;
    await pump(
      tester,
      preferences: <TagCatalogType, List<TagPreferenceEntry>>{
        TagCatalogType.tag: <TagPreferenceEntry>[entry('tag-1', 5)],
      },
      onTagTap: (tag, displayName) => tapped = '${tag.query}|$displayName',
      onLongPress: (tag, displayName) => longPressed = tag.query,
      onSortChanged: (sort) => requestedSort = sort,
    );

    await tester.tap(find.text('標籤一'));
    await tester.longPress(find.text('標籤一'));
    await tester.tap(find.text('Most distinctive'));
    await tester.pumpAndSettle();

    // The display name is what the Downloads filter matches on (P75).
    expect(tapped, 'tag:tag-1|標籤一');
    expect(longPressed, 'tag:tag-1');
    expect(requestedSort, TagPreferenceSort.affinity);
  });

  testWidgets('shows an empty state when nothing ranks yet', (tester) async {
    await pump(
      tester,
      preferences: <TagCatalogType, List<TagPreferenceEntry>>{
        TagCatalogType.tag: const <TagPreferenceEntry>[],
      },
    );

    expect(find.textContaining('No tag data yet'), findsOneWidget);
  });

  testWidgets('the header fits a phone and its action stays tappable', (
    tester,
  ) async {
    // A phone, not the tablet-sized default test surface: the single-row
    // header overflowed here, drew the sort toggle over the title and the
    // "Full analysis" link, and swallowed that link's taps.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    var opened = 0;
    await pump(
      tester,
      preferences: <TagCatalogType, List<TagPreferenceEntry>>{
        TagCatalogType.tag: <TagPreferenceEntry>[entry('tag-1', 42)],
      },
      onOpenFullAnalysis: () => opened++,
    );

    expect(find.text('Tag Preferences'), findsOneWidget);
    expect(find.text('Most kept'), findsOneWidget);

    await tester.tap(find.text('Full analysis ›'));
    await tester.pumpAndSettle();

    expect(opened, 1);
  });
}
