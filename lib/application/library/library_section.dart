enum LibrarySection {
  favorites,
  readLater,
  history,
  downloads;

  String get displayName {
    switch (this) {
      case LibrarySection.favorites:
        return 'Favorite';
      case LibrarySection.readLater:
        return 'Next';
      case LibrarySection.history:
        return 'History';
      case LibrarySection.downloads:
        return 'Downloads';
    }
  }
}
