import 'dart:io';

import 'package:concept_nhv/l10n/app_localizations.dart';
import 'package:concept_nhv/models/download_list_item_snapshot.dart';
import 'package:concept_nhv/widgets/downloads/completed_comic_sheet.dart';
import 'package:concept_nhv/widgets/fallback_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One kept comic in the Downloads grid.
class CompletedGridCell extends StatelessWidget {
  const CompletedGridCell({
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
          showCompletedSheetFor(context, item, isMutating);
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
// (used by both list-view DownloadItemCard and grid-view CompletedGridCell)
// ---------------------------------------------------------------------------
