import 'dart:io';
import 'dart:math';

import 'package:concept_nhv/application/downloads/weighted_random_pick.dart';
import 'package:concept_nhv/application/home/home_shell_controller.dart';
import 'package:concept_nhv/application/tags/load_comic_meta_use_case.dart';
import 'package:concept_nhv/l10n/app_localizations.dart';
import 'package:concept_nhv/models/comic_tag.dart';
import 'package:concept_nhv/models/download_job_status.dart';
import 'package:concept_nhv/models/download_list_item_snapshot.dart';
import 'package:concept_nhv/services/tag_display_service.dart';
import 'package:concept_nhv/state/download_manager_model.dart';
import 'package:concept_nhv/widgets/comic_tag_bottom_sheet.dart';
import 'package:concept_nhv/widgets/fallback_cached_network_image.dart';
import 'package:concept_nhv/widgets/page_jump_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class DownloadJobListSliver extends StatefulWidget {
  const DownloadJobListSliver({
    super.key,
    required this.searchQuery,
    required this.onOpenOfflineReader,
    this.filterTagIds = const <int>[],
  });

  final String searchQuery;

  /// Tag ids every shown download must carry — ANDed with each other and
  /// with [searchQuery] (P82). Matched by id, so `full color` cannot match
  /// `full colors` the way the text filter would.
  final List<int> filterTagIds;

  /// Called when the user taps a completed download card to open the reader.
  final ValueChanged<String> onOpenOfflineReader;

  @override
  State<DownloadJobListSliver> createState() => _DownloadJobListSliverState();
}

class _DownloadJobListSliverState extends State<DownloadJobListSliver> {
  String? _expandedComicId;

  bool _isRepairingAll = false;
  int? _repairProgressCurrent;
  int? _repairProgressTotal;
  final Random _random = Random();

  @override
  void didUpdateWidget(DownloadJobListSliver oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<DownloadManagerModel>().resetCompletedPage();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DownloadManagerModel>(
      builder: (context, model, _) {
        final l10n = AppLocalizations.of(context)!;
        final query = widget.searchQuery.trim().toLowerCase();
        final tagDisplayService = context.read<TagDisplayService>();
        final filteredItems = model.sortedDownloadItems
            .where((item) {
              // An in-progress job has no tags yet, so a tag filter cannot
              // match it — deliberately, since it has nothing to match on.
              for (final tagId in widget.filterTagIds) {
                if (!item.tags.any((tag) => tag.id == tagId)) return false;
              }
              if (query.isEmpty) return true;
              if (item.title.toLowerCase().contains(query)) return true;
              return item.tags.any((tag) {
                final rawName = tag.name ?? '';
                final displayName = tagDisplayService.displayName(
                  tag.slug,
                  rawName,
                );
                return rawName.toLowerCase().contains(query) ||
                    displayName.toLowerCase().contains(query);
              });
            })
            .toList(growable: false);
        final activeItems = filteredItems
            .where((item) => !item.isCompletedCard)
            .toList(growable: false);
        final completedItems = filteredItems
            .where((item) => item.isCompletedCard)
            .toList(growable: false);

        if (filteredItems.isEmpty) {
          final hasFilter = query.isNotEmpty || widget.filterTagIds.isNotEmpty;
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                !hasFilter
                    ? l10n.downloadsEmpty
                    : query.isEmpty
                    ? l10n.downloadsEmptyForTags
                    : l10n.downloadsEmptyForQuery(widget.searchQuery.trim()),
              ),
            ),
          );
        }

