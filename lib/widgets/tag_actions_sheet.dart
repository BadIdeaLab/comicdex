import 'package:concept_nhv/models/local_tag_catalog_entry.dart';
import 'package:concept_nhv/state/blocked_tags_model.dart';
import 'package:concept_nhv/state/home_ui_model.dart';
import 'package:concept_nhv/widgets/favorites_tag_filter_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Long-press actions for a tag shown outside a comic (the preference
/// ranking and the analysis page). The comic tag sheet has its own copy
/// because it must also pop that sheet on the way out.
Future<void> showTagActionsSheet(
  BuildContext context,
  LocalTagCatalogEntry tag,
  String displayName,
) {
  final blockedTagsModel = context.read<BlockedTagsModel>();
  final homeUiModel = context.read<HomeUiModel>();
  final messenger = ScaffoldMessenger.of(context);
  final isBlocked = blockedTagsModel.blockedTags.contains(tag.query);
  final tagId = tag.id;

  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: Icon(isBlocked ? Icons.check_circle_outline : Icons.block),
            title: Text(
              isBlocked ? 'Unblock "$displayName"' : 'Block "$displayName"',
            ),
            onTap: () {
              Navigator.of(sheetContext).pop();
              if (isBlocked) {
                blockedTagsModel.removeTag(tag.query);
              } else {
                blockedTagsModel.addTag(tag.query);
              }
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    isBlocked
                        ? '"${tag.query}" removed from blocked tags'
                        : '"${tag.query}" added to blocked tags',
                  ),
                ),
              );
            },
          ),
          if (tagId != null)
            ListTile(
              leading: const Icon(Icons.favorite_border),
              title: Text('Search "$displayName" in Favorites'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                openFavoritesFilteredByTag(context, tagId);
              },
            ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: Text('Search "$displayName" in Downloads'),
            onTap: () {
              Navigator.of(sheetContext).pop();
              homeUiModel.searchInDownloads(displayName);
            },
          ),
        ],
      ),
    ),
  );
}
