import 'package:concept_nhv/application/search/blocked_tags_repository.dart';

class FakeBlockedTagsRepository implements BlockedTagsRepository {
  FakeBlockedTagsRepository({List<String>? initial})
      : _tags = initial ?? const <String>[];

  List<String> _tags;

  @override
  Future<List<String>> loadBlockedTags() async => _tags;

  @override
  Future<void> saveBlockedTags(List<String> queries) async {
    _tags = queries;
  }
}