        // Pagination for completed items: [anchorPage, currentPage] is the
        // continuously-revealed range. Jumping resets both to the same
        // page; scrolling to the end only advances currentPage, so already
        // revealed pages stay visible (mirrors ComicFeedModel/ComicGridSliver).
        final pageSize = DownloadManagerModel.completedPageSize;
        final totalCompletedPages = completedItems.isEmpty
            ? 1
            : ((completedItems.length + pageSize - 1) ~/ pageSize);
        final anchorPage = model.completedAnchorPage.clamp(
          1,
          totalCompletedPages,
        );
        final currentPage = model.completedPage.clamp(1, totalCompletedPages);
        final pageStart = (anchorPage - 1) * pageSize;
        final pageEnd = (currentPage * pageSize).clamp(
          0,
          completedItems.length,
        );
        final pagedCompletedItems = completedItems.sublist(pageStart, pageEnd);
        final showPageBar = completedItems.length > pageSize;

        final slivers = <Widget>[];

        if (activeItems.isNotEmpty) {
          slivers.add(
            SliverToBoxAdapter(
              child: _DownloadsSectionHeader(
                title: l10n.downloadsSectionActive,
              ),
            ),
          );
          slivers.add(
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildItemCard(model, activeItems[index]),
                childCount: activeItems.length,
              ),
            ),
          );
        }

        if (completedItems.isNotEmpty) {
          slivers.add(
            SliverToBoxAdapter(
              child: _DownloadsSectionHeader(
                title: l10n.downloadsSectionCompleted,
                isGridView: model.completedViewIsGrid,
                onViewToggle: () =>
                    model.setCompletedViewIsGrid(!model.completedViewIsGrid),
                isRepairingAll: _isRepairingAll,
                repairProgressCurrent: _repairProgressCurrent,
                repairProgressTotal: _repairProgressTotal,
                onRandomCompleted: () => _openRandomCompleted(completedItems),
                onRepairAll: () => _handleRepairAll(model),
              ),
            ),
          );

          if (showPageBar) {
            slivers.add(
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      PageJumpBar(
                        currentPage: anchorPage,
                        totalPages: totalCompletedPages,
                        onJump: (page) async {
                          model.setCompletedPage(page);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          if (model.completedViewIsGrid) {
            slivers.add(
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 150,
                    mainAxisExtent: 220,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    _maybeRevealNextCompletedPage(
                      model,
                      index,
                      pagedCompletedItems.length,
                      totalCompletedPages,
                    );
                    final item = pagedCompletedItems[index];
                    return _CompletedGridCell(
                      key: ValueKey<String>(item.comicId),
                      item: item,
                      isMutating: model.isMutating(item.comicId),
                      onTap: () => widget.onOpenOfflineReader(item.comicId),
                    );
                  }, childCount: pagedCompletedItems.length),
                ),
              ),
            );
          } else {
            slivers.add(
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  _maybeRevealNextCompletedPage(
                    model,
                    index,
                    pagedCompletedItems.length,
                    totalCompletedPages,
                  );
                  return _buildItemCard(model, pagedCompletedItems[index]);
                }, childCount: pagedCompletedItems.length),
              ),
            );
          }
        }

        return SliverMainAxisGroup(slivers: slivers);
      },
    );
  }

  /// Mirrors [ComicGridSliver]'s auto-load-next-page trigger, but reveals an
  /// already in-memory page instead of fetching one — no loading flag or
  /// snackbar needed since there's no network latency to signal.
  void _maybeRevealNextCompletedPage(
    DownloadManagerModel model,
    int index,
    int renderedCount,
    int totalPages,
  ) {
    final reachLastItem = index + 1 == renderedCount;
    if (!reachLastItem || model.completedPage >= totalPages) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      model.revealNextCompletedPage(totalPages);
    });
  }

  void _openRandomCompleted(List<DownloadListItemSnapshot> completedItems) {
    // Weighted rather than uniform: uniform drawing repeats far more often
    // than it feels like it should (P87). The pool is the whole filtered
    // list, not the page on screen.
    final item = pickByReadingStaleness<DownloadListItemSnapshot>(
      completedItems,
      lastReadAt: (item) => item.lastReadAt,
      tieBreaker: (item) => item.comicId,
      random: _random,
    );
    if (item == null) return;
    widget.onOpenOfflineReader(item.comicId);
  }

  Widget _buildItemCard(
    DownloadManagerModel model,
    DownloadListItemSnapshot item,
  ) {
    return _DownloadItemCard(
      key: ValueKey<String>(item.comicId),
      item: item,
      isExpanded: _expandedComicId == item.comicId,
      isMutating: model.isMutating(item.comicId),
      onToggleExpanded: () {
        setState(() {
          _expandedComicId = _expandedComicId == item.comicId
              ? null
              : item.comicId;
        });
      },
      onOpenOfflineReader: () => widget.onOpenOfflineReader(item.comicId),
    );
  }

  Future<void> _handleRepairAll(DownloadManagerModel model) async {
    final l10n = AppLocalizations.of(context)!;
    if (_isRepairingAll) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.downloadsRepairAllTitle),
          content: Text(l10n.downloadsRepairAllBody),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancelButton),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.downloadsRepairAllConfirm),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isRepairingAll = true;
      _repairProgressCurrent = null;
      _repairProgressTotal = null;
    });
    try {
      final result = await model.repairAllCompleted(
        onProgress: (processed, total) {
          if (!mounted) {
            return;
          }
          setState(() {
            _repairProgressCurrent = processed;
            _repairProgressTotal = total;
          });
        },
      );
      if (!mounted) {
        return;
      }
      final message = switch ((
        result.repairedCount,
        result.failedCount,
        result.stoppedEarly,
      )) {
        (0, 0, _) => l10n.downloadsRepairAllIntact(result.totalCount),
        (_, 0, _) => l10n.downloadsRepairAllRepaired(
          result.repairedCount,
          result.totalCount,
        ),
        (_, _, true) => l10n.downloadsRepairAllStopped(
          result.repairedCount,
          result.failedCount,
          result.totalCount,
        ),
        _ => l10n.downloadsRepairAllMixed(
          result.repairedCount,
          result.failedCount,
          result.totalCount,
        ),
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.downloadsRepairAllError('$error'))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRepairingAll = false;
          _repairProgressCurrent = null;
          _repairProgressTotal = null;
        });
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Section header (Active / Completed) — optional grid/list toggle
// ---------------------------------------------------------------------------

