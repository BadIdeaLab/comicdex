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
    final doubleClickIndex = _navigationIndex == 0 && value == 0;
    final fromIndexPage = _navigationIndex == 0;
    if (doubleClickIndex || fromIndexPage) {
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

  void resetSearchView() {
    searchController.text = '';
    if (_isSearchControllerAttached && searchController.isOpen) {
      searchController.closeView(null);
    }
  }
}
