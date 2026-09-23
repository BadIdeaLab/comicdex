import 'package:concept_nhv/services/local_tag_catalog_service.dart';
import 'package:concept_nhv/services/tag_display_service.dart';
import 'package:concept_nhv/state/home_ui_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The Downloads tab's active tag filters, one removable chip each (P82).
class DownloadsTagFilterChips extends StatelessWidget {
  const DownloadsTagFilterChips({super.key});

  @override
  Widget build(BuildContext context) {
    final homeUiModel = context.watch<HomeUiModel>();
    final tagIds = homeUiModel.downloadsTagIds;
    if (tagIds.isEmpty) return const SizedBox.shrink();

    final catalog = context.read<LocalTagCatalogService>();
    final display = context.read<TagDisplayService>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          for (final tagId in tagIds)
            InputChip(
              label: Text(_label(catalog, display, tagId)),
              onDeleted: () => homeUiModel.removeDownloadsTagFilter(tagId),
            ),
          if (tagIds.length > 1)
            TextButton(
              onPressed: homeUiModel.clearDownloadsTagFilters,
              child: const Text('Clear tags'),
            ),
        ],
      ),
    );
  }

  /// Falls back to the raw id: a catalog older than P76 resolves nothing, and
  /// a chip with no label would be a filter the user cannot identify.
  String _label(
    LocalTagCatalogService catalog,
    TagDisplayService display,
    int tagId,
  ) {
    final entry = catalog.entryById(tagId);
    if (entry == null) return 'Tag #$tagId';
    return display.displayName(entry.slug, entry.name);
  }
}
