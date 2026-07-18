import 'package:concept_nhv/application/library/comic_card_action_coordinator.dart';
import 'package:concept_nhv/models/collection_type.dart';
import 'package:concept_nhv/models/comic_card_data.dart';
import 'package:concept_nhv/models/download_job_status.dart';
import 'package:concept_nhv/state/comic_reader_model.dart';
import 'package:concept_nhv/state/download_manager_model.dart';
import 'package:concept_nhv/state/favorite_sync_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'comic_tag_bottom_sheet.dart';
import 'fallback_cached_network_image.dart';

class ComicCard extends StatelessWidget {
  const ComicCard({
    super.key,
    required this.comic,
    this.collectionType,
    this.onCollectionChanged,
    this.onTagSelected,
    this.isSelected = false,
    this.onSelectionToggle,
  });

  final ComicCardData comic;
  final CollectionType? collectionType;
  final VoidCallback? onCollectionChanged;

  /// Called when user taps a tag inside the tag sheet.
  /// Receives the selected search queries (e.g. ["tag:full-color"]).
  final ValueChanged<List<String>>? onTagSelected;

  /// When non-null, the card is in selection mode: tap toggles selection,
  /// long press is disabled.
  final bool isSelected;
  final VoidCallback? onSelectionToggle;

  @override
  Widget build(BuildContext context) {
    final inSelectionMode = onSelectionToggle != null;
    return Column(
      children: <Widget>[
        Expanded(
          child: Card(
            clipBehavior: Clip.hardEdge,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                InkWell(
                  splashColor: Colors.blue.withAlpha(30),
                  onTap: inSelectionMode
                      ? onSelectionToggle
                      : () async {
                          await context
                              .read<ComicCardActionCoordinator>()
                              .openComic(comic);
                          if (!context.mounted) return;
                          await context.push(
                            Uri(
                              path: '/third',
                              queryParameters: <String, String>{'id': comic.id},
                            ).toString(),
                          );
                          if (!context.mounted) return;
                          context.read<ComicReaderModel>().clearComic();
                          await context.read<DownloadManagerModel>().refresh();
                        },
                  onLongPress: inSelectionMode ? null : () => _showTagSheet(context),
                  child: FallbackCachedNetworkImage(
                    url: comic.thumbnailUrl,
                    width: comic.thumbnailWidth,
                    height: comic.thumbnailHeight,
                  ),
                ),
                if (isSelected)
                  IgnorePointer(
                    child: Container(color: Theme.of(context).colorScheme.primary.withAlpha(64)),
                  ),
                if (inSelectionMode)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: IgnorePointer(
                      child: Icon(
                        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.white,
                        shadows: const <Shadow>[
                          Shadow(blurRadius: 4, color: Colors.black54),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Consumer<DownloadManagerModel>(
          builder: (context, downloadManagerModel, _) {
            final downloadJob = downloadManagerModel.jobForComic(comic.id);
            final icon = _cardStatusIcon(downloadJob?.status);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Text(
                    comic.title,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                if (icon != null) ...<Widget>[
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(icon, size: 18),
                  ),
                ],
              ],
            );
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.add_to_photos_outlined),
              onPressed: () => _saveToCollection(context, CollectionType.next),
            ),
            Text('${comic.pages}p'),
            Consumer<FavoriteSyncModel>(
              builder: (context, favoriteModel, child) {
                final isFavorite = favoriteModel.isFavorite(comic.id);
                final isMutating = favoriteModel.isMutating(comic.id);
                return IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_outline,
                  ),
                  onPressed: isMutating ? null : () => _toggleFavorite(context),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showTagSheet(BuildContext context) async {
    HapticFeedback.selectionClick();
    final downloadManagerModel = context.read<DownloadManagerModel>();
    final downloadJob = downloadManagerModel.jobForComic(comic.id);

    await ComicTagBottomSheet.show(
      context: context,
      title: comic.title,
      tags: comic.tags,
      comicId: comic.id,
      comicUploadDate: comic.uploadDate,
      loadMeta: () => context.read<ComicCardActionCoordinator>().loadComicMeta(comic),
      onSearchSelected: (queries) => onTagSelected?.call(queries),
      downloadSlot: _buildDownloadSlot(
        context,
        status: downloadJob?.status,
        isMutating: downloadManagerModel.isMutating(comic.id),
      ),
      actionSlot: collectionType != null
          ? _buildRemoveFromCollectionButton(context)
          : null,
    );
  }

  /// Builds the download status tile or "Download" button for the sheet.
  Widget _buildDownloadSlot(
    BuildContext context, {
    required DownloadJobStatus? status,
    required bool isMutating,
  }) {
    if (status == null) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: isMutating ? null : () => _enqueueDownload(context),
          icon: isMutating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download_outlined),
          label: Text(isMutating ? 'Starting download...' : 'Download'),
        ),
      );
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(_downloadStatusIcon(status)),
      title: Text(_downloadStatusLabel(status)),
      subtitle: const Text('Manage in Downloads tab'),
    );
  }

  /// Builds the remove-from-collection button for the sheet.
  Widget _buildRemoveFromCollectionButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
          side: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
        icon: const Icon(Icons.remove_circle_outline),
        label: Text('Remove from ${collectionType!.displayName}'),
        onPressed: () {
          Navigator.of(context, rootNavigator: true).pop();
          _removeFromCollection(context);
        },
      ),
    );
  }

