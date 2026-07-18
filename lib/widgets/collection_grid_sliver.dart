import 'package:concept_nhv/models/collection_summary.dart';
import 'package:concept_nhv/widgets/fallback_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CollectionGridSliver extends StatelessWidget {
  const CollectionGridSliver({super.key, required this.collections});

  final List<CollectionSummary> collections;

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        mainAxisExtent: 300,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        final collection = collections[index];
        return Column(
          children: <Widget>[
            Expanded(
              child: Card(
                clipBehavior: Clip.hardEdge,
                child: InkWell(
                  splashColor: Colors.blue.withAlpha(30),
                  onTap: () {
                    context.push(
                      Uri(
                        path: '/collection',
                        queryParameters: <String, String>{
                          'collectionName': collection.collectionName,
                        },
                      ).toString(),
                    );
                  },
                  child: FallbackCachedNetworkImage(
                    url: collection.thumbnailUrl,
                    width: collection.thumbnailWidth,
                    height: collection.thumbnailHeight,
                  ),
                ),
              ),
            ),
            Text(
              collection.collectionName,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text('${collection.collectedCount} collected'),
              ],
            ),
          ],
        );
      }, childCount: collections.length),
    );
  }
}
