import 'package:concept_nhv/application/tags/find_similar_comics_use_case.dart';
import 'package:concept_nhv/models/local_tag_catalog_entry.dart';
import 'package:concept_nhv/models/stored_comic.dart';
import 'package:concept_nhv/models/tag_catalog_type.dart';
import 'package:concept_nhv/services/local_tag_catalog_service.dart';
import 'package:concept_nhv/services/tag_display_service.dart';
import 'package:concept_nhv/widgets/reader/similar_comics_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../test_support/helpers/localized_test_app.dart';

void main() {
  SimilarComic entry(String id, {List<int> shared = const <int>[7]}) {
    return SimilarComic(
      comic: StoredComic(
        id: id,
        mediaId: 'm$id',
        title: 'Comic $id',
        serializedImages: '',
        pages: 20,
      ),
      similarity: 0.6,
      sharedTagIds: shared,
    );
  }

  Widget buildPage({
    required List<SimilarComic> similar,
    void Function(String comicId)? onOpen,
  }) {
    return MultiProvider(
      providers: <SingleChildWidget>[
        ChangeNotifierProvider<LocalTagCatalogService>.value(
          value: LocalTagCatalogService.fromEntries(<LocalTagCatalogEntry>[
            const LocalTagCatalogEntry(
              id: 7,
              type: TagCatalogType.artist,
              name: 'kataokasan',
              slug: 'kataokasan',
              count: 40,
            ),
          ]),
        ),
        Provider<TagDisplayService>.value(
          value: TagDisplayService.fromMap(const <String, String>{}),
        ),
      ],
      child: localizedTestApp(
        home: SimilarComicsPage(
          similar: similar,
          onOpen: onOpen ?? (_) {},
        ),
      ),
    );
  }

  testWidgets('says why each comic is here', (tester) async {
    // A row of covers with no explanation reads as a random fill; the reason
    // is the whole difference.
    await tester.pumpWidget(buildPage(similar: <SimilarComic>[entry('1')]));
    await tester.pump();

    expect(find.textContaining('kataokasan'), findsOneWidget);
  });

  testWidgets('opens the comic that was tapped', (tester) async {
    String? opened;
    await tester.pumpWidget(
      buildPage(
        similar: <SimilarComic>[entry('1'), entry('2')],
        onOpen: (id) => opened = id,
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Comic 2'));
    expect(opened, '2');
  });

  testWidgets('fits a phone without overflowing or scrolling', (tester) async {
    // 1170x2532 at 3x is 390dp wide. The analysis page shipped a header that
    // overflowed by 137 pixels at this size and swallowed the tap on its own
    // link, and none of that was visible on a tablet.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    String? opened;
    await tester.pumpWidget(
      buildPage(
        similar: <SimilarComic>[
          for (var i = 0; i < 6; i++) entry('$i'),
        ],
        onOpen: (id) => opened = id,
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Comic 0'));
    expect(opened, '0', reason: 'the first cover must stay tappable');
  });

  testWidgets('shows two when only two are similar', (tester) async {
    // Never padded to fill the grid: two strong matches beat six where four
    // are noise.
    await tester.pumpWidget(
      buildPage(similar: <SimilarComic>[entry('1'), entry('2')]),
    );
    await tester.pump();

    expect(find.textContaining('Comic '), findsNWidgets(2));
  });
}
