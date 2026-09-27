import 'package:concept_nhv/application/favorites/clear_favorite_auth_use_case.dart';
import 'package:concept_nhv/application/favorites/initialize_favorites_use_case.dart';
import 'package:concept_nhv/application/favorites/save_api_key_use_case.dart';
import 'package:concept_nhv/application/favorites/sync_remote_favorites_use_case.dart';
import 'package:concept_nhv/application/favorites/toggle_favorite_use_case.dart';
import 'package:concept_nhv/application/tags/find_similar_comics_online_use_case.dart';
import 'package:concept_nhv/application/tags/find_similar_comics_use_case.dart';
import 'package:concept_nhv/models/local_tag_catalog_entry.dart';
import 'package:concept_nhv/models/stored_comic.dart';
import 'package:concept_nhv/models/tag_catalog_type.dart';
import 'package:concept_nhv/services/local_tag_catalog_service.dart';
import 'package:concept_nhv/services/tag_display_service.dart';
import 'package:concept_nhv/state/favorite_sync_model.dart';
import 'package:concept_nhv/storage/nhentai_api_key_store.dart';
import 'package:concept_nhv/widgets/comic_language_badge.dart';
import 'package:concept_nhv/widgets/reader/similar_comics_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../test_support/fakes/fake_nhentai_auth_service.dart';
import '../../test_support/fakes/fake_remote_favorite_gateway.dart';
import '../../test_support/fakes/memory_secure_store.dart';
import '../../test_support/helpers/localized_test_app.dart';
import '../../test_support/storage/sqlite_test_harness.dart';

/// nhentai's tag id for Japanese — see kLanguageTagIds.
const int japaneseTagId = 6346;

void main() {
  late SqliteTestHarness harness;
  late FavoriteSyncModel favorites;

  setUp(() async {
    harness = SqliteTestHarness();
    await harness.initialize();
    // A real model rather than a nullable lookup in the widget: letting the
    // tile quietly drop its favourite button when the provider is missing
    // would hide a wiring mistake in the app itself.
    final authService = FakeNhentaiAuthService(
      NhentaiApiKeyStore(secureStore: MemorySecureKeyValueStore()),
    );
    // Favourites are server-backed, so without a key the toggle correctly
    // refuses. Testing the button against an unauthenticated model would
    // only prove that it fails.
    await authService.saveAndValidateApiKey('test-key');
    final remoteFavorites = FakeRemoteFavoriteGateway();
    favorites = FavoriteSyncModel(
      initializeFavoritesUseCase: InitializeFavoritesUseCase(
        collectionRepository: harness.collectionRepository,
        authService: authService,
      ),
      saveApiKeyUseCase: SaveApiKeyUseCase(authService: authService),
      clearFavoriteAuthUseCase: ClearFavoriteAuthUseCase(
        authService: authService,
      ),
      syncRemoteFavoritesUseCase: SyncRemoteFavoritesUseCase(
        collectionRepository: harness.collectionRepository,
        comicTagRepository: harness.comicTagRepository,
        remoteFavoriteGateway: remoteFavorites,
      ),
      toggleFavoriteUseCase: ToggleFavoriteUseCase(
        collectionRepository: harness.collectionRepository,
        comicTagRepository: harness.comicTagRepository,
        remoteFavoriteGateway: remoteFavorites,
        authService: authService,
      ),
    );
  });

  tearDown(() async {
    favorites.dispose();
    await harness.dispose();
  });

  SimilarComic entry(
    String id, {
    List<int> shared = const <int>[7],
    List<int> tagIds = const <int>[7],
  }) {
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
      tagIds: tagIds,
    );
  }

  Widget buildPage({
    required List<SimilarComic> similar,
    void Function(String comicId)? onOpen,
    Future<OnlineSimilarResult> Function()? onFindOnline,
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
        ChangeNotifierProvider<FavoriteSyncModel>.value(value: favorites),
      ],
      child: localizedTestApp(
        home: SimilarComicsPage(
          similar: similar,
          onOpen: onOpen ?? (_) {},
          onFindOnline:
              onFindOnline ??
              () async => const OnlineSimilarResult.unavailable(),
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

  testWidgets('the online button is reachable without scrolling', (
    tester,
  ) async {
    // "One screenful" is the point of capping the library list: if six
    // covers push the button off a phone, the feature is unreachable where
    // it matters most.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      buildPage(
        similar: <SimilarComic>[for (var i = 0; i < 6; i++) entry('$i')],
      ),
    );
    await tester.pump();

    final button = find.text('Find more on the site');
    expect(button, findsOneWidget);
    expect(
      tester.getBottomLeft(button).dy,
      lessThan(tester.view.physicalSize.height / tester.view.devicePixelRatio),
    );
  });

  testWidgets('asks the site only when told to', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      buildPage(
        similar: <SimilarComic>[entry('1')],
        onFindOnline: () async {
          calls++;
          return const OnlineSimilarResult(
            comics: <OnlineSimilarComic>[],
            searchedTag: null,
            failed: false,
          );
        },
      ),
    );
    await tester.pump();

    expect(calls, 0, reason: 'nothing should be fetched on arrival');

    await tester.tap(find.text('Find more on the site'));
    await tester.pump();
    await tester.pump();

    expect(calls, 1);
  });

  testWidgets('says so when the site has nothing new', (tester) async {
    await tester.pumpWidget(
      buildPage(
        similar: <SimilarComic>[entry('1')],
        onFindOnline: () async => const OnlineSimilarResult(
          comics: <OnlineSimilarComic>[],
          searchedTag: null,
          failed: false,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Find more on the site'));
    await tester.pump();
    await tester.pump();

    // An empty area would read as a broken lookup.
    expect(find.textContaining('already have'), findsOneWidget);
  });

  testWidgets('reports a lookup that could not reach the site', (tester) async {
    await tester.pumpWidget(
      buildPage(
        similar: <SimilarComic>[entry('1')],
        onFindOnline: () async => const OnlineSimilarResult.unavailable(),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Find more on the site'));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Could not reach'), findsOneWidget);
  });

  testWidgets('shows the language on the cover', (tester) async {
    // Language was invisible here at first, so keeping something meant
    // opening it just to find out what it was written in.
    await tester.pumpWidget(
      buildPage(
        similar: <SimilarComic>[
          entry('1', tagIds: <int>[7, japaneseTagId]),
        ],
      ),
    );
    await tester.pump();

    expect(find.byKey(languageBadgeKey), findsOneWidget);
  });

  testWidgets('leaves the badge off when no language is known', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildPage(similar: <SimilarComic>[entry('1', tagIds: <int>[7])]),
    );
    await tester.pump();

    expect(find.byKey(languageBadgeKey), findsNothing);
  });

  testWidgets('favourites straight from the tile', (tester) async {
    // Tapping through to the comic replaces this reader, so "open it and come
    // back" is not a route the reader has.
    await tester.pumpWidget(buildPage(similar: <SimilarComic>[entry('1')]));
    await tester.pump();

    expect(favorites.isFavorite('1'), isFalse);

    await tester.tap(find.byIcon(Icons.favorite_outline));
    await tester.pump();
    await tester.pump();

    expect(favorites.isFavorite('1'), isTrue);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
  });
}
