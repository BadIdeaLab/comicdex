import 'package:concept_nhv/application/tags/load_tag_cooccurrence_use_case.dart';
import 'package:concept_nhv/application/tags/load_tag_coverage_use_case.dart';
import 'package:concept_nhv/application/tags/load_tag_preferences_use_case.dart';
import 'package:concept_nhv/models/tag_combination.dart';
import 'package:concept_nhv/models/tag_catalog_type.dart';
import 'package:concept_nhv/models/tag_preference_entry.dart';
import 'package:concept_nhv/storage/tag_preference_store.dart';
import 'package:flutter/foundation.dart';

/// Holds the tag preference ranking shown on the Collections tab (P78).
class TagPreferenceModel extends ChangeNotifier {
  TagPreferenceModel({
    required this.loadTagPreferencesUseCase,
    required this.loadTagCooccurrenceUseCase,
    required this.loadTagCoverageUseCase,
    required this.tagPreferenceStore,
  });

  final LoadTagPreferencesUseCase loadTagPreferencesUseCase;
  final LoadTagCooccurrenceUseCase loadTagCooccurrenceUseCase;
  final LoadTagCoverageUseCase loadTagCoverageUseCase;
  final TagPreferenceStore tagPreferenceStore;

  Map<TagCatalogType, List<TagPreferenceEntry>> _preferences =
      <TagCatalogType, List<TagPreferenceEntry>>{};
  TagPreferenceSort _sort = TagPreferenceSort.count;
  TagPreferenceSort _combinationSort = TagPreferenceSort.affinity;
  bool _isLoading = false;
  bool _hasLoaded = false;
  List<TagCombination> _combinations = const <TagCombination>[];
  TagCoverage? _coverage;
  bool _isAnalysisLoading = false;
  bool _hasLoadedAnalysis = false;

  Map<TagCatalogType, List<TagPreferenceEntry>> get preferences => _preferences;
  TagPreferenceSort get sort => _sort;
  TagPreferenceSort get combinationSort => _combinationSort;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;

  /// Only loaded once the analysis page asks for it — the Collections tab
  /// shows the ranking alone and must not pay for the combination pass (P81).
  List<TagCombination> get combinations => _combinations;
  TagCoverage? get coverage => _coverage;
  bool get isAnalysisLoading => _isAnalysisLoading;
  bool get hasLoadedAnalysis => _hasLoadedAnalysis;

  /// Everything the analysis page shows: the ranking, the tag coverage and
  /// the tag combinations.
  Future<void> loadAnalysis() async {
    if (_isAnalysisLoading) return;
    _isAnalysisLoading = true;
    notifyListeners();
    try {
      await load();
      if (!_hasLoadedAnalysis) {
        _combinationSort = await tagPreferenceStore.loadCombinationSort();
      }
      _coverage = await loadTagCoverageUseCase.execute();
      _combinations = await loadTagCooccurrenceUseCase.execute(
        sort: _combinationSort,
      );
      _hasLoadedAnalysis = true;
    } finally {
      _isAnalysisLoading = false;
      notifyListeners();
    }
  }

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

  /// Re-sorts the combinations without touching the ranking.
  Future<void> setCombinationSort(TagPreferenceSort sort) async {
    if (sort == _combinationSort) return;
    _combinationSort = sort;
    notifyListeners();
    await tagPreferenceStore.saveCombinationSort(sort);
    _combinations = await loadTagCooccurrenceUseCase.execute(sort: sort);
    notifyListeners();
  }

  Future<void> setSort(TagPreferenceSort sort) async {
    if (sort == _sort) return;
    _sort = sort;
    notifyListeners();
    await tagPreferenceStore.saveSort(sort);
    await load();
  }
}
