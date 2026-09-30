import 'package:concept_nhv/l10n/app_localizations.dart';
import 'package:concept_nhv/state/tracking_model.dart';
import 'package:concept_nhv/widgets/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// The permanent way into tracking, below the collection entries.
///
/// Always present, unlike the bell: this is where the list is managed and
/// where someone who has never tracked anything finds out that they can.
/// The count on the right is the same one the bell carries.
class TrackedArtistsCard extends StatelessWidget {
  const TrackedArtistsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<TrackingModel?>();
    if (model == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final withNewWork = model.artistsWithNewWork;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GlassContainer.card(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.push('/tracking'),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 48,
                  height: 64,
                  child: Icon(
                    Icons.notifications_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        l10n.trackingEntryCard,
                        style: theme.textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        withNewWork > 0
                            ? l10n.trackingNewWorkBadge(withNewWork)
                            : l10n.trackingEntrySubtitle(model.artists.length),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: withNewWork > 0
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (withNewWork > 0) Badge.count(count: withNewWork),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
