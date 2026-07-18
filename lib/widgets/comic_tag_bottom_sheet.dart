import 'package:concept_nhv/models/comic_tag.dart';
import 'package:concept_nhv/models/tag_type_l10n.dart';
import 'package:concept_nhv/services/tag_display_service.dart';
import 'package:concept_nhv/state/blocked_tags_model.dart';
import 'package:concept_nhv/widgets/glass_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// A draggable bottom sheet that displays grouped, selectable tags and
/// triggers a multi-tag search when the user confirms their selection.
///
/// Callers may pass optional [downloadSlot] and [actionSlot] widgets to
/// compose context-specific UI (e.g. download status, delete button) into
/// the bottom action area without coupling this widget to any domain model.
class ComicTagBottomSheet extends StatefulWidget {
  const ComicTagBottomSheet({
    super.key,
    required this.title,
    required this.initialTags,
    required this.onSearchSelected,
    this.comicId,
    this.comicUploadDate,
    this.loadMeta,
    this.downloadSlot,
    this.actionSlot,
  });

  final String title;
  final List<ComicTag> initialTags;
  final String? comicId;
  final int? comicUploadDate;

  /// Optional async loader that fetches the full tag list and favorite count.
  /// When null, [initialTags] is used directly.
  final Future<({List<ComicTag> tags, int? numFavorites, int? uploadDate})> Function()? loadMeta;

  /// Called with the sorted list of selected tag query strings when the user
  /// confirms the search. The sheet is dismissed before this is invoked.
  final ValueChanged<List<String>> onSearchSelected;

  /// Optional widget rendered below the search button.
  /// Intended for download-status information (e.g. a progress tile).
  final Widget? downloadSlot;

  /// Optional widget rendered at the bottom of the action area.
  /// Intended for destructive actions (e.g. Remove from collection, Delete).
  final Widget? actionSlot;

  static Future<void> show({
    required BuildContext context,
    required String title,
    required List<ComicTag> tags,
    required ValueChanged<List<String>> onSearchSelected,
    String? comicId,
    int? comicUploadDate,
    Future<({List<ComicTag> tags, int? numFavorites, int? uploadDate})> Function()? loadMeta,
    Widget? downloadSlot,
    Widget? actionSlot,
  }) {
    return showGlassModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ComicTagBottomSheet(
        title: title,
        initialTags: tags,
        comicId: comicId,
        comicUploadDate: comicUploadDate,
        loadMeta: loadMeta,
        onSearchSelected: onSearchSelected,
        downloadSlot: downloadSlot,
        actionSlot: actionSlot,
      ),
    );
  }

  @override
  State<ComicTagBottomSheet> createState() => _ComicTagBottomSheetState();
}

class _ComicTagBottomSheetState extends State<ComicTagBottomSheet> {
  List<ComicTag>? _tags;
  int? _numFavorites;
  int? _loadedUploadDate;
  String? _errorMessage;
  bool _isLoading = false;
  final Set<String> _selectedQueries = <String>{};

