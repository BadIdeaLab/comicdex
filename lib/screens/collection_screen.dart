import 'package:concept_nhv/application/library/collection_page_coordinator.dart';
import 'package:concept_nhv/application/home/home_shell_controller.dart';
import 'package:concept_nhv/l10n/app_localizations.dart';
import 'package:concept_nhv/models/collection_type.dart';
import 'package:concept_nhv/models/comic_card_data.dart';
import 'package:concept_nhv/services/local_tag_catalog_service.dart';
import 'package:concept_nhv/services/tag_display_service.dart';
import 'package:concept_nhv/state/download_manager_model.dart';
import 'package:concept_nhv/storage/comic_tag_repository.dart';
import 'package:concept_nhv/state/favorite_sync_model.dart';
import 'package:concept_nhv/widgets/comic_grid_sliver.dart';
import 'package:concept_nhv/widgets/collection_type_label.dart';
import 'package:concept_nhv/widgets/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({
    super.key,
    required this.collectionName,
    this.initialTagId,
  });

  final String collectionName;

  /// Shows only comics carrying this tag id, with a chip to clear it (P80).
  final int? initialTagId;

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  bool _selectionMode = false;
  int? _tagId;
  Set<String>? _tagFilterIds;

  @override
  void initState() {
    super.initState();
    _tagId = widget.initialTagId;
    _loadTagFilter();
  }

  Future<void> _loadTagFilter() async {
    final tagId = _tagId;
    if (tagId == null) return;
    final ids = await context.read<ComicTagRepository>().loadComicIdsWithTag(
      tagId,
    );
    if (!mounted) return;
    setState(() => _tagFilterIds = ids);
  }

  void _clearTagFilter() {
    setState(() {
      _tagId = null;
      _tagFilterIds = null;
    });
  }

  String get _tagFilterLabel {
    final entry = context.read<LocalTagCatalogService>().entryById(_tagId!);
    if (entry == null) {
      return AppLocalizations.of(context)!.collectionUnknownTag(_tagId!);
    }
    return context.read<TagDisplayService>().displayName(
      entry.slug,
      entry.name,
    );
  }

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
    final l10n = AppLocalizations.of(context)!;
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
                ? l10n.collectionNoneSelected
                : l10n.collectionAllAlreadyDownloaded(alreadyHandled),
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
      l10n.collectionBatchQueued(result.queuedCount),
      if (skipped > 0) l10n.collectionBatchSkipped(skipped),
      if (result.failedCount > 0)
        l10n.collectionBatchFailed(result.failedCount),
      if (result.stoppedEarly) l10n.collectionBatchStoppedEarly,
    ];
    messenger.showSnackBar(SnackBar(content: Text(messageParts.join(', '))));
  }

  @override
  Widget build(BuildContext context) {
    final collectionType = _collectionType;
    final l10n = AppLocalizations.of(context)!;
    if (collectionType == null) {
      return Scaffold(
        body: Center(
          child: Text(l10n.collectionUnknown(widget.collectionName)),
        ),
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
                ? Text(l10n.collectionSelectedCount(selectedCount))
                : Text(collectionTypeLabel(l10n, collectionType)),
            actions: <Widget>[
              if (_isFavorite && !_selectionMode)
                IconButton(
                  icon: const Icon(Icons.checklist_outlined),
                  tooltip: l10n.collectionSelectComics,
                  onPressed: () => setState(() => _selectionMode = true),
                ),
              if (_selectionMode)
                IconButton(
                  icon: Icon(
                    _isAllSelected ? Icons.deselect : Icons.select_all,
                  ),
                  tooltip: _isAllSelected
                      ? l10n.collectionDeselectAll
                      : l10n.collectionSelectAll,
                  onPressed: _allComics.isEmpty
                      ? null
                      : (_isAllSelected ? _deselectAll : _selectAll),
                ),
              if (_selectionMode)
                TextButton(
                  onPressed: _exitSelectionMode,
                  child: Text(l10n.collectionDone),
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
                              child: Text(l10n.collectionOpenSettings),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          if (_tagId != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: InputChip(
                    label: Text(_tagFilterLabel),
                    onDeleted: _clearTagFilter,
                  ),
                ),
              ),
            ),
          CollectionComicSliver(
            collectionType: collectionType,
            selectedIds: _selectedComics.keys.toSet(),
            onToggleSelection: _selectionMode ? _toggleSelection : null,
            onComicsLoaded: _handleComicsLoaded,
            // Null until the lookup finishes, which reads as "no filter yet"
            // rather than "nothing matches".
            filterComicIds: _tagId == null ? null : _tagFilterIds,
          ),
        ],
      ),
      bottomNavigationBar: _isBatchDownloading
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
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
                        l10n.collectionBatchProgress(
                          _batchDownloadProcessed ?? 0,
                          _batchDownloadTotal ?? 0,
                        ),
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
                          l10n.collectionDownloadSelected(selectedCount),
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
    this.filterComicIds,
  });

  final CollectionType collectionType;
  final Set<String> selectedIds;
  final void Function(ComicCardData comic)? onToggleSelection;
  final void Function(List<ComicCardData> comics)? onComicsLoaded;

  /// Restricts the list to these comic ids; null means no filter (P80).
  final Set<String>? filterComicIds;

  @override
  State<CollectionComicSliver> createState() => _CollectionComicSliverState();
}

