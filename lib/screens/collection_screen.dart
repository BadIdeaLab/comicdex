import 'package:concept_nhv/application/library/collection_page_coordinator.dart';
import 'package:concept_nhv/application/home/home_shell_controller.dart';
import 'package:concept_nhv/models/collection_type.dart';
import 'package:concept_nhv/models/comic_card_data.dart';
import 'package:concept_nhv/state/download_manager_model.dart';
import 'package:concept_nhv/state/favorite_sync_model.dart';
import 'package:concept_nhv/widgets/comic_grid_sliver.dart';
import 'package:concept_nhv/widgets/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key, required this.collectionName});

  final String collectionName;

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  bool _selectionMode = false;
  final Map<String, ComicCardData> _selectedComics = {};
  List<ComicCardData> _allComics = const <ComicCardData>[];
  bool _isBatchDownloading = false;
  int? _batchDownloadProcessed;
  int? _batchDownloadTotal;
  // A State-owned controller (rather than CustomScrollView's default
  // PrimaryScrollController/PageStorage) so scroll position survives even if
  // the Element tree gets rebuilt — see .codex/phases/P52-collections-screen-reliability.md.
  final ScrollController _scrollController = ScrollController();

  CollectionType? get _collectionType =>
      CollectionType.fromStorageName(widget.collectionName);

  bool get _isFavorite => _collectionType == CollectionType.favorite;

  void _toggleSelection(ComicCardData comic) {
    setState(() {
      if (_selectedComics.containsKey(comic.id)) {
        _selectedComics.remove(comic.id);
      } else {
        _selectedComics[comic.id] = comic;
      }
    });
  }

  void _handleComicsLoaded(List<ComicCardData> comics) {
    if (!mounted || identical(_allComics, comics)) return;
    // Deferred to a post-frame callback: this fires from the child sliver's
    // build() (via FutureBuilder), and calling setState synchronously during
    // an ancestor's build would trigger a "setState during build" error.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _allComics = comics);
    });
  }

  bool get _isAllSelected =>
      _allComics.isNotEmpty && _selectedComics.length == _allComics.length;

  void _selectAll() {
    setState(() {
      for (final comic in _allComics) {
        _selectedComics[comic.id] = comic;
      }
    });
  }

  void _deselectAll() {
    setState(_selectedComics.clear);
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedComics.clear();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _downloadSelected(BuildContext context) async {
    final downloadManagerModel = context.read<DownloadManagerModel>();
    final messenger = ScaffoldMessenger.of(context);
    final comics = _selectedComics.values.toList();
    _exitSelectionMode();

    final toDownload = <ComicCardData>[];
    var alreadyHandled = 0;
    for (final comic in comics) {
      if (downloadManagerModel.jobForComic(comic.id) != null) {
        alreadyHandled++;
      } else {
        toDownload.add(comic);
      }
    }

    if (toDownload.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            alreadyHandled == 0
                ? 'No comics selected'
                : 'All $alreadyHandled comic${alreadyHandled > 1 ? 's' : ''} already in Downloads',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isBatchDownloading = true;
      _batchDownloadProcessed = 0;
      _batchDownloadTotal = toDownload.length;
    });

    final result = await downloadManagerModel.enqueueMany(
      toDownload,
      onProgress: (processed, total) {
        if (!mounted) return;
        setState(() {
          _batchDownloadProcessed = processed;
          _batchDownloadTotal = total;
        });
      },
    );

    if (!mounted) return;
    setState(() {
      _isBatchDownloading = false;
      _batchDownloadProcessed = null;
      _batchDownloadTotal = null;
    });

    final skipped = result.skippedCount + alreadyHandled;
    final messageParts = <String>[
      '${result.queuedCount} comic${result.queuedCount == 1 ? '' : 's'} added to Downloads',
      if (skipped > 0) '$skipped skipped (already downloaded)',
      if (result.failedCount > 0) '${result.failedCount} failed',
      if (result.stoppedEarly) 'stopped early after repeated failures',
    ];
    messenger.showSnackBar(SnackBar(content: Text(messageParts.join(', '))));
  }

  @override
  Widget build(BuildContext context) {
    final collectionType = _collectionType;
    if (collectionType == null) {
      return Scaffold(
        body: Center(child: Text('Unknown collection: ${widget.collectionName}')),
      );
    }

    final selectedCount = _selectedComics.length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: <Widget>[
          SliverAppBar(
            backgroundColor: Colors.transparent,
            flexibleSpace: GlassContainer.bar(child: const SizedBox.expand()),
            floating: true,
            snap: true,
            title: _selectionMode
                ? Text('$selectedCount selected')
                : Text(collectionType.displayName),
            actions: <Widget>[
              if (_isFavorite && !_selectionMode)
                IconButton(
                  icon: const Icon(Icons.checklist_outlined),
                  tooltip: 'Select comics',
                  onPressed: () => setState(() => _selectionMode = true),
                ),
              if (_selectionMode)
                IconButton(
                  icon: Icon(_isAllSelected ? Icons.deselect : Icons.select_all),
                  tooltip: _isAllSelected ? 'Deselect all' : 'Select all',
                  onPressed: _allComics.isEmpty
                      ? null
                      : (_isAllSelected ? _deselectAll : _selectAll),
                ),
              if (_selectionMode)
                TextButton(
                  onPressed: _exitSelectionMode,
                  child: const Text('Done'),
                ),
            ],
          ),
          if (collectionType == CollectionType.favorite)
            Consumer<FavoriteSyncModel>(
              builder: (context, favoriteModel, child) {
                final message = favoriteModel.syncError;
                if (message == null) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }

                return SliverToBoxAdapter(
                  child: Card(
                    margin: const EdgeInsets.all(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(message),
                          if (!favoriteModel.isAuthenticated)
                            TextButton(
                              onPressed: () => context.push('/settings'),
                              child: const Text('Open Settings'),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          CollectionComicSliver(
            collectionType: collectionType,
            selectedIds: _selectedComics.keys.toSet(),
            onToggleSelection: _selectionMode ? _toggleSelection : null,
            onComicsLoaded: _handleComicsLoaded,
          ),
        ],
      ),
      bottomNavigationBar: _isBatchDownloading
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: <Widget>[
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Adding $_batchDownloadProcessed/$_batchDownloadTotal to Downloads…',
                      ),
                    ),
                  ],
                ),
              ),
            )
          : (_selectionMode && selectedCount > 0
                ? SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: FilledButton.icon(
                        onPressed: () => _downloadSelected(context),
                        icon: const Icon(Icons.download_outlined),
                        label: Text(
                          'Download $selectedCount comic${selectedCount > 1 ? 's' : ''}',
                        ),
                      ),
                    ),
                  )
                : null),
    );
  }
}

