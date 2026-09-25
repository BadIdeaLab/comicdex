import 'package:concept_nhv/models/collection_summary.dart';
import 'package:concept_nhv/models/comic_card_data.dart';
import 'package:concept_nhv/application/home/home_shell_controller.dart';
import 'package:concept_nhv/application/reader/reader_launcher.dart';
import 'package:concept_nhv/state/comic_feed_model.dart';
import 'package:concept_nhv/state/download_manager_model.dart';
import 'package:concept_nhv/state/home_ui_model.dart';
import 'package:concept_nhv/application/feed/feed_load_result.dart';
import 'package:concept_nhv/l10n/app_localizations.dart';
import 'package:concept_nhv/state/preference_score_model.dart';
import 'package:concept_nhv/widgets/feed_failure_message.dart';
import 'package:concept_nhv/state/tag_preference_model.dart';
import 'package:concept_nhv/widgets/collection_grid_sliver.dart';
import 'package:concept_nhv/widgets/comic_grid_sliver.dart';
import 'package:concept_nhv/widgets/download_job_list_sliver.dart';
import 'package:concept_nhv/widgets/downloads_tag_filter_chips.dart';
import 'package:concept_nhv/widgets/loading_indicator_bar.dart';
import 'package:concept_nhv/widgets/page_jump_bar.dart';
import 'package:concept_nhv/widgets/glass_container.dart';
import 'package:concept_nhv/widgets/search_suggestions_panel.dart';
import 'package:concept_nhv/widgets/tag_actions_sheet.dart';
import 'package:concept_nhv/widgets/tag_preference_sliver.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  /// One controller per bottom-nav destination.
  ///
  /// There used to be a single controller for all three, which did not merely
  /// look coupled — the tabs literally shared one scroll offset. Scrolling the
  /// home feed to 800 px and switching to Downloads landed there at 800 px, and
  /// a shorter Downloads list clamped the offset so the home feed lost its
  /// place on the way back.
  ///
  /// A controller each is only half of it: the `CustomScrollView` below is the
  /// same widget across tabs, so Flutter would keep one `ScrollPosition` and
  /// throw when a second controller attached to it. The per-tab [PageStorageKey]
  /// is what makes them distinct scroll views — dropping it is a crash, not a
  /// silent regression.
  static const int _destinationCount = 3;
  final List<ScrollController> _scrollControllers =
      List<ScrollController>.generate(
        _destinationCount,
        (_) => ScrollController(),
      );

  /// Where each tab was left, recorded by hand rather than left to
  /// `PageStorage`.
  ///
  /// The framework does restore a keyed scroll view's offset, but it writes
  /// that offset only when a scroll *ends* — a position abandoned mid-fling, or
  /// any path that skips `didEndScroll`, is never saved, and the tab silently
  /// comes back at the top. Reading the outgoing controller at the moment of
  /// the switch has no such timing to miss.
  final List<double> _savedOffsets = List<double>.filled(_destinationCount, 0);
  int _destination = 0;

  /// Records where the tab being left sat, and prepares the one being entered.
  ///
  /// Called from `build` before the scroll view is rebuilt: the outgoing
  /// controller is still attached at that point, and the incoming one is not
  /// attached yet, which is exactly when each can be touched safely.
  void _rememberOffsetAndSwap(int next) {
    final outgoing = _scrollControllers[_destination];
    if (outgoing.hasClients) {
      _savedOffsets[_destination] = outgoing.offset;
    }

    final incoming = _scrollControllers[next];
    if (!incoming.hasClients &&
        incoming.initialScrollOffset != _savedOffsets[next]) {
      // A controller's initial offset is fixed at construction, so restoring
      // to a new position means a new controller.
      incoming.dispose();
      _scrollControllers[next] = ScrollController(
        initialScrollOffset: _savedOffsets[next],
      );
    }
    _destination = next;
  }

  @override
  void dispose() {
    for (final controller in _scrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Select only navigationIndex — avoids scroll reset on isLoading changes.
    final navigationIndex = context.select<HomeUiModel, int>(
      (m) => m.navigationIndex,
    );
    final destination = navigationIndex.clamp(0, _destinationCount - 1);
    if (destination != _destination) {
      _rememberOffsetAndSwap(destination);
    }

    return CustomScrollView(
      key: PageStorageKey<int>(destination),
      controller: _scrollControllers[destination],
      physics: const BouncingScrollPhysics(),
      slivers: <Widget>[
        _buildTopBar(context, navigationIndex),
        // Scaffold(extendBody: true) lets content scroll behind the glass
        // bottom nav bar (see app_router.dart), but a bare CustomScrollView
        // doesn't consume the resulting bottom MediaQuery padding on its
        // own — without this, the last row(s) render underneath the bar.
        SliverSafeArea(
          top: false,
          sliver: _buildBody(context, navigationIndex),
        ),
      ],
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context, int navigationIndex) {
    if (navigationIndex == 1) {
      return _buildDownloadsAppBar(context);
    }
    return _buildHomeAppBar(context);
  }

  Widget _buildDownloadsAppBar(BuildContext context) {
    return Consumer<DownloadManagerModel>(
      builder: (context, model, _) {
        return SliverAppBar(
          backgroundColor: Colors.transparent,
          flexibleSpace: GlassContainer.bar(child: const SizedBox.expand()),
          floating: true,
          snap: true,
          title: TextField(
            // No onChanged: the model listens to its own controller, so typing
            // here and the tag sheet writing into it take the same path.
            controller: context.read<HomeUiModel>().downloadsSearchController,
            decoration: const InputDecoration(
              hintText: 'Search downloaded comics',
              border: InputBorder.none,
            ),
          ),
          actions: <Widget>[
            IconButton(
              onPressed: () => context.push('/settings'),
              icon: const Icon(Icons.settings),
            ),
          ],
          bottom: LoadingIndicatorBar(isLoading: model.isRefreshing),
        );
      },
    );
  }

  /// Reloads the home feed and returns to the top.
  ///
  /// Jumping to the top is right here and wrong on a tab switch: this is an
  /// explicit request for fresh results, so landing on them is expected —
  /// whereas the old automatic reload moved a reader who had asked for
  /// nothing.
  Future<void> _refreshHomeFeed(BuildContext context) async {
    final homeUiModel = context.read<HomeUiModel>();
    final feedModel = context.read<ComicFeedModel>();

    homeUiModel.setLoading(true);
    try {
      await feedModel.refreshCurrentQuery();
    } finally {
      homeUiModel.setLoading(false);
    }

    if (!mounted) {
      return;
    }
    final controller = _scrollControllers[0];
    if (controller.hasClients) {
      controller.jumpTo(0);
    }
  }

  Widget _buildHomeAppBar(BuildContext context) {
    return Consumer<HomeUiModel>(
      builder: (context, homeUiModel, _) {
        return SliverAppBar(
          clipBehavior: Clip.none,
          backgroundColor: Colors.transparent,
          flexibleSpace: GlassContainer.bar(child: const SizedBox.expand()),
          floating: true,
          snap: true,
          bottom: LoadingIndicatorBar(isLoading: homeUiModel.isLoading),
          title: SearchAnchor.bar(
            searchController: homeUiModel.searchController,
            onSubmitted: (value) => _handleSearchSubmit(context, value),
            barTrailing: <Widget>[
              IconButton.filledTonal(
                onPressed: homeUiModel.isLoading
                    ? null
                    : () => _refreshHomeFeed(context),
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
              IconButton.filledTonal(
                onPressed: () => context.push('/settings'),
                icon: const Icon(Icons.settings),
              ),
            ],
            barHintText: 'Search comic',
            barElevation: WidgetStateProperty.all(0),
            suggestionsBuilder: (buildContext, controller) {
              return <Widget>[
                SizedBox(
                  height: MediaQuery.sizeOf(buildContext).height * 0.56,
                  child: SearchSuggestionsPanel(
                    onHistorySelected: (query) {
                      controller.closeView(query);
                      _handleSearchSubmit(context, query);
                    },
                  ),
                ),
              ];
            },
          ),
        );
      },
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context, int navigationIndex) {
    switch (navigationIndex) {
      case 1:
        return SliverMainAxisGroup(
          slivers: <Widget>[
            const SliverToBoxAdapter(child: DownloadsTagFilterChips()),
            DownloadJobListSliver(
              searchQuery: context.select<HomeUiModel, String>(
                (m) => m.downloadsSearchQuery,
              ),
              filterTagIds: context.watch<HomeUiModel>().downloadsTagIds,
              onOpenOfflineReader: (comicId) =>
                  _handleOpenOfflineReader(context, comicId),
            ),
          ],
        );
      case 2:
        return const CollectionOverviewScreen();
      case 0:
      default:
        return _buildHomeFeedSliver(context);
    }
  }

  Widget _buildHomeFeedSliver(BuildContext context) {
    return Consumer<ComicFeedModel>(
      builder: (context, feedModel, _) {
        final comics = feedModel.comics;

        // No data yet — show error or empty placeholder.
        if (comics == null) {
          final failure = feedModel.feedFailure;
          if (failure != null) {
            return _buildFeedError(context, failure);
          }
          return SliverList(
            delegate: SliverChildListDelegate(const <Widget>[]),
          );
        }

        final numPages = feedModel.numPages;
        final showPageBar = numPages != null && numPages > 1;

        return SliverMainAxisGroup(
          slivers: <Widget>[
            if (showPageBar)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      PageJumpBar(
                        currentPage: feedModel.pageLoaded,
                        totalPages: numPages,
                        onJump: feedModel.jumpToPage,
                      ),
                    ],
                  ),
                ),
              ),
            ComicGridSliver(
              showsPreferenceBadges: true,
              comics: comics.map(ComicCardData.fromComic).toList(),
              pageLoaded: feedModel.pageLoaded,
              onTagSelected: (tagQueries) =>
                  _handleTagSelected(context, tagQueries),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeedError(BuildContext context, FeedLoadFailure failure) {
    final l10n = AppLocalizations.of(context)!;
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(feedFailureMessage(l10n, failure), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => _retryHomeFeed(context),
                child: Text(l10n.retryButton),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Handlers ──────────────────────────────────────────────────────────────

  Future<void> _handleSearchSubmit(BuildContext context, String value) async {
    final controller = context.read<HomeShellController>();
    final launcher = context.read<ReaderLauncher>();
    final navigator = GoRouter.of(context);

    // Deliberately outside the launcher: submitSearch handles ordinary text
    // searches too, and those must never be blocked just because a reader
    // happens to be open.
    final result = await controller.submitSearch(value);
    if (!mounted || !result.openComicReader || result.comicId == null) return;

    // submitSearch already loaded the comic, so there is nothing left to load.
    await launcher.open(
      show: () => navigator.push(
        Uri(
          path: '/third',
          queryParameters: <String, String>{'id': result.comicId!},
        ).toString(),
      ),
    );
  }

  Future<void> _handleTagSelected(
    BuildContext context,
    List<String> tagQueries,
  ) async {
    await context.read<HomeShellController>().submitTagSearch(tagQueries);
  }

  Future<void> _retryHomeFeed(BuildContext context) async {
    await context.read<HomeShellController>().retryHomeFeed();
  }

  Future<void> _handleOpenOfflineReader(BuildContext context, String comicId) {
    final navigator = GoRouter.of(context);

    return context.read<ReaderLauncher>().open(
      // The reader loads from local files and reports "not downloaded" itself;
      // there is nothing to check before navigating.
      show: () => navigator.push(
        Uri(
          path: '/third',
          queryParameters: <String, String>{'id': comicId, 'offline': 'true'},
        ).toString(),
      ),
    );
  }
}

// ── Collection overview ───────────────────────────────────────────────────────

class CollectionOverviewScreen extends StatefulWidget {
  const CollectionOverviewScreen({super.key});

  @override
  State<CollectionOverviewScreen> createState() =>
      _CollectionOverviewScreenState();
}

class _CollectionOverviewScreenState extends State<CollectionOverviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final feedModel = context.read<ComicFeedModel>();
      if (feedModel.collectionSummariesFuture == null) {
        feedModel.refreshCollections();
      }
      // Recomputed on every visit: favorites and downloads change underneath
      // it, and the query is cheap enough not to warrant a cache (P78).
      context.read<TagPreferenceModel>().load();
      // The badges and the Downloads preference sort read the same ranking,
      // so this is the natural place to refresh them: the user is looking at
      // their taste, which is exactly when it has just changed (P84).
      // Optional, like the badge itself — this screen has to build with no
      // preference data above it.
      context.read<PreferenceScoreModel?>()?.refresh();
    });
  }

  Widget _buildTagPreferences(BuildContext context) {
    final model = context.watch<TagPreferenceModel>();
    if (!model.hasLoaded) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return TagPreferenceSliver(
      preferences: model.preferences,
      sort: model.sort,
      onSortChanged: model.setSort,
      onTagTap: (tag, displayName) => context
          .read<HomeShellController>()
          .submitTagSearch(<String>[tag.query]),
      onTagLongPress: (tag, displayName) =>
          showTagActionsSheet(context, tag, displayName),
      onOpenFullAnalysis: () => context.push('/analysis'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final future = context.watch<ComicFeedModel>().collectionSummariesFuture;
    if (future == null) {
      return const SliverFillRemaining(hasScrollBody: false);
    }

    return FutureBuilder<List<CollectionSummary>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('Failed to load collections'),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () =>
                        context.read<ComicFeedModel>().refreshCollections(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const SliverFillRemaining(hasScrollBody: false);
        }
        return SliverMainAxisGroup(
          slivers: <Widget>[
            CollectionGridSliver(collections: snapshot.requireData),
            _buildTagPreferences(context),
          ],
        );
      },
    );
  }
}