class _DownloadsSectionHeader extends StatelessWidget {
  const _DownloadsSectionHeader({
    required this.title,
    this.onViewToggle,
    this.isGridView = false,
    this.onRandomCompleted,
    this.onRepairAll,
    this.isRepairingAll = false,
    this.repairProgressCurrent,
    this.repairProgressTotal,
  });

  final String title;
  final VoidCallback? onViewToggle;
  final bool isGridView;
  final VoidCallback? onRandomCompleted;
  final VoidCallback? onRepairAll;
  final bool isRepairingAll;
  final int? repairProgressCurrent;
  final int? repairProgressTotal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasTrailingActions =
        onViewToggle != null ||
        onRandomCompleted != null ||
        onRepairAll != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, hasTrailingActions ? 4 : 16, 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (isRepairingAll &&
              repairProgressCurrent != null &&
              repairProgressTotal != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                '$repairProgressCurrent/$repairProgressTotal',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          if (onRandomCompleted != null)
            IconButton(
              icon: const Icon(Icons.shuffle),
              tooltip: l10n.downloadsRandomTooltip,
              onPressed: onRandomCompleted,
              iconSize: 20,
              visualDensity: VisualDensity.compact,
            ),
          if (onRepairAll != null)
            IconButton(
              icon: isRepairingAll
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.build_circle_outlined),
              tooltip: l10n.downloadsRepairAllTooltip,
              onPressed: isRepairingAll ? null : onRepairAll,
              iconSize: 20,
              visualDensity: VisualDensity.compact,
            ),
          if (onViewToggle != null)
            IconButton(
              icon: Icon(isGridView ? Icons.list : Icons.grid_view),
              tooltip: isGridView
                  ? l10n.downloadsListViewTooltip
                  : l10n.downloadsGridViewTooltip,
              onPressed: onViewToggle,
              iconSize: 20,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Grid cell — completed downloads only
// ---------------------------------------------------------------------------

class _CompletedGridCell extends StatelessWidget {
  const _CompletedGridCell({
    super.key,
    required this.item,
    required this.isMutating,
    required this.onTap,
  });

  final DownloadListItemSnapshot item;
  final bool isMutating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        onLongPress: () {
          HapticFeedback.selectionClick();
          _showCompletedSheetFor(context, item, isMutating);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(child: _CompletedGridCover(item: item)),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.downloadsPageCountShort(
                      item.pageCount ?? item.totalPages,
                    ),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletedGridCover extends StatelessWidget {
  const _CompletedGridCover({required this.item});

  final DownloadListItemSnapshot item;

  @override
  Widget build(BuildContext context) {
    final localCoverPath = item.coverLocalPath;
    if (localCoverPath != null && localCoverPath.isNotEmpty) {
      return Image.file(
        File(localCoverPath),
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, _, _) => _buildFallback(context),
      );
    }
    return _buildFallback(context);
  }

  Widget _buildFallback(BuildContext context) {
    final thumbnailPath = item.thumbnailPath;
    if (thumbnailPath == null || thumbnailPath.isEmpty) {
      return ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(child: Icon(Icons.image_not_supported)),
      );
    }
    return FallbackCachedNetworkImage(
      url: 'https://t1.nhentai.net/$thumbnailPath',
      width: 150,
      height: 170,
    );
  }
}

// ---------------------------------------------------------------------------
// Shared helpers for completed download actions
// (used by both list-view _DownloadItemCard and grid-view _CompletedGridCell)
// ---------------------------------------------------------------------------

Future<void> _showCompletedSheetFor(
  BuildContext context,
  DownloadListItemSnapshot item,
  bool isMutating,
) async {
  final homeShellController = context.read<HomeShellController>();
  final loadComicMetaUseCase = context.read<LoadComicMetaUseCase>();

  await ComicTagBottomSheet.show(
    context: context,
    title: item.title,
    tags: item.tags,
    comicId: item.comicId,
    comicNumFavorites: item.numFavorites,
    loadMeta: () => loadComicMetaUseCase.execute(item.comicId),
    onSearchSelected: (queries) async {
      await homeShellController.submitTagSearch(queries);
      if (context.mounted) {
        context.goNamed('index');
      }
    },
    actionSlot: _buildCompletedActionSlotFor(context, item, isMutating),
  );
}

Widget _buildCompletedActionSlotFor(
  BuildContext context,
  DownloadListItemSnapshot item,
  bool isMutating,
) {
  final l10n = AppLocalizations.of(context)!;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
          side: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
        icon: const Icon(Icons.delete_outline),
        label: Text(l10n.downloadsDeleteAction),
        onPressed: isMutating
            ? null
            : () {
                Navigator.of(context, rootNavigator: true).pop();
                _confirmAndDeleteCompleted(context, item);
              },
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        icon: const Icon(Icons.refresh),
        label: Text(l10n.downloadsReloadAction),
        onPressed: isMutating
            ? null
            : () {
                Navigator.of(context, rootNavigator: true).pop();
                _confirmAndReloadCompleted(context, item);
              },
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        icon: const Icon(Icons.build_outlined),
        label: Text(l10n.downloadsRepairAction),
        onPressed: isMutating
            ? null
            : () {
                Navigator.of(context, rootNavigator: true).pop();
                _runRepairCompleted(context, item);
              },
      ),
    ],
  );
}

