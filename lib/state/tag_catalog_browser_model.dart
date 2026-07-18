import 'package:concept_nhv/application/tags/load_tag_catalog_use_case.dart';
import 'package:concept_nhv/models/tag_catalog_item.dart';
import 'package:concept_nhv/models/tag_catalog_page.dart';
import 'package:concept_nhv/models/tag_catalog_type.dart';
import 'package:flutter/material.dart';

class TagCatalogBrowserModel extends ChangeNotifier {
  TagCatalogBrowserModel({required this.loadTagCatalogUseCase});

  final LoadTagCatalogUseCase loadTagCatalogUseCase;

  TagCatalogType _type = TagCatalogType.tag;
  TagCatalogPage? _currentPage;
  bool _isLoading = false;
  String? _errorMessage;
  int _requestSequence = 0;
  final Set<String> _selectedQueries = <String>{};

  TagCatalogType get type => _type;
  TagCatalogPage? get currentPage => _currentPage;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<String> get selectedQueries => (_selectedQueries.toList()..sort());

  Future<void> ensureLoaded() async {
    if (_currentPage == null && !_isLoading) {
      await loadPage(1);
    }
  }

  Future<void> setType(TagCatalogType type) async {
    if (_type == type) {
      return;
    }
    _type = type;
    _selectedQueries.clear();
    _currentPage = null;
    _errorMessage = null;
    notifyListeners();
    await loadPage(1);
  }

  Future<void> loadPage(int page) async {
    final requestId = ++_requestSequence;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await loadTagCatalogUseCase.execute(type: _type, page: page);
      if (requestId != _requestSequence) {
        return;
      }
      _currentPage = result;
    } catch (_) {
      if (requestId != _requestSequence) {
        return;
      }
      _errorMessage = 'Failed to load tags.';
    } finally {
      if (requestId == _requestSequence) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void toggleSelection(TagCatalogItem item) {
    if (_selectedQueries.contains(item.query)) {
      _selectedQueries.remove(item.query);
    } else {
      _selectedQueries.add(item.query);
    }
    notifyListeners();
  }

  bool isSelected(TagCatalogItem item) => _selectedQueries.contains(item.query);

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
}
