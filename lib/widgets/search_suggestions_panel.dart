import 'package:concept_nhv/application/home/home_shell_controller.dart';
import 'package:concept_nhv/models/search_history_entry.dart';
import 'package:concept_nhv/models/tag_catalog_type.dart';
import 'package:concept_nhv/models/tag_type_l10n.dart';
import 'package:concept_nhv/state/tag_catalog_browser_model.dart';
import 'package:concept_nhv/services/tag_display_service.dart';
import 'package:concept_nhv/storage/search_history_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SearchSuggestionsPanel extends StatefulWidget {
  const SearchSuggestionsPanel({super.key, required this.onHistorySelected});

  final ValueChanged<String> onHistorySelected;

  @override
  State<SearchSuggestionsPanel> createState() => _SearchSuggestionsPanelState();
}

class _SearchSuggestionsPanelState extends State<SearchSuggestionsPanel> {
  late Future<List<SearchHistoryEntry>> _historyFuture;
  final TextEditingController _tagFilterController = TextEditingController();
  String _tagFilterQuery = '';

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadHistory();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<TagCatalogBrowserModel>().ensureLoaded();
    });
  }

  @override
  void dispose() {
    _tagFilterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: <Widget>[
          const TabBar(
            tabs: <Widget>[
              Tab(text: 'History'),
              Tab(text: 'Tags'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                _buildHistoryTab(context),
                _buildTagsTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(BuildContext context) {
    return FutureBuilder<List<SearchHistoryEntry>>(
      future: _historyFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final entries = snapshot.requireData;
        if (entries.isEmpty) {
          return const Center(child: Text('No search history'));
        }

        return ListView.builder(
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return ListTile(
              titleAlignment: ListTileTitleAlignment.center,
              title: Text(entry.query),
              trailing: Text(entry.createdAt.toString()),
              onTap: () => widget.onHistorySelected(entry.query),
              onLongPress: () async {
                await context.read<SearchHistoryRepository>().remove(
                  entry.query,
                );
                if (!mounted) {
                  return;
                }
                setState(() {
                  _historyFuture = _loadHistory();
                });
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTagsTab(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return Consumer<TagCatalogBrowserModel>(
      builder: (context, model, child) {
        final tagDisplayService = context.read<TagDisplayService>();
        final results = model.results;
        return Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: SegmentedButton<TagCatalogType>(
                segments: TagCatalogType.values.map((type) {
                  return ButtonSegment<TagCatalogType>(
                    value: type,
                    label: Text(
                      TagTypeL10n.localizedName(type.apiValue, locale),
                    ),
                  );
                }).toList(),
                selected: <TagCatalogType>{model.type},
                onSelectionChanged: (selection) {
                  model.setType(selection.first);
                  _clearTagFilter(model);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: TextField(
                controller: _tagFilterController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _tagFilterQuery.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.clear),
                          onPressed: () => _clearTagFilter(model),
                        ),
                  hintText: 'Search this category',
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.search,
                onChanged: (value) {
                  setState(() {
                    _tagFilterQuery = value;
                  });
                  model.setQuery(value);
                },
              ),
            ),
            if (model.selectedQueries.isNotEmpty)
              _SelectedTagSummary(
                selectedQueries: model.selectedQueries,
                onRemove: model.removeSelection,
                onClear: model.clearSelection,
              ),
            if (model.selectedQueries.isNotEmpty) const SizedBox(height: 8),
            if (results.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    _tagFilterQuery.trim().isEmpty
                        ? 'No tags in this category'
                        : 'No tags match "${_tagFilterQuery.trim()}"',
                  ),
                ),
              )
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  children: <Widget>[
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: results.map((item) {
                        final displayName = tagDisplayService.displayName(
                          item.slug,
                          item.name,
                        );
                        return FilterChip(
                          label: Text('$displayName (${item.count})'),
                          selected: model.isSelected(item),
                          onSelected: (_) => model.toggleSelection(item),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: model.selectedQueries.isEmpty
                      ? null
                      : () async {
                          final controller = context
                              .read<HomeShellController>();
                          final selectedQueries = List<String>.of(
                            model.selectedQueries,
                          );
                          model.clearSelection();
                          await controller.submitTagSearch(selectedQueries);
                        },
                  icon: const Icon(Icons.search),
                  label: Text(
                    model.selectedQueries.isEmpty
                        ? 'Select tags to search'
                        : 'Search ${model.selectedQueries.length} tags',
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<List<SearchHistoryEntry>> _loadHistory() {
    return context.read<SearchHistoryRepository>().load();
  }

  void _clearTagFilter(TagCatalogBrowserModel model) {
    if (_tagFilterQuery.isEmpty && _tagFilterController.text.isEmpty) {
      return;
    }
    setState(() {
      _tagFilterQuery = '';
      _tagFilterController.clear();
    });
    model.setQuery('');
  }
}

class _SelectedTagSummary extends StatelessWidget {
  const _SelectedTagSummary({
    required this.selectedQueries,
    required this.onRemove,
    required this.onClear,
  });

  final List<String> selectedQueries;
  final ValueChanged<String> onRemove;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Text(
            'Selected ${selectedQueries.length}',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: selectedQueries.length,
              separatorBuilder: (context, index) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final query = selectedQueries[index];
                return Center(
                  child: InputChip(
                    label: Text(query),
                    onDeleted: () => onRemove(query),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              },
            ),
          ),
          TextButton(onPressed: onClear, child: const Text('Clear')),
        ],
      ),
    );
  }
}
