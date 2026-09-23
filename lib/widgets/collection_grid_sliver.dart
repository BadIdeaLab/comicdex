import 'package:concept_nhv/models/collection_summary.dart';
import 'package:concept_nhv/widgets/fallback_cached_network_image.dart';
import 'package:concept_nhv/widgets/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The Favorite / Next / History entries at the top of the Collections tab.
///
/// Compact rows rather than the tall cover-dominated cards this used to be:
/// the tab now carries the tag preference sections below (P78), and three
/// 300px-high covers pushed them off screen.
class CollectionGridSliver extends StatelessWidget {
  const CollectionGridSliver({super.key, required this.collections});

  final List<CollectionSummary> collections;

  @override
  Widget build(BuildContext context) {
    return SliverList.separated(
      itemCount: collections.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) =>
          _CollectionEntryCard(collection: collections[index]),
    );
  }
}

class _CollectionEntryCard extends StatelessWidget {
  const _CollectionEntryCard({required this.collection});

  final CollectionSummary collection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GlassContainer.card(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.push(
            Uri(
              path: '/collection',
              queryParameters: <String, String>{
                'collectionName': collection.collectionName,
              },
            ).toString(),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 48,
                    height: 64,
                    child: FallbackCachedNetworkImage(
                      url: collection.thumbnailUrl,
                      width: collection.thumbnailWidth,
                      height: collection.thumbnailHeight,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        collection.collectionName,
                        style: theme.textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${collection.collectedCount} collected',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