Future<void> _confirmAndDeleteCompleted(
  BuildContext context,
  DownloadListItemSnapshot item,
) async {
  final l10n = AppLocalizations.of(context)!;
  final shouldDelete = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.downloadsDeleteTitle),
        content: Text(l10n.downloadsDeleteBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.confirmButton),
          ),
        ],
      );
    },
  );

  if (shouldDelete != true || !context.mounted) {
    return;
  }

  await _runAction(
    context,
    successMessage: l10n.downloadsDeletedMessage,
    action: () => context.read<DownloadManagerModel>().deleteJob(item.comicId),
  );
}

Future<void> _confirmAndReloadCompleted(
  BuildContext context,
  DownloadListItemSnapshot item,
) async {
  final l10n = AppLocalizations.of(context)!;
  final shouldReload = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.downloadsReloadTitle),
        content: Text(l10n.downloadsReloadBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.downloadsReloadAction),
          ),
        ],
      );
    },
  );

  if (shouldReload != true || !context.mounted) {
    return;
  }

  await _runAction(
    context,
    successMessage: l10n.downloadsReloadQueued,
    action: () =>
        context.read<DownloadManagerModel>().reloadCompleted(item.comicId),
  );
}

Future<void> _runRepairCompleted(
  BuildContext context,
  DownloadListItemSnapshot item,
) async {
  final l10n = AppLocalizations.of(context)!;
  await _runAction(
    context,
    successMessage: l10n.downloadsRepairQueued,
    noOpMessage: l10n.downloadsNothingToRepair,
    action: () async {
      await context.read<DownloadManagerModel>().repairCompleted(item.comicId);
    },
  );
}

