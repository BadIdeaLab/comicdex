import 'package:concept_nhv/models/local_tag_catalog_entry.dart';
import 'package:concept_nhv/state/blocked_tags_model.dart';
import 'package:concept_nhv/models/tag_catalog_type.dart';
import 'package:concept_nhv/state/home_ui_model.dart';
import 'package:concept_nhv/state/tracking_model.dart';
import 'package:concept_nhv/widgets/favorites_tag_filter_route.dart';
import 'package:concept_nhv/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  final l10n = AppLocalizations.of(context)!;
  final homeUiModel = context.read<HomeUiModel>();
  final messenger = ScaffoldMessenger.of(context);
  final isBlocked = blockedTagsModel.blockedTags.contains(tag.query);
  final tagId = tag.id;
  final router = GoRouter.of(context);
  // Nullable, like every other optional model: the sheet has to open
  // with no tracking wired up above it.
  final tracking = context.read<TrackingModel?>();
  final isTracked = tagId != null && (tracking?.isTracked(tagId) ?? false);

  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: Icon(isBlocked ? Icons.check_circle_outline : Icons.block),
            title: Text(
              isBlocked
                  ? l10n.tagActionUnblock(displayName)
                  : l10n.tagActionBlock(displayName),
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
                        ? l10n.tagActionUnblocked(tag.query)
                        : l10n.tagActionBlocked(tag.query),
                  ),
                ),
              );
            },
          ),
          if (tagId != null)
            ListTile(
              leading: const Icon(Icons.favorite_border),
              title: Text(l10n.tagActionSearchFavorites(displayName)),
              onTap: () {
                Navigator.of(sheetContext).pop();
                openFavoritesFilteredByTag(context, tagId);
              },
            ),
          // Artists only. A parody or a plain tag publishes constantly, so
          // "new work" for one of those would be news every day, which is no
          // news at all.
          if (tagId != null &&
              tracking != null &&
              tag.type == TagCatalogType.artist)
            ListTile(
              leading: Icon(
                isTracked
                    ? Icons.notifications_off_outlined
                    : Icons.notifications_active_outlined,
              ),
              title: Text(
                isTracked
                    ? l10n.tagActionUntrackArtist(displayName)
                    : l10n.tagActionTrackArtist(displayName),
              ),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                if (isTracked) {
                  await tracking.untrack(tagId);
                } else {
                  await tracking.track(tagId);
                }
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      isTracked
                          ? l10n.tagActionUntracked(displayName)
                          : l10n.tagActionTracked(displayName),
                    ),
                  ),
                );
              },
            ),
          if (tagId != null)
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: Text(l10n.tagActionFilterDownloads(displayName)),
              onTap: () {
                Navigator.of(sheetContext).pop();
                homeUiModel.filterDownloadsByTags(<int>[tagId]);
                // Adding the filter only switches the tab *inside* the shell;
                // from a pushed route (the analysis page) the shell keeps
                // showing that route, so the action looks like it did nothing.
                router.goNamed('index');
              },
            ),
        ],
      ),
    ),
  );
}
