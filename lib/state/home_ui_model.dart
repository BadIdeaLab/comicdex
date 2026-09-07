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

  int get navigationIndex => _navigationIndex;
  bool get isLoading => _isLoading;
  String get downloadsSearchQuery => downloadsSearchController.text;

  /// Filters the Downloads tab by [label] and switches to it.
  ///
  /// [label] must be the tag's **displayed** name, not its `type:slug` query.
  /// The Downloads filter is a plain substring match over titles and tag names
  /// (see `DownloadJobListSliver`), so `tag:full-color` would match nothing
  /// while looking perfectly reasonable in the box.
  void searchInDownloads(String label) {
    downloadsSearchController.text = label;
    _navigationIndex = 1;
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