  @override
  void initState() {
    super.initState();
    if (widget.initialTags.isNotEmpty) {
      _tags = widget.initialTags;
      return;
    }
    _loadMeta();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final tags = _tags ?? const <ComicTag>[];
    final grouped = _groupTagsByType(tags);
    final sortedTypes = _sortedTypeKeys(grouped.keys.toList());

    return DraggableScrollableSheet(
      initialChildSize: 0.68,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: <Widget>[
            _buildHandle(context),
            _buildTitle(context),
            if (_numFavorites != null || widget.comicId != null || _loadedUploadDate != null || widget.comicUploadDate != null)
              _buildInfoRow(context),
            const Divider(height: 1),
            Expanded(
              child: _buildBody(
                context: context,
                locale: locale,
                grouped: grouped,
                sortedTypes: sortedTypes,
                scrollController: scrollController,
              ),
            ),
            const Divider(height: 1),
            _buildActionArea(context),
          ],
        );
      },
    );
  }

  // ── Chrome ────────────────────────────────────────────────────────────────

  Widget _buildHandle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(80),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        widget.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: <Widget>[
          if (_numFavorites != null) ...<Widget>[
            Icon(Icons.favorite, size: 13, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 4),
            Text(_formatFavorites(_numFavorites), style: style),
            const SizedBox(width: 12),
          ],
          if (widget.comicId != null) ...<Widget>[
            Text('#${widget.comicId}', style: style),
            const SizedBox(width: 12),
          ],
          if (_loadedUploadDate != null || widget.comicUploadDate != null)
            Text(_formatDate((_loadedUploadDate ?? widget.comicUploadDate)!), style: style),
        ],
      ),
    );
  }

  String _formatDate(int uploadDateSeconds) {
    final dt = DateTime.fromMillisecondsSinceEpoch(uploadDateSeconds * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  // ── Tag body ──────────────────────────────────────────────────────────────

  Widget _buildBody({
    required BuildContext context,
    required Locale locale,
    required Map<String, List<ComicTag>> grouped,
    required List<String> sortedTypes,
    required ScrollController scrollController,
  }) {
    if (_isLoading && _tags == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null && _tags == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(_errorMessage!),
            const SizedBox(height: 8),
            FilledButton(onPressed: _loadMeta, child: const Text('Retry')),
          ],
        ),
      );
    }
    if ((_tags ?? const <ComicTag>[]).isEmpty) {
      return const Center(child: Text('No tags'));
    }

    final blockedTagsModel = context.watch<BlockedTagsModel>();
    final blockedQueries = blockedTagsModel.blockedTags.toSet();

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: <Widget>[
        for (final type in sortedTypes) ...<Widget>[
          _TagTypeSection(
            typeName: TagTypeL10n.localizedName(type, locale),
            tags: grouped[type]!,
            selectedQueries: _selectedQueries,
            blockedQueries: blockedQueries,
            onToggleTag: (tag) {
              setState(() {
                if (_selectedQueries.contains(tag.query)) {
                  _selectedQueries.remove(tag.query);
                } else {
                  _selectedQueries.add(tag.query);
                }
              });
            },
            onLongPressTag: (tag) => _showTagContextMenu(context, tag, blockedTagsModel),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  void _showTagContextMenu(
    BuildContext context,
    ComicTag tag,
    BlockedTagsModel blockedTagsModel,
  ) {
    final query = tag.query;
    if (query.isEmpty) return;

    final isBlocked = blockedTagsModel.isBlocked(query);
    showGlassModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(
                  isBlocked ? Icons.check_circle_outline : Icons.block,
                ),
                title: Text(
                  isBlocked ? 'Unblock "${tag.name}"' : 'Block "${tag.name}"',
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  if (isBlocked) {
                    blockedTagsModel.removeTag(query);
                  } else {
                    blockedTagsModel.addTag(query);
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isBlocked
                            ? '"$query" removed from blocked tags'
                            : '"$query" added to blocked tags',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Bottom action area ────────────────────────────────────────────────────

  Widget _buildActionArea(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (_selectedQueries.isNotEmpty) ...<Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: (_selectedQueries.toList()..sort()).map((query) {
                    return Chip(
                      label: Text(query),
                      onDeleted: () => setState(() => _selectedQueries.remove(query)),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _selectedQueries.isEmpty ? null : _handleSearch,
                icon: const Icon(Icons.search),
                label: Text(
                  _selectedQueries.isEmpty
                      ? 'Select tags to search'
                      : 'Search ${_selectedQueries.length} tags',
                ),
              ),
            ),
            if (widget.downloadSlot != null) ...<Widget>[
              const SizedBox(height: 8),
              widget.downloadSlot!,
            ],
            if (widget.actionSlot != null) ...<Widget>[
              const SizedBox(height: 8),
              widget.actionSlot!,
            ],
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _loadMeta() async {
    final loadMeta = widget.loadMeta;
    if (loadMeta == null) {
      setState(() => _tags = widget.initialTags);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final meta = await loadMeta();
      if (!mounted) return;
      setState(() {
        _tags = meta.tags;
        _numFavorites = meta.numFavorites;
        if (meta.uploadDate != null) _loadedUploadDate = meta.uploadDate;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load tags.';
        _isLoading = false;
      });
    }
  }

  void _handleSearch() {
    final selected = _selectedQueries.toList()..sort();
    Navigator.of(context).pop();
    widget.onSearchSelected(selected);
  }

  String _formatFavorites(int? count) {
    if (count == null || count <= 0) return '0';
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '$count';
  }

  Map<String, List<ComicTag>> _groupTagsByType(List<ComicTag> tags) {
    final result = <String, List<ComicTag>>{};
    for (final tag in tags) {
      result.putIfAbsent(tag.type ?? 'tag', () => <ComicTag>[]).add(tag);
    }
    return result;
  }

  List<String> _sortedTypeKeys(List<String> keys) {
    const priority = <String>[
      'parody', 'character', 'tag', 'artist', 'group', 'language', 'category',
    ];
    final prioritized = keys.where(priority.contains).toList()
      ..sort((a, b) => priority.indexOf(a) - priority.indexOf(b));
    final rest = keys.where((k) => !priority.contains(k)).toList()..sort();
    return <String>[...prioritized, ...rest];
  }
}

// ── Tag type section ──────────────────────────────────────────────────────────

class _TagTypeSection extends StatelessWidget {
  const _TagTypeSection({
    required this.typeName,
    required this.tags,
    required this.selectedQueries,
    required this.blockedQueries,
    required this.onToggleTag,
    required this.onLongPressTag,
  });

  final String typeName;
  final List<ComicTag> tags;
  final Set<String> selectedQueries;
  final Set<String> blockedQueries;
  final ValueChanged<ComicTag> onToggleTag;
  final ValueChanged<ComicTag> onLongPressTag;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          typeName,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: tags.map((tag) {
            final isBlocked = blockedQueries.contains(tag.query);
            return GestureDetector(
              onLongPress: () => onLongPressTag(tag),
              child: FilterChip(
                label: Text(
                  context.read<TagDisplayService>().displayName(tag.slug, tag.name ?? ''),
                ),
                selected: selectedQueries.contains(tag.query),
                avatar: isBlocked
                    ? const Icon(Icons.block, size: 14)
                    : null,
                onSelected: (_) => onToggleTag(tag),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
