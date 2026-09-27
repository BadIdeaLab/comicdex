import 'package:concept_nhv/models/comic_tag.dart';
import 'package:concept_nhv/models/download_list_item_snapshot.dart';
import 'package:concept_nhv/services/tag_display_service.dart';

/// Narrows the Downloads list to what the search field and the tag chips ask
/// for.
///
/// [query] is matched case-insensitively against the title and against every
/// tag — both its raw name and its translated one, so a reader searching in
/// Chinese finds comics whose tags are stored in English.
///
/// [tagIds] must all be present, and an in-progress job therefore never
/// survives a tag filter: it has no tags yet, deliberately, since it has
/// nothing to match on.
List<DownloadListItemSnapshot> filterDownloadItems(
  List<DownloadListItemSnapshot> items, {
  String query = '',
  Iterable<int> tagIds = const <int>[],
  required TagDisplayService tagDisplayService,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty && tagIds.isEmpty) {
    return items;
  }
  return items
      .where(
        (item) => _matches(
          item,
          query: normalizedQuery,
          tagIds: tagIds,
          tagDisplayService: tagDisplayService,
        ),
      )
      .toList(growable: false);
}

bool _matches(
  DownloadListItemSnapshot item, {
  required String query,
  required Iterable<int> tagIds,
  required TagDisplayService tagDisplayService,
}) {
  for (final tagId in tagIds) {
    if (!item.tags.any((tag) => tag.id == tagId)) return false;
  }
  if (query.isEmpty) return true;
  if (item.title.toLowerCase().contains(query)) return true;
  return item.tags.any((tag) {
    final rawName = tag.name ?? '';
    final displayName = tagDisplayService.displayName(tag.slug, rawName);
    return rawName.toLowerCase().contains(query) ||
        displayName.toLowerCase().contains(query);
  });
}
