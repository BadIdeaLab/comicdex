import 'package:concept_nhv/models/tag_preference_entry.dart';
import 'package:concept_nhv/storage/options_store.dart';

class TagPreferenceStore {
  const TagPreferenceStore({required this.optionsStore});

  final OptionsStore optionsStore;

  static const String _sortKey = 'tag_preference_sort';

  Future<TagPreferenceSort> loadSort() async {
    return TagPreferenceSort.fromName(await optionsStore.loadOption(_sortKey));
  }

  Future<void> saveSort(TagPreferenceSort sort) {
    return optionsStore.saveOption(_sortKey, sort.name);
  }
}
