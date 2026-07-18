import 'dart:io';
import 'dart:math';

import 'package:concept_nhv/application/home/home_shell_controller.dart';
import 'package:concept_nhv/application/tags/load_comic_meta_use_case.dart';
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
  });

  final String searchQuery;

  /// Called when the user taps a completed download card to open the reader.
  final ValueChanged<String> onOpenOfflineReader;

  @override
  State<DownloadJobListSliver> createState() => _DownloadJobListSliverState();
}

class _DownloadJobListSliverState extends State<DownloadJobListSliver> {
  String? _expandedComicId;
  bool _completedViewIsGrid = false;
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
        final query = widget.searchQuery.trim().toLowerCase();
        final tagDisplayService = context.read<TagDisplayService>();
        final filteredItems = model.sortedDownloadItems.where((item) {
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
        }).toList(growable: false);
        final activeItems = filteredItems
            .where((item) => !item.isCompletedCard)
            .toList(growable: false);
        final completedItems = filteredItems
            .where((item) => item.isCompletedCard)
            .toList(growable: false);

        if (filteredItems.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                widget.searchQuery.trim().isEmpty
                    ? 'No downloads yet'
                    : 'No downloads match "${widget.searchQuery.trim()}"',
              ),
            ),
          );
        }

        // Pagination for completed items.
        final pageSize = DownloadManagerModel.completedPageSize;
        final totalCompletedPages =
            completedItems.isEmpty ? 1 : ((completedItems.length + pageSize - 1) ~/ pageSize);
        final currentPage = model.completedPage.clamp(1, totalCompletedPages);
        final pageStart = (currentPage - 1) * pageSize;
        final pageEnd = (pageStart + pageSize).clamp(0, completedItems.length);
        final pagedCompletedItems = completedItems.sublist(pageStart, pageEnd);
        final showPageBar = completedItems.length > pageSize;

        final slivers = <Widget>[];

        if (activeItems.isNotEmpty) {
          slivers.add(const SliverToBoxAdapter(
            child: _DownloadsSectionHeader(title: 'Active Downloads'),
          ));
          slivers.add(SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildItemCard(model, activeItems[index]),
              childCount: activeItems.length,
            ),
          ));
        }

        if (completedItems.isNotEmpty) {
          slivers.add(SliverToBoxAdapter(
            child: _DownloadsSectionHeader(
              title: 'Completed Downloads',
              isGridView: _completedViewIsGrid,
              onViewToggle: () =>
                  setState(() => _completedViewIsGrid = !_completedViewIsGrid),
              isRepairingAll: _isRepairingAll,
              repairProgressCurrent: _repairProgressCurrent,
              repairProgressTotal: _repairProgressTotal,
              onRandomCompleted: () => _openRandomCompleted(completedItems),
              onRepairAll: () => _handleRepairAll(model),
            ),
          ));

          if (showPageBar) {
            slivers.add(SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    PageJumpBar(
                      currentPage: currentPage,
                      totalPages: totalCompletedPages,
                      onJump: (page) async {
                        model.setCompletedPage(page);
                      },
                    ),
                  ],
                ),
              ),
            ));
          }

          if (_completedViewIsGrid) {
            slivers.add(SliverPadding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 150,
                  mainAxisExtent: 220,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = pagedCompletedItems[index];
                    return _CompletedGridCell(
                      key: ValueKey<String>(item.comicId),
                      item: item,
                      isMutating: model.isMutating(item.comicId),
                      onTap: () => widget.onOpenOfflineReader(item.comicId),
                    );
                  },
                  childCount: pagedCompletedItems.length,
                ),
              ),
            ));
          } else {
            slivers.add(SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _buildItemCard(model, pagedCompletedItems[index]),
                childCount: pagedCompletedItems.length,
              ),
            ));
          }
        }

        return SliverMainAxisGroup(slivers: slivers);
      },
    );
  }

  void _openRandomCompleted(List<DownloadListItemSnapshot> completedItems) {
    if (completedItems.isEmpty) {
      return;
    }
    final item = completedItems[_random.nextInt(completedItems.length)];
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
          _expandedComicId =
              _expandedComicId == item.comicId ? null : item.comicId;
        });
      },
      onOpenOfflineReader: () => widget.onOpenOfflineReader(item.comicId),
    );
  }

  Future<void> _handleRepairAll(DownloadManagerModel model) async {
    if (_isRepairingAll) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Repair all completed downloads?'),
          content: const Text(
            'This scans every completed download for missing pages or a missing '
            'cover and re-downloads anything broken. It may take a while and '
            'will use network data.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Repair All'),
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
        (0, 0, _) => 'All ${result.totalCount} downloads are intact',
        (_, 0, _) =>
          'Repaired ${result.repairedCount} of ${result.totalCount} downloads',
        (_, _, true) =>
          'Stopped after repeated failures — repaired ${result.repairedCount}, '
              'failed ${result.failedCount} (of ${result.totalCount} total)',
        _ =>
          'Repaired ${result.repairedCount}, failed ${result.failedCount}, '
              'of ${result.totalCount} downloads',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Repair all failed: $error')),
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
              tooltip: 'Open a random completed download',
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
              tooltip: 'Repair all completed downloads',
              onPressed: isRepairingAll ? null : onRepairAll,
              iconSize: 20,
              visualDensity: VisualDensity.compact,
            ),
          if (onViewToggle != null)
            IconButton(
              icon: Icon(isGridView ? Icons.list : Icons.grid_view),
              tooltip: isGridView ? 'List view' : 'Grid view',
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
                    '${item.pageCount ?? item.totalPages}p',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
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
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
          side: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
        icon: const Icon(Icons.delete_outline),
        label: const Text('Delete Download'),
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
        label: const Text('Reload'),
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
        label: const Text('Repair'),
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
  final shouldDelete = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Delete downloaded comic?'),
        content: const Text(
          'This deletes the saved download, cover, offline snapshot, and the completed job record.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirm'),
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
    successMessage: 'Downloaded comic deleted',
    action: () => context.read<DownloadManagerModel>().deleteJob(item.comicId),
  );
}

