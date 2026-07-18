import 'package:concept_nhv/models/collection_type.dart';
import 'package:concept_nhv/models/comic_card_data.dart';
import 'package:concept_nhv/state/comic_feed_model.dart';
import 'package:concept_nhv/state/home_ui_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'comic_card.dart';

class ComicGridSliver extends StatelessWidget {
  const ComicGridSliver({
    super.key,
    required this.comics,
    this.pageLoaded,
    this.collectionType,
    this.onCollectionChanged,
    this.onTagSelected,
    this.selectedIds = const <String>{},
    this.onToggleSelection,
  });

  final List<ComicCardData> comics;
  final int? pageLoaded;
  final CollectionType? collectionType;
  final VoidCallback? onCollectionChanged;

  /// Forwarded to each [ComicCard]; called when a tag chip is tapped.
  final ValueChanged<List<String>>? onTagSelected;

  final Set<String> selectedIds;
  final void Function(ComicCardData comic)? onToggleSelection;

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        mainAxisExtent: 300,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        final reachLastItem = index + 1 == comics.length;
        final feedModel = context.read<ComicFeedModel>();
        final homeUiModel = context.read<HomeUiModel>();

        if (pageLoaded != null &&
            reachLastItem &&
            !feedModel.noMorePage &&
            !homeUiModel.isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (homeUiModel.isLoading) {
              return;
            }
            homeUiModel.setLoading(true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Loading... page: ${pageLoaded! + 1}, language: ${feedModel.currentLanguage.name}',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
            await feedModel.fetchNextPage(page: pageLoaded! + 1);
            homeUiModel.setLoading(false);
          });
        }

        final comic = comics[index];
        return ComicCard(
          key: ValueKey<String>(comic.id),
          comic: comic,
          collectionType: collectionType,
          onCollectionChanged: onCollectionChanged,
          onTagSelected: onTagSelected,
          isSelected: selectedIds.contains(comic.id),
          onSelectionToggle: onToggleSelection != null
              ? () => onToggleSelection!(comic)
              : null,
        );
      }, childCount: comics.length),
    );
  }
}
