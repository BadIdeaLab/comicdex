import 'dart:async';

import 'package:concept_nhv/models/local_tag_catalog_entry.dart';
import 'package:concept_nhv/models/tag_catalog_type.dart';
import 'package:concept_nhv/services/local_tag_catalog_service.dart';
import 'package:concept_nhv/services/tag_display_service.dart';
import 'package:flutter/material.dart';

const Duration _searchDebounce = Duration(milliseconds: 200);

class TagCatalogBrowserModel extends ChangeNotifier {
  TagCatalogBrowserModel({
    required this.localTagCatalogService,
    required this.tagDisplayService,
  });

  final LocalTagCatalogService localTagCatalogService;
  final TagDisplayService tagDisplayService;

  TagCatalogType _type = TagCatalogType.tag;
  String _query = '';
  List<LocalTagCatalogEntry> _results = const <LocalTagCatalogEntry>[];
  Timer? _debounce;
  final Set<String> _selectedQueries = <String>{};

  TagCatalogType get type => _type;
  String get query => _query;
  List<LocalTagCatalogEntry> get results => _results;
  List<String> get selectedQueries => (_selectedQueries.toList()..sort());

  /// Runs the initial search so the panel isn't blank on first open. Kept as
  /// a no-arg method (rather than folding into the constructor) so callers
  /// that already invoke `ensureLoaded()` on init need no change.
  void ensureLoaded() {
    if (_results.isEmpty && _query.isEmpty) {
      _runSearch();
    }
  }

  void setType(TagCatalogType type) {
    if (_type == type) {
      return;
    }
    _type = type;
    // Selected tags intentionally survive a category switch so users can
    // build a search that spans multiple tag types (see P58).
    _runSearch();
  }

  void setQuery(String value) {
    _query = value;
    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, _runSearch);
  }

  void _runSearch() {
    _results = localTagCatalogService.search(
      _query,
      type: _type,
      displayNameResolver: tagDisplayService.displayName,
    );
    notifyListeners();
  }

  void toggleSelection(LocalTagCatalogEntry item) {
    if (_selectedQueries.contains(item.query)) {
      _selectedQueries.remove(item.query);
    } else {
      _selectedQueries.add(item.query);
    }
    notifyListeners();
  }

  bool isSelected(LocalTagCatalogEntry item) => _selectedQueries.contains(item.query);

  void removeSelection(String query) {
    if (_selectedQueries.remove(query)) {
      notifyListeners();
    }
  }

  void clearSelection() {
    if (_selectedQueries.isEmpty) {
      return;
    }
    _selectedQueries.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
