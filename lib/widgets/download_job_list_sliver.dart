import 'dart:math';

import 'package:concept_nhv/application/downloads/completed_page_window.dart';
import 'package:concept_nhv/application/downloads/download_item_filter.dart';
import 'package:concept_nhv/application/downloads/weighted_random_pick.dart';
import 'package:concept_nhv/l10n/app_localizations.dart';
import 'package:concept_nhv/models/download_list_item_snapshot.dart';
import 'package:concept_nhv/services/tag_display_service.dart';
import 'package:concept_nhv/state/download_manager_model.dart';
import 'package:concept_nhv/widgets/downloads/completed_grid_cell.dart';
import 'package:concept_nhv/widgets/downloads/download_item_card.dart';
import 'package:concept_nhv/widgets/downloads/downloads_section_header.dart';
import 'package:concept_nhv/widgets/page_jump_bar.dart';
import 'package:flutter/material.dart';
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
        final filteredItems = filterDownloadItems(
          model.sortedDownloadItems,
          query: query,
          tagIds: widget.filterTagIds,
          tagDisplayService: context.read<TagDisplayService>(),
        );
        final activeItems = filteredItems
            .where((item) => !item.isCompletedCard)
            .toList(growable: false);
        final completedItems = filteredItems
            .where((item) => item.isCompletedCard)
            .toList(growable: false);

        if (filteredItems.isEmpty) {
          // Three different empty states, and which one it is decides whether
          // the user should go download something or go clear a filter.
          final String message;
          if (query.isNotEmpty) {
            message = l10n.downloadsEmptyForQuery(widget.searchQuery.trim());
          } else if (widget.filterTagIds.isNotEmpty) {
            message = l10n.downloadsEmptyForTags;
          } else {
            message = l10n.downloadsEmpty;
          }
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text(message)),
          );
        }

        final window = CompletedPageWindow.of(
          itemCount: completedItems.length,
          anchorPage: model.completedAnchorPage,
          currentPage: model.completedPage,
          pageSize: DownloadManagerModel.completedPageSize,
        );
        final pagedCompletedItems = window.slice(completedItems);

        final slivers = <Widget>[];

        if (activeItems.isNotEmpty) {
          slivers.add(
            SliverToBoxAdapter(
              child: DownloadsSectionHeader(title: l10n.downloadsSectionActive),
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
              child: DownloadsSectionHeader(
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

          if (window.showPageBar) {
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
                        currentPage: window.anchorPage,
                        totalPages: window.totalPages,
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
                      window.totalPages,
                    );
                    final item = pagedCompletedItems[index];
                    return CompletedGridCell(
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
                    window.totalPages,
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
    return DownloadItemCard(
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
