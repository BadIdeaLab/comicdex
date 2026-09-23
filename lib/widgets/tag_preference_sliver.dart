import 'package:concept_nhv/models/local_tag_catalog_entry.dart';
import 'package:concept_nhv/models/tag_catalog_type.dart';
import 'package:concept_nhv/models/tag_preference_entry.dart';
import 'package:concept_nhv/services/tag_display_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Ranked tag preferences, grouped by tag type (P78).
///
/// Each row is a chip with a proportional bar behind it: one measure, one
/// series, so one hue — the bar carries magnitude, the text stays in normal
/// ink rather than wearing the bar's color.
class TagPreferenceSliver extends StatefulWidget {
  const TagPreferenceSliver({
    super.key,
    required this.preferences,
    required this.sort,
    required this.onSortChanged,
    required this.onTagTap,
    required this.onTagLongPress,
    this.collapsedCount = 10,
  });

  final Map<TagCatalogType, List<TagPreferenceEntry>> preferences;
  final TagPreferenceSort sort;
  final ValueChanged<TagPreferenceSort> onSortChanged;
  final void Function(LocalTagCatalogEntry tag, String displayName) onTagTap;
  final void Function(LocalTagCatalogEntry tag, String displayName)
  onTagLongPress;

  /// Entries shown per section before "Show more".
  final int collapsedCount;

  @override
  State<TagPreferenceSliver> createState() => _TagPreferenceSliverState();
}

class _TagPreferenceSliverState extends State<TagPreferenceSliver> {
  final Set<TagCatalogType> _expanded = <TagCatalogType>{};

  static const Map<TagCatalogType, String> _sectionTitles =
      <TagCatalogType, String>{
        TagCatalogType.tag: 'Tags',
        TagCatalogType.artist: 'Artists',
        TagCatalogType.parody: 'Parodies',
        TagCatalogType.character: 'Characters',
      };

  @override
  Widget build(BuildContext context) {
    final sections = widget.preferences.entries
        .where((entry) => entry.value.isNotEmpty)
        .toList(growable: false);

    return SliverList.list(
      children: <Widget>[
        const SizedBox(height: 24),
        _buildHeader(context),
        if (sections.isEmpty)
          _buildEmptyState(context)
        else
          for (final section in sections)
            _buildSection(context, section.key, section.value),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 12, 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text('Tag Preferences', style: theme.textTheme.titleMedium),
          ),
          SegmentedButton<TagPreferenceSort>(
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: const <ButtonSegment<TagPreferenceSort>>[
              ButtonSegment<TagPreferenceSort>(
                value: TagPreferenceSort.count,
                label: Text('Most kept'),
              ),
              ButtonSegment<TagPreferenceSort>(
                value: TagPreferenceSort.affinity,
                label: Text('Most distinctive'),
              ),
            ],
            selected: <TagPreferenceSort>{widget.sort},
            onSelectionChanged: (selection) =>
                widget.onSortChanged(selection.first),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        'No tag data yet. Sync favorites from Settings, or download a few '
        'comics, and preferences will build up here.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    TagCatalogType type,
    List<TagPreferenceEntry> entries,
  ) {
    final theme = Theme.of(context);
    final isExpanded = _expanded.contains(type);
    final visible = isExpanded
        ? entries
        : entries.take(widget.collapsedCount).toList(growable: false);
    // One scale per section: a section's own leader defines a full bar, so
    // sections with smaller numbers stay readable instead of flat.
    final maxValue = _sortValue(entries.first);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Text(
            _sectionTitles[type] ?? type.apiValue,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        for (final entry in visible)
          _TagPreferenceRow(
            entry: entry,
            fraction: maxValue <= 0 ? 0 : _sortValue(entry) / maxValue,
            onTap: () => widget.onTagTap(entry.tag, _displayName(entry)),
            onLongPress: () =>
                widget.onTagLongPress(entry.tag, _displayName(entry)),
          ),
        if (entries.length > widget.collapsedCount)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: TextButton(
              onPressed: () => setState(() {
                if (isExpanded) {
                  _expanded.remove(type);
                } else {
                  _expanded.add(type);
                }
              }),
              child: Text(
                isExpanded
                    ? 'Show less'
                    : 'Show ${entries.length - widget.collapsedCount} more',
              ),
            ),
          ),
      ],
    );
  }

  double _sortValue(TagPreferenceEntry entry) {
    return widget.sort == TagPreferenceSort.count
        ? entry.comicCount.toDouble()
        : entry.affinity;
  }

  String _displayName(TagPreferenceEntry entry) {
    return context.read<TagDisplayService>().displayName(
      entry.tag.slug,
      entry.tag.name,
    );
  }
}

class _TagPreferenceRow extends StatelessWidget {
  const _TagPreferenceRow({
    required this.entry,
    required this.fraction,
    required this.onTap,
    required this.onLongPress,
  });

  final TagPreferenceEntry entry;
  final double fraction;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = context.read<TagDisplayService>().displayName(
      entry.tag.slug,
      entry.tag.name,
    );
    const radius = BorderRadius.all(Radius.circular(10));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Material(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: fraction.clamp(0.02, 1.0),
                  child: ColoredBox(
                    color: theme.colorScheme.primary.withValues(alpha: 0.28),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        displayName,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.comicCount}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
