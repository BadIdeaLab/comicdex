import 'package:flutter/material.dart';

class HomeUiModel extends ChangeNotifier {
  HomeUiModel() {
    downloadsSearchController.addListener(notifyListeners);
  }

  int _navigationIndex = 0;
  final SearchController searchController = SearchController();

  /// The Downloads tab's filter text.
  ///
  /// Owned here rather than by `HomeShell` because the tag sheet needs to set
  /// it from outside that widget — the same reason the completed-view mode
  /// moved onto its model in P71.
  final TextEditingController downloadsSearchController =
      TextEditingController();

  bool _isLoading = false;

  /// Tag ids the Downloads tab filters by, ANDed together (P82).
  ///
  /// Ids rather than text: tag names contain spaces (`sole female`), so
  /// splitting the search box on whitespace would match nothing, and a
  /// substring filter cannot tell `full color` from `full colors`.
  final List<int> _downloadsTagIds = <int>[];

  int get navigationIndex => _navigationIndex;
  bool get isLoading => _isLoading;
  String get downloadsSearchQuery => downloadsSearchController.text;
  List<int> get downloadsTagIds => List<int>.unmodifiable(_downloadsTagIds);

  /// Filters the Downloads tab by [label] and switches to it.
  ///
  /// [label] must be the tag's **displayed** name, not its `type:slug` query.
  /// The Downloads text filter is a plain substring match over titles and tag
  /// names (see `DownloadJobListSliver`), so `tag:full-color` would match
  /// nothing while looking perfectly reasonable in the box.
  void searchInDownloads(String label) {
    downloadsSearchController.text = label;
    _navigationIndex = 1;
    notifyListeners();
  }

  /// Adds tag ids to the Downloads filter and switches to that tab (P82).
  /// Ids already present are ignored, so tapping the same tag twice does not
  /// stack up chips.
  void filterDownloadsByTags(Iterable<int> tagIds) {
    for (final tagId in tagIds) {
      if (_downloadsTagIds.contains(tagId)) continue;
      _downloadsTagIds.add(tagId);
    }
    // Always notifies: even when every id was already there, the tab index
    // moved and the listener has to act on it.
    _navigationIndex = 1;
    notifyListeners();
  }

  void removeDownloadsTagFilter(int tagId) {
    if (_downloadsTagIds.remove(tagId)) notifyListeners();
  }

  void clearDownloadsTagFilters() {
    if (_downloadsTagIds.isEmpty) return;
    _downloadsTagIds.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    downloadsSearchController.removeListener(notifyListeners);
    downloadsSearchController.dispose();
    super.dispose();
  }

  bool get _isSearchControllerAttached {
    try {
      return searchController.isAttached;
    } on AssertionError {
      return false;
    }
  }

  void setNavigationIndex(int value) {
    // Only a deliberate tap on Home while already on Home clears the search.
    // Merely leaving the tab used to clear it as well, on the assumption that
    // coming back would reload from scratch anyway. That assumption is gone,
    // and clearing now would empty the box while its results stayed on screen.
    final tappedHomeWhileOnHome = _navigationIndex == 0 && value == 0;
    if (tappedHomeWhileOnHome) {
      searchController.text = '';
    }
    _navigationIndex = value;
    notifyListeners();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void closeSearchView([String? selectedText]) {
    if (_isSearchControllerAttached && searchController.isOpen) {
      searchController.closeView(selectedText);
      return;
    }

    if (selectedText != null) {
      searchController.text = selectedText;
    }
  }

  /// Closes the search overlay if it is open, leaving the query alone.
  ///
  /// It used to clear the text as well, which quietly overrode
  /// [setNavigationIndex]'s rule: every tab switch went through here first, so
  /// the query was wiped on the way out no matter what. That was invisible
  /// while returning to Home refetched from scratch, and wrong the moment the
  /// results started surviving the trip.
  void resetSearchView() {
    if (_isSearchControllerAttached && searchController.isOpen) {
      searchController.closeView(null);
    }
  }
}