Future<void> _runAction(
  BuildContext context, {
  required String successMessage,
  String? noOpMessage,
  required Future<void> Function() action,
}) async {
  final beforeItems = context.read<DownloadManagerModel>().downloadItems;
  try {
    await action();
    if (!context.mounted) return;
    final afterItems = context.read<DownloadManagerModel>().downloadItems;
    final changed = afterItems != beforeItems;
    final message = (!changed && noOpMessage != null)
        ? noOpMessage
        : successMessage;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$error')));
  }
}

// ---------------------------------------------------------------------------
// List-view card — active and completed
// ---------------------------------------------------------------------------

class _DownloadItemCard extends StatelessWidget {
  const _DownloadItemCard({
    super.key,
    required this.item,
    required this.isExpanded,
    required this.isMutating,
    required this.onToggleExpanded,
    required this.onOpenOfflineReader,
  });

  final DownloadListItemSnapshot item;
  final bool isExpanded;
  final bool isMutating;
  final VoidCallback onToggleExpanded;

  /// Only invoked for completed cards; opens the offline reader.
  final VoidCallback onOpenOfflineReader;

  @override
  Widget build(BuildContext context) {
    // Completed cards: tap → open reader, long-press → open tag/action sheet.
    // Active cards: tap → expand/collapse (unchanged).
    final onTap = item.isCompletedCard ? onOpenOfflineReader : onToggleExpanded;
    final onLongPress = item.isCompletedCard
        ? () {
            HapticFeedback.selectionClick();
            _showCompletedSheetFor(context, item, isMutating);
          }
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    width: 72,
                    child: AspectRatio(
                      aspectRatio: 0.72,
                      child: _DownloadItemCover(item: item),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: item.isCompletedCard
                        ? _CompletedCardSummary(item: item)
                        : _ActiveCardSummary(item: item),
                  ),
                  if (!item.isCompletedCard) ...<Widget>[
                    const SizedBox(width: 8),
                    Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                  ],
                ],
              ),
              if (!item.isCompletedCard)
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 180),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _buildActionButtons(context),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final model = context.read<DownloadManagerModel>();
    return switch (item.status) {
      DownloadJobStatus.downloading => <Widget>[
        FilledButton.tonal(
          onPressed: isMutating
              ? null
              : () => _runAction(
                  context,
                  successMessage: l10n.downloadsPausedMessage,
                  action: () => model.pause(item.comicId),
                ),
          child: Text(l10n.downloadsPauseAction),
        ),
      ],
      DownloadJobStatus.queued => <Widget>[
        FilledButton.tonal(
          onPressed: isMutating
              ? null
              : () => _runAction(
                  context,
                  successMessage: l10n.downloadsPausedMessage,
                  action: () => model.pause(item.comicId),
                ),
          child: Text(l10n.downloadsPauseAction),
        ),
      ],
      DownloadJobStatus.paused => <Widget>[
        FilledButton(
          onPressed: isMutating
              ? null
              : () => _runAction(
                  context,
                  successMessage: l10n.downloadsResumedMessage,
                  action: () => model.resume(item.comicId),
                ),
          child: Text(l10n.downloadsResumeAction),
        ),
        OutlinedButton(
          onPressed: isMutating
              ? null
              : () => _confirmAndDelete(
                  context,
                  title: l10n.downloadsRemoveJobTitle,
                  message: l10n.downloadsRemoveJobBody,
                  successMessage: l10n.downloadsJobRemovedMessage,
                ),
          child: Text(l10n.downloadsRemoveAction),
        ),
      ],
      DownloadJobStatus.failed => <Widget>[
        FilledButton(
          onPressed: isMutating
              ? null
              : () => _runAction(
                  context,
                  successMessage: l10n.downloadsRetriedMessage,
                  action: () => model.retry(item.comicId),
                ),
          child: Text(l10n.downloadsRetryAction),
        ),
        OutlinedButton(
          onPressed: isMutating
              ? null
              : () => _confirmAndDelete(
                  context,
                  title: l10n.downloadsRemoveFailedTitle,
                  message: l10n.downloadsRemoveFailedBody,
                  successMessage: l10n.downloadsFailedRemovedMessage,
                ),
          child: Text(l10n.downloadsRemoveAction),
        ),
      ],
      DownloadJobStatus.completed => <Widget>[],
    };
  }

  Future<void> _confirmAndDelete(
    BuildContext context, {
    required String title,
    required String message,
    required String successMessage,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancelButton),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.confirmButton),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !context.mounted) {
      return;
    }

    await _runAction(
      context,
      successMessage: successMessage,
      action: () =>
          context.read<DownloadManagerModel>().deleteJob(item.comicId),
    );
  }
}

