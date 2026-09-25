import 'package:concept_nhv/models/tag_preference_entry.dart';
import 'package:concept_nhv/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// A section title with an optional action link and a sort toggle.
///
/// Wraps to two rows on narrow screens. Kept as one widget because the
/// single-row version overflowed on a phone: the toggle claimed its
/// intrinsic width, drew over the title and the action link, and swallowed
/// taps meant for the link.
class SortSectionHeader extends StatelessWidget {
  const SortSectionHeader({
    super.key,
    required this.title,
    required this.sort,
    required this.onSortChanged,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final TagPreferenceSort sort;
  final ValueChanged<TagPreferenceSort> onSortChanged;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Below this the toggle gets its own row. Two labels plus the title do not
  /// fit in a phone's width, and the exact breakpoint matters less than
  /// never overlapping.
  static const double _singleRowMinWidth = 560;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final titleRow = Row(
      children: <Widget>[
        Flexible(
          child: Text(
            title,
            style: theme.textTheme.titleMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );

    final toggle = SegmentedButton<TagPreferenceSort>(
      showSelectedIcon: false,
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
      segments: <ButtonSegment<TagPreferenceSort>>[
        ButtonSegment<TagPreferenceSort>(
          value: TagPreferenceSort.count,
          label: Text(l10n.sortMostKept),
        ),
        ButtonSegment<TagPreferenceSort>(
          value: TagPreferenceSort.affinity,
          label: Text(l10n.sortMostDistinctive),
        ),
      ],
      selected: <TagPreferenceSort>{sort},
      onSelectionChanged: (selection) => onSortChanged(selection.first),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _singleRowMinWidth) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 12, 8),
            child: Row(
              children: <Widget>[
                Expanded(child: titleRow),
                toggle,
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              titleRow,
              const SizedBox(height: 4),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: toggle,
              ),
            ],
          ),
        );
      },
    );
  }
}
