import 'package:concept_nhv/models/collection_summary.dart';
import 'package:concept_nhv/models/comic_card_data.dart';
import 'package:concept_nhv/application/home/home_shell_controller.dart';
import 'package:concept_nhv/state/comic_feed_model.dart';
import 'package:concept_nhv/state/comic_reader_model.dart';
import 'package:concept_nhv/state/download_manager_model.dart';
import 'package:concept_nhv/state/home_ui_model.dart';
import 'package:concept_nhv/widgets/collection_grid_sliver.dart';
import 'package:concept_nhv/widgets/comic_grid_sliver.dart';
import 'package:concept_nhv/widgets/download_job_list_sliver.dart';
import 'package:concept_nhv/widgets/loading_indicator_bar.dart';
import 'package:concept_nhv/widgets/page_jump_bar.dart';
import 'package:concept_nhv/widgets/glass_container.dart';
import 'package:concept_nhv/widgets/search_suggestions_panel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _downloadsSearchController = TextEditingController();
  String _downloadsSearchQuery = '';

  @override
  void dispose() {
    _scrollController.dispose();
    _downloadsSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Select only navigationIndex — avoids scroll reset on isLoading changes.
    final navigationIndex =
        context.select<HomeUiModel, int>((m) => m.navigationIndex);

    return CustomScrollView(
      controller: _scrollController,
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
            controller: _downloadsSearchController,
            onChanged: (value) => setState(() => _downloadsSearchQuery = value),
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
        return DownloadJobListSliver(
          searchQuery: _downloadsSearchQuery,
          onOpenOfflineReader: (comicId) =>
              _handleOpenOfflineReader(context, comicId),
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
          final errorMessage = feedModel.feedErrorMessage;
          if (errorMessage != null) {
            return _buildFeedError(context, errorMessage);
          }
          return SliverList(delegate: SliverChildListDelegate(const <Widget>[]));
        }

        final numPages = feedModel.numPages;
        final showPageBar = numPages != null && numPages > 1;

        return SliverMainAxisGroup(
          slivers: <Widget>[
            if (showPageBar)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              comics: comics.map(ComicCardData.fromComic).toList(),
              pageLoaded: feedModel.pageLoaded,
              onTagSelected: (tagQueries) => _handleTagSelected(context, tagQueries),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeedError(BuildContext context, String errorMessage) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(errorMessage, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => _retryHomeFeed(context),
                child: const Text('Retry'),
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
    final readerModel = context.read<ComicReaderModel>();
    final downloadManagerModel = context.read<DownloadManagerModel>();
    final navigator = GoRouter.of(context);

    final result = await controller.submitSearch(value);
    if (!mounted || !result.openComicReader || result.comicId == null) return;

    await navigator.push(
      Uri(
        path: '/third',
        queryParameters: <String, String>{'id': result.comicId!},
      ).toString(),
    );
    if (!mounted) return;
    readerModel.clearComic();
    await downloadManagerModel.refresh();
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

  Future<void> _handleOpenOfflineReader(
    BuildContext context,
    String comicId,
  ) async {
    final readerModel = context.read<ComicReaderModel>();
    final downloadManagerModel = context.read<DownloadManagerModel>();
    final navigator = GoRouter.of(context);

    final opened = await readerModel.loadOfflineComic(comicId);
    if (!mounted || !opened) return;

    await navigator.push(
      Uri(
        path: '/third',
        queryParameters: <String, String>{'id': comicId, 'offline': 'true'},
      ).toString(),
    );
    if (!mounted) return;
    readerModel.clearComic();
    await downloadManagerModel.refresh();
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
    });
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
        return CollectionGridSliver(collections: snapshot.requireData);
      },
    );
  }
}