class CollectionComicSliver extends StatefulWidget {
  const CollectionComicSliver({
    super.key,
    required this.collectionType,
    this.selectedIds = const <String>{},
    this.onToggleSelection,
    this.onComicsLoaded,
  });

  final CollectionType collectionType;
  final Set<String> selectedIds;
  final void Function(ComicCardData comic)? onToggleSelection;
  final void Function(List<ComicCardData> comics)? onComicsLoaded;

  @override
  State<CollectionComicSliver> createState() => _CollectionComicSliverState();
}

class _CollectionComicSliverState extends State<CollectionComicSliver> {
  late Future<List<ComicCardData>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadInitialComics();
  }

  @override
  void didUpdateWidget(covariant CollectionComicSliver oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.collectionType != widget.collectionType) {
      _future = _loadInitialComics();
    }
  }

  Future<List<ComicCardData>> _loadInitialComics() {
    return context.read<CollectionPageCoordinator>().load(
      widget.collectionType,
    );
  }

  void _refresh() {
    setState(() {
      _future = context.read<CollectionPageCoordinator>().refresh(
        widget.collectionType,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ComicCardData>>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SliverFillRemaining(hasScrollBody: false);
        }

        final comics = snapshot.requireData;
        widget.onComicsLoaded?.call(comics);
        if (comics.isEmpty) {
          final favoriteModel = context.watch<FavoriteSyncModel>();
          final isFavoriteCollection =
              widget.collectionType == CollectionType.favorite;
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('No comics in ${widget.collectionType.displayName}'),
                  if (isFavoriteCollection && !favoriteModel.isAuthenticated)
                    TextButton(
                      onPressed: () => context.push('/settings'),
                      child: const Text('Login from Settings'),
                    ),
                ],
              ),
            ),
          );
        }

        return ComicGridSliver(
          comics: comics,
          collectionType: widget.collectionType,
          onCollectionChanged: _refresh,
          onTagSelected: (tagQueries) async {
            await context
                .read<HomeShellController>()
                .submitTagSearch(tagQueries);
            if (context.mounted) {
              context.goNamed('index');
            }
          },
          selectedIds: widget.selectedIds,
          onToggleSelection: widget.onToggleSelection,
        );
      },
    );
  }
}
