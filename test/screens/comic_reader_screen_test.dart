import 'package:concept_nhv/models/comic.dart';
import 'package:concept_nhv/models/comic_tag.dart';
import 'package:concept_nhv/models/local_tag_catalog_entry.dart';
import 'package:concept_nhv/models/tag_catalog_type.dart';
import 'package:concept_nhv/widgets/reader/similar_comics_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_support/fixtures/sample_comic.dart';
import '../test_support/helpers/reader_test_harness.dart';

void main() {
  const artist = 20;
  const other = 21;

  final catalog = <LocalTagCatalogEntry>[
    const LocalTagCatalogEntry(
      id: artist,
      type: TagCatalogType.artist,
      name: 'artist',
      slug: 'artist',
      count: 40,
    ),
    const LocalTagCatalogEntry(
      id: other,
      type: TagCatalogType.tag,
      name: 'glasses',
      slug: 'glasses',
      count: 8000,
    ),
  ];

  group('ComicReaderScreen', () {
    late ReaderTestHarness harness;

    setUp(() async {
      harness = ReaderTestHarness();
      await harness.initialize();
    });

    tearDown(() async {
      await harness.dispose();
    });

    /// [sampleComic] carries two page images and one tag of its own, so both
    /// are cleared here and set explicitly — a comic whose `numPages` and
    /// `images.pages` disagree would index past the end of the list.
    Comic comicWith({List<int> tagIds = const <int>[]}) {
      return sampleComic(
        id: 'source',
        mediaId: '500',
      ).copyWith(tags: const <ComicTag>[], tagIds: tagIds);
    }

    /// Mounts the reader and lets its two async loads settle.
    Future<void> open(WidgetTester tester, Comic comic) async {
      await tester.pumpWidget(harness.buildApp(comic: comic, catalog: catalog));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    PageView pageViewOf(WidgetTester tester) =>
        tester.widget<PageView>(find.byType(PageView));

    int pageCountOf(WidgetTester tester) =>
        pageViewOf(tester).childrenDelegate.estimatedChildCount!;

    Future<void> goToPage(WidgetTester tester, int index) async {
      // Jumped rather than swiped: gestures inside the reader's loose Stack
      // are unreliable in a test.
      pageViewOf(tester).controller!.jumpToPage(index);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('the trailing page is not recorded as reading progress', (
      tester,
    ) async {
      // The trap P92 called the most insidious: recorded as page N+1, the
      // next visit lands on the recommendations instead of where the reader
      // left off, and nothing reveals it until then.
      await harness.keep('source', <int>[artist, other]);
      await harness.keep('sibling', <int>[artist, other]);

      await open(tester, comicWith(tagIds: <int>[artist, other]));
      expect(pageCountOf(tester), 3, reason: 'two pages plus the trailing one');

      await goToPage(tester, 2);
      expect(find.byType(SimilarComicsPage), findsOneWidget);

      expect(
        await harness.readerSettings.loadLastSeenPage('source'),
        isNot(3),
        reason: 'page 3 does not exist; it is the recommendations page',
      );
    });

    testWidgets('a comic with no tags gets no trailing page', (tester) async {
      await open(tester, comicWith());

      expect(find.byType(PageView), findsOneWidget);
      expect(pageCountOf(tester), 2, reason: 'its two pages and nothing more');
    });

    testWidgets(
      'a tagged comic gets a trailing page even with an empty library',
      (tester) async {
        // Looking on the site is most useful precisely when the library holds
        // nothing similar, and that button lives on this page.
        await open(tester, comicWith(tagIds: <int>[artist]));

        expect(pageCountOf(tester), 3);
      },
    );

    testWidgets('the trailing page lists what the library holds', (
      tester,
    ) async {
      await harness.keep('source', <int>[artist, other]);
      await harness.keep('sibling', <int>[artist, other]);

      await open(tester, comicWith(tagIds: <int>[artist, other]));
      await goToPage(tester, 2);

      expect(find.text('Comic sibling'), findsOneWidget);
    });

    testWidgets('the top bar keeps the comic', (tester) async {
      await open(tester, comicWith(tagIds: <int>[artist]));

      // The bar starts slid off-screen, and reaching the last page is what
      // brings it back — the same thing that happens when a reader finishes.
      // A centre tap would do it too, but the page images never load in a
      // test, so the tap zones are not where they would be on a device.
      await goToPage(tester, 1);
      // Past the 200ms slide, or the button is still on its way in.
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        tester.getCenter(find.byIcon(Icons.favorite_outline)).dy,
        greaterThan(0),
        reason: 'an off-screen button cannot be tapped',
      );

      expect(harness.favorites.isFavorite('source'), isFalse);

      await tester.tap(find.byIcon(Icons.favorite_outline));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(harness.favorites.isFavorite('source'), isTrue);
      expect(find.byIcon(Icons.favorite), findsNWidgets(2));
    });
  });
}
