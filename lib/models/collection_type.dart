enum CollectionType {
  favorite('Favorite'),
  next('Next'),
  history('History');

  const CollectionType(this.storageName);

  final String storageName;

  String get displayName => storageName;

  static CollectionType? fromStorageName(String value) {
    for (final type in CollectionType.values) {
      if (type.storageName.toLowerCase() == value.toLowerCase()) {
        return type;
      }
    }
    return null;
  }
}
