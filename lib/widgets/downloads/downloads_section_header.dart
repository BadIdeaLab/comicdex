import 'package:concept_nhv/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// The 'Downloading' / 'Downloaded' divider, with the latter's controls.
class DownloadsSectionHeader extends StatelessWidget {
  const DownloadsSectionHeader({
    super.key,
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