Future<void> _confirmAndReloadCompleted(
  BuildContext context,
  DownloadListItemSnapshot item,
) async {
  final shouldReload = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Reload download?'),
        content: const Text(
          'This deletes the saved pages and re-downloads the comic from scratch. '
          'Reading history and metadata are preserved.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reload'),
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
    successMessage: 'Reload queued',
    action: () =>
        context.read<DownloadManagerModel>().reloadCompleted(item.comicId),
  );
}

Future<void> _runRepairCompleted(
  BuildContext context,
  DownloadListItemSnapshot item,
) async {
  await _runAction(
    context,
    successMessage: 'Repair queued',
    noOpMessage: 'All pages and cover are intact — nothing to repair',
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
    final message =
        (!changed && noOpMessage != null) ? noOpMessage : successMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$error')),
    );
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
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                    ),
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
    final model = context.read<DownloadManagerModel>();
    return switch (item.status) {
      DownloadJobStatus.downloading => <Widget>[
        FilledButton.tonal(
          onPressed: isMutating
              ? null
              : () => _runAction(
                  context,
                  successMessage: 'Download paused',
                  action: () => model.pause(item.comicId),
                ),
          child: const Text('Pause'),
        ),
      ],
      DownloadJobStatus.queued => <Widget>[
        FilledButton.tonal(
          onPressed: isMutating
              ? null
              : () => _runAction(
                  context,
                  successMessage: 'Download paused',
                  action: () => model.pause(item.comicId),
                ),
          child: const Text('Pause'),
        ),
      ],
      DownloadJobStatus.paused => <Widget>[
        FilledButton(
          onPressed: isMutating
              ? null
              : () => _runAction(
                  context,
                  successMessage: 'Download resumed',
                  action: () => model.resume(item.comicId),
                ),
          child: const Text('Resume'),
        ),
        OutlinedButton(
          onPressed: isMutating
              ? null
              : () => _confirmAndDelete(
                  context,
                  title: 'Remove download job?',
                  message:
                      'This removes the download job and deletes any partial files already saved.',
                  successMessage: 'Download job removed',
                ),
          child: const Text('Remove'),
        ),
      ],
      DownloadJobStatus.failed => <Widget>[
        FilledButton(
          onPressed: isMutating
              ? null
              : () => _runAction(
                  context,
                  successMessage: 'Download retried',
                  action: () => model.retry(item.comicId),
                ),
          child: const Text('Retry'),
        ),
        OutlinedButton(
          onPressed: isMutating
              ? null
              : () => _confirmAndDelete(
                  context,
                  title: 'Remove failed download?',
                  message:
                      'This removes the failed job and deletes any partial files already saved.',
                  successMessage: 'Failed download removed',
                ),
          child: const Text('Remove'),
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
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Confirm'),
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
        Text(_statusLabel(item.status)),
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
        const Text('Completed'),
        const SizedBox(height: 8),
        Text('$pageCount page${pageCount == 1 ? '' : 's'}'),
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

String _statusLabel(DownloadJobStatus status) {
  return switch (status) {
    DownloadJobStatus.downloading => 'Downloading',
    DownloadJobStatus.queued => 'Queued',
    DownloadJobStatus.paused => 'Paused',
    DownloadJobStatus.failed => 'Failed',
    DownloadJobStatus.completed => 'Completed',
  };
}
