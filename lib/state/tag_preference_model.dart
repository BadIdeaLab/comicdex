import 'package:concept_nhv/application/tags/load_tag_preferences_use_case.dart';
import 'package:concept_nhv/models/tag_catalog_type.dart';
import 'package:concept_nhv/models/tag_preference_entry.dart';
import 'package:concept_nhv/storage/tag_preference_store.dart';
import 'package:flutter/foundation.dart';

/// Holds the tag preference ranking shown on the Collections tab (P78).
class TagPreferenceModel extends ChangeNotifier {
  TagPreferenceModel({
    required this.loadTagPreferencesUseCase,
    required this.tagPreferenceStore,
  });

  final LoadTagPreferencesUseCase loadTagPreferencesUseCase;
  final TagPreferenceStore tagPreferenceStore;

  Map<TagCatalogType, List<TagPreferenceEntry>> _preferences =
      <TagCatalogType, List<TagPreferenceEntry>>{};
  TagPreferenceSort _sort = TagPreferenceSort.count;
  bool _isLoading = false;
  bool _hasLoaded = false;

  Map<TagCatalogType, List<TagPreferenceEntry>> get preferences => _preferences;
  TagPreferenceSort get sort => _sort;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;

  /// Recomputes the ranking. Cheap enough to run on every visit (one query
  /// plus an in-memory sort), so there is no cache to invalidate when
  /// favorites or downloads change.
  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      if (!_hasLoaded) {
        _sort = await tagPreferenceStore.loadSort();
      }
      _preferences = await loadTagPreferencesUseCase.execute(sort: _sort);
      _hasLoaded = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setSort(TagPreferenceSort sort) async {
    if (sort == _sort) return;
    _sort = sort;
    notifyListeners();
    await tagPreferenceStore.saveSort(sort);
    await load();
  }
}