// ---------------------------------------------------------------------------
// Card content widgets
// ---------------------------------------------------------------------------

class _ActiveCardSummary extends StatelessWidget {
  const _ActiveCardSummary({required this.item});

  final DownloadListItemSnapshot item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final progress = item.totalPages == 0
        ? 0.0
        : (item.completedPages / item.totalPages).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(_statusLabel(l10n, item.status)),
        const SizedBox(height: 8),
        Text('${item.completedPages} / ${item.totalPages}'),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: progress),
      ],
    );
  }
}

class _CompletedCardSummary extends StatelessWidget {
  const _CompletedCardSummary({required this.item});

  final DownloadListItemSnapshot item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pageCount = item.pageCount ?? item.totalPages;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(l10n.downloadsStatusCompleted),
        const SizedBox(height: 8),
        Text(l10n.downloadsPageCount(pageCount)),
      ],
    );
  }
}

class _DownloadItemCover extends StatelessWidget {
  const _DownloadItemCover({required this.item});

  final DownloadListItemSnapshot item;

  @override
  Widget build(BuildContext context) {
    final localCoverPath = item.coverLocalPath;
    if (localCoverPath != null && localCoverPath.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(localCoverPath),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallback(context),
        ),
      );
    }
    return _buildFallback(context);
  }

  Widget _buildFallback(BuildContext context) {
    final thumbnailPath = item.thumbnailPath;
    if (thumbnailPath == null || thumbnailPath.isEmpty) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(child: Icon(Icons.download)),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: FallbackCachedNetworkImage(
        url: 'https://t1.nhentai.net/$thumbnailPath',
        width: 72,
        height: 100,
      ),
    );
  }
}

String _statusLabel(AppLocalizations l10n, DownloadJobStatus status) {
  return switch (status) {
    DownloadJobStatus.downloading => l10n.downloadsStatusDownloading,
    DownloadJobStatus.queued => l10n.downloadsStatusQueued,
    DownloadJobStatus.paused => l10n.downloadsStatusPaused,
    DownloadJobStatus.failed => l10n.downloadsStatusFailed,
    DownloadJobStatus.completed => l10n.downloadsStatusCompleted,
  };
}
