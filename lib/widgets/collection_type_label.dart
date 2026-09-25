import 'package:concept_nhv/l10n/app_localizations.dart';
import 'package:concept_nhv/models/collection_type.dart';

/// The user-facing name of a collection.
///
/// [CollectionType.displayName] cannot be it: that is an alias of
/// `storageName`, which is the literal value written to the `Collection.name`
/// column. Translating it would rename the data.
String collectionTypeLabel(AppLocalizations l10n, CollectionType type) {
  return switch (type) {
    CollectionType.favorite => l10n.collectionFavorite,
    CollectionType.next => l10n.collectionNext,
    CollectionType.history => l10n.collectionHistory,
  };
}
