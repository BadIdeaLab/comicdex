import 'dart:convert';

import 'package:concept_nhv/application/search/blocked_tags_repository.dart';
import 'package:concept_nhv/storage/options_store.dart';

class BlockedTagsStore implements BlockedTagsRepository {
  const BlockedTagsStore({required this.optionsStore});

  final OptionsStore optionsStore;

  static const String _key = 'search_blocked_tags';

  @override
  Future<List<String>> loadBlockedTags() async {
    final raw = await optionsStore.loadOption(_key);
    if (raw.isEmpty) return const <String>[];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.cast<String>();
    } catch (_) {
      return const <String>[];
    }
  }

  @override
  Future<void> saveBlockedTags(List<String> queries) {
    return optionsStore.saveOption(_key, jsonEncode(queries));
  }
}
