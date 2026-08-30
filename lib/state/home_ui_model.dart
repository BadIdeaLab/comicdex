import 'package:flutter/material.dart';

class HomeUiModel extends ChangeNotifier {
  int _navigationIndex = 0;
  final SearchController searchController = SearchController();
  bool _isLoading = false;

  int get navigationIndex => _navigationIndex;
  bool get isLoading => _isLoading;

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
