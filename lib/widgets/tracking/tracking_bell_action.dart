import 'package:concept_nhv/l10n/app_localizations.dart';
import 'package:concept_nhv/state/tracking_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// The bell in the app bar, shown only when a tracked artist has published.
///
/// Absent rather than greyed out when there is nothing: it sits inside
/// `SearchAnchor.bar`'s trailing row, already occupied by refresh and
/// settings, and a third permanent icon takes a visible bite out of the
/// search field at phone widths. Appearing only when it has something to say
/// also makes it a notification rather than a second entrance — the permanent
/// way in is the card on the Collections tab.
class TrackingBellAction extends StatelessWidget {
  const TrackingBellAction({super.key});

  @override
  Widget build(BuildContext context) {
    // Nullable: the app has to build with no tracking wired up at all, the
    // same way the preference badge does.
    final count = context.watch<TrackingModel?>()?.artistsWithNewWork ?? 0;
    if (count == 0) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    return IconButton.filledTonal(
      tooltip: l10n.trackingBellTooltip,
      onPressed: () => context.push('/tracking'),
      icon: Badge.count(
        count: count,
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}
