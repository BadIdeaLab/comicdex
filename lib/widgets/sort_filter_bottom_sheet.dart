import 'package:concept_nhv/models/popular_sort_type.dart';
import 'package:concept_nhv/state/comic_feed_model.dart';
import 'package:concept_nhv/widgets/glass_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// A modal bottom sheet for configuring the home feed's sort order
/// and persistent tag filters.
///
/// Changes are applied immediately when the user taps "Apply".
class SortFilterBottomSheet extends StatefulWidget {
  const SortFilterBottomSheet({super.key});

  /// Shows the sheet and returns whether the user applied changes.
  static Future<bool> show(BuildContext context) async {
    final result = await showGlassModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ComicFeedModel>(),
        child: const SortFilterBottomSheet(),
      ),
    );
    return result ?? false;
  }

  @override
  State<SortFilterBottomSheet> createState() => _SortFilterBottomSheetState();
}

class _SortFilterBottomSheetState extends State<SortFilterBottomSheet> {
  late PopularSortType? _selectedSort;
  late List<String> _tagFilters;
  final TextEditingController _tagInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final feedModel = context.read<ComicFeedModel>();
    _selectedSort = feedModel.sortByPopularType;
    _tagFilters = List<String>.from(feedModel.tagFilters);
  }

  @override
  void dispose() {
    _tagInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Drag handle
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Sort & Filter',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Divider(height: 1),
          // Scrollable body
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.7,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildSortSection(context),
                  const SizedBox(height: 20),
                  _buildTagFilterSection(context),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          // Action buttons
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _handleReset,
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _handleApply,
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Sort by',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: <Widget>[
            _SortChip(
              label: 'Latest',
              selected: _selectedSort == null,
              onSelected: (_) => setState(() => _selectedSort = null),
            ),
            for (final type in PopularSortType.values)
              _SortChip(
                label: type.label,
                selected: _selectedSort == type,
                onSelected: (_) => setState(() => _selectedSort = type),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTagFilterSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Tag filters',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tags are combined with the current search. Format: type:name (e.g. tag:full-color)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        // Tag input
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _tagInputController,
                decoration: const InputDecoration(
                  hintText: 'e.g. tag:full-color',
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: _addTag,
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              icon: const Icon(Icons.add),
              onPressed: () => _addTag(_tagInputController.text),
              tooltip: 'Add tag filter',
            ),
          ],
        ),
        // Active tag chips
        if (_tagFilters.isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _tagFilters.map((tag) {
              return Chip(
                label: Text(tag),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => setState(() => _tagFilters.remove(tag)),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  void _addTag(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || _tagFilters.contains(trimmed)) return;
    setState(() {
      _tagFilters.add(trimmed);
      _tagInputController.clear();
    });
  }

  void _handleReset() {
    setState(() {
      _selectedSort = null;
      _tagFilters.clear();
      _tagInputController.clear();
    });
  }

  void _handleApply() {
    Navigator.of(context).pop(true);
    final feedModel = context.read<ComicFeedModel>();
    feedModel.setSortType(_selectedSort);
    feedModel.setTagFilters(_tagFilters);
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: true,
    );
  }
}
