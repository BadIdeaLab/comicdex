import 'package:concept_nhv/models/collection_type.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Opens Favorites showing only the comics carrying [tagId] (P80).
///
/// Favorites hold tag ids but no tag names locally, so the filter travels as
/// an id rather than as search text the way the Downloads filter does.
void openFavoritesFilteredByTag(BuildContext context, int tagId) {
  context.push(
    Uri(
      path: '/collection',
      queryParameters: <String, String>{
        'collectionName': CollectionType.favorite.storageName,
        'tagId': '$tagId',
      },
    ).toString(),
  );
}
