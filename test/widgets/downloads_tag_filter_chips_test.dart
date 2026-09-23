import 'package:concept_nhv/models/local_tag_catalog_entry.dart';
import 'package:concept_nhv/models/tag_catalog_type.dart';
import 'package:concept_nhv/services/local_tag_catalog_service.dart';
import 'package:concept_nhv/services/tag_display_service.dart';
import 'package:concept_nhv/state/home_ui_model.dart';
import 'package:concept_nhv/widgets/downloads_tag_filter_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

void main() {
  Future<HomeUiModel> pumpChips(WidgetTester tester, List<int> tagIds) async {
    final model = HomeUiModel();
    addTearDown(model.dispose);
    model.filterDownloadsByTags(tagIds);

    await tester.pumpWidget(
      MultiProvider(
        providers: <SingleChildWidget>[
          ChangeNotifierProvider<HomeUiModel>.value(value: model),
          ChangeNotifierProvider<LocalTagCatalogService>.value(
            value:
                LocalTagCatalogService.fromEntries(const <LocalTagCatalogEntry>[
                  LocalTagCatalogEntry(
                    id: 10,
                    type: TagCatalogType.tag,
                    name: 'full color',
                    slug: 'full-color',
                    count: 100,
                  ),
                  LocalTagCatalogEntry(
                    id: 11,
                    type: TagCatalogType.tag,
                    name: 'schoolgirl',
                    slug: 'schoolgirl',
                    count: 100,
                  ),
                ]),
          ),
          Provider<TagDisplayService>.value(
            value: TagDisplayService.fromMap(const <String, String>{
              'full-color': '全彩',
            }),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: DownloadsTagFilterChips()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return model;
  }

  testWidgets('shows a chip per filter, using the localized name', (
    tester,
  ) async {
    await pumpChips(tester, <int>[10, 11]);

    expect(find.text('全彩'), findsOneWidget);
    expect(find.text('schoolgirl'), findsOneWidget);
  });

  testWidgets('deleting a chip drops that filter only', (tester) async {
    final model = await pumpChips(tester, <int>[10, 11]);

    await tester.tap(find.byIcon(Icons.clear).first);
    await tester.pumpAndSettle();

    expect(model.downloadsTagIds, <int>[11]);
  });

  testWidgets('clear removes them all, and only shows with more than one', (
    tester,
  ) async {
    final model = await pumpChips(tester, <int>[10, 11]);

    await tester.tap(find.text('Clear tags'));
    await tester.pumpAndSettle();

    expect(model.downloadsTagIds, isEmpty);
    expect(find.byType(InputChip), findsNothing);
  });

  testWidgets('an id the catalog cannot resolve still identifies itself', (
    tester,
  ) async {
    await pumpChips(tester, <int>[999]);

    expect(find.text('Tag #999'), findsOneWidget);
  });
}
