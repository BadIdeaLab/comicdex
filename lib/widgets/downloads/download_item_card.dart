import 'dart:io';

import 'package:concept_nhv/l10n/app_localizations.dart';
import 'package:concept_nhv/models/download_job_status.dart';
import 'package:concept_nhv/models/download_list_item_snapshot.dart';
import 'package:concept_nhv/state/download_manager_model.dart';
import 'package:concept_nhv/widgets/downloads/completed_comic_sheet.dart';
import 'package:concept_nhv/widgets/downloads/download_action_runner.dart';
import 'package:concept_nhv/widgets/fallback_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// One row of the Downloads list: a running job or a kept comic.
class DownloadItemCard extends StatelessWidget {
  const DownloadItemCard({
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
            showCompletedSheetFor(context, item, isMutating);
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
              : () => runDownloadAction(
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
              : () => runDownloadAction(
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
              : () => runDownloadAction(
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
              : () => runDownloadAction(
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

    await runDownloadAction(
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
