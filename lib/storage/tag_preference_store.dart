import 'package:concept_nhv/models/tag_preference_entry.dart';
import 'package:concept_nhv/storage/options_store.dart';

class TagPreferenceStore {
  const TagPreferenceStore({required this.optionsStore});

  final OptionsStore optionsStore;

  static const String _sortKey = 'tag_preference_sort';
  static const String _combinationSortKey = 'tag_combination_sort';

  Future<TagPreferenceSort> loadSort() async {
    return TagPreferenceSort.fromName(await optionsStore.loadOption(_sortKey));
  }

  Future<void> saveSort(TagPreferenceSort sort) {
    return optionsStore.saveOption(_sortKey, sort.name);
  }

  /// The combinations list sorts independently of the ranking: "my biggest
  /// tags" and "my most unusual combinations" are different questions and a
  /// reader may want one of each on screen.
  Future<TagPreferenceSort> loadCombinationSort() async {
    final raw = await optionsStore.loadOption(_combinationSortKey);
    return raw.isEmpty
        ? TagPreferenceSort.affinity
        : TagPreferenceSort.fromName(raw);
  }

  Future<void> saveCombinationSort(TagPreferenceSort sort) {
    return optionsStore.saveOption(_combinationSortKey, sort.name);
  }
}