class _CollectionComicSliverState extends State<CollectionComicSliver> {
  late Future<List<ComicCardData>> _future;
  FavoriteSyncModel? _favoriteSyncModel;
  DateTime? _seenSyncAt;

  @override
  void initState() {
    super.initState();
    _future = _loadInitialComics();
    if (widget.collectionType == CollectionType.favorite) {
      final model = context.read<FavoriteSyncModel>();
      _favoriteSyncModel = model;
      _seenSyncAt = model.lastSyncAt;
      model.addListener(_onFavoriteSyncChanged);
    }
  }

  @override
  void dispose() {
    _favoriteSyncModel?.removeListener(_onFavoriteSyncChanged);
    super.dispose();
  }

  /// Reloads the list once a background sync (P77) actually finished, so a
  /// favorite added elsewhere shows up without leaving the screen. Reads
  /// local data only — `refresh` never starts another sync, so this cannot
  /// loop. Skipped during multi-select, where rows disappearing under the
  /// user would be worse than waiting.
  void _onFavoriteSyncChanged() {
    final model = _favoriteSyncModel;
    if (model == null || model.isSyncing) return;
    final syncedAt = model.lastSyncAt;
    if (syncedAt == null || syncedAt == _seenSyncAt) return;
    _seenSyncAt = syncedAt;
    if (widget.onToggleSelection != null) return;
    if (!mounted) return;
    _refresh();
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
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<List<ComicCardData>>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SliverFillRemaining(hasScrollBody: false);
        }

        final loaded = snapshot.requireData;
        final filterIds = widget.filterComicIds;
        final comics = filterIds == null
            ? loaded
            : loaded
                  .where((comic) => filterIds.contains(comic.id))
                  .toList(growable: false);
        // Selection acts on what is on screen, so it gets the filtered list.
        widget.onComicsLoaded?.call(comics);
        if (comics.isEmpty && loaded.isNotEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text(l10n.collectionEmptyForTag)),
          );
        }
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
                  Text(
                    l10n.collectionEmpty(
                      collectionTypeLabel(l10n, widget.collectionType),
                    ),
                  ),
                  if (isFavoriteCollection && !favoriteModel.isAuthenticated)
                    TextButton(
                      onPressed: () => context.push('/settings'),
                      child: Text(l10n.collectionLoginFromSettings),
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
            await context.read<HomeShellController>().submitTagSearch(
              tagQueries,
            );
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