  Future<void> _removeFromCollection(BuildContext context) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Remove this comic from ${collectionType!.displayName}?'),
          content: Text(
            "Careful! You can't undo this action. You are removing: ${comic.title}",
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('REMOVE'),
            ),
          ],
        );
      },
    );

    if (shouldRemove != true || !context.mounted) return;

    final result = await context.read<ComicCardActionCoordinator>().removeFromCollection(
      comic: comic,
      collectionType: collectionType!,
    );
    if (!context.mounted) return;
    if (result.triggerHaptic) HapticFeedback.lightImpact();
    if (result.message != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message!)));
    }
    if (result.shouldRefreshCollection) onCollectionChanged?.call();
  }

  Future<void> _saveToCollection(
    BuildContext context,
    CollectionType targetCollection,
  ) async {
    final result = await context.read<ComicCardActionCoordinator>().saveToCollection(
      comic: comic,
      targetCollection: targetCollection,
    );
    if (!context.mounted) return;
    if (result.triggerHaptic) HapticFeedback.lightImpact();
    if (result.message != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message!)));
    }
  }

  Future<void> _toggleFavorite(BuildContext context) async {
    final result = await context.read<ComicCardActionCoordinator>().toggleFavorite(
      comic: comic,
      collectionType: collectionType,
    );
    if (!context.mounted) return;
    if (result.triggerHaptic) HapticFeedback.lightImpact();
    if (result.message != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message!)));
    }
    if (result.shouldRefreshCollection) onCollectionChanged?.call();
  }

  Future<void> _enqueueDownload(BuildContext context) async {
    final result = await context.read<ComicCardActionCoordinator>().enqueueDownload(comic);
    if (!context.mounted) return;
    if (result.success) Navigator.of(context, rootNavigator: true).pop();
    if (result.triggerHaptic) HapticFeedback.lightImpact();
    if (result.message != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message!)));
    }
  }

  IconData? _cardStatusIcon(DownloadJobStatus? status) {
    return switch (status) {
      DownloadJobStatus.downloading => Icons.downloading,
      DownloadJobStatus.completed => Icons.download_done,
      _ => null,
    };
  }

  IconData _downloadStatusIcon(DownloadJobStatus status) {
    return switch (status) {
      DownloadJobStatus.queued => Icons.schedule,
      DownloadJobStatus.downloading => Icons.downloading,
      DownloadJobStatus.paused => Icons.pause_circle_outline,
      DownloadJobStatus.failed => Icons.error_outline,
      DownloadJobStatus.completed => Icons.download_done,
    };
  }

  String _downloadStatusLabel(DownloadJobStatus status) {
    return switch (status) {
      DownloadJobStatus.queued => 'Queued',
      DownloadJobStatus.downloading => 'Downloading',
      DownloadJobStatus.paused => 'Paused',
      DownloadJobStatus.failed => 'Failed',
      DownloadJobStatus.completed => 'Downloaded',
    };
  }
}
