abstract class BlockedTagsRepository {
  /// Returns all blocked tag query strings (e.g. ["tag:full-color", "artist:xxx"]).
  Future<List<String>> loadBlockedTags();

  /// Replaces the entire blocked tag list.
  Future<void> saveBlockedTags(List<String> queries);
}
