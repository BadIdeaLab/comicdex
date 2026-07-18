import 'package:concept_nhv/application/search/blocked_tags_repository.dart';
import 'package:flutter/foundation.dart';

class BlockedTagsModel extends ChangeNotifier {
  BlockedTagsModel({required this.blockedTagsRepository});

  final BlockedTagsRepository blockedTagsRepository;

  List<String> _blockedTags = const <String>[];

  List<String> get blockedTags => _blockedTags;

  Future<void> load() async {
    _blockedTags = await blockedTagsRepository.loadBlockedTags();
    notifyListeners();
  }

  Future<void> addTag(String query) async {
    if (_blockedTags.contains(query)) return;
    final updated = List<String>.from(_blockedTags)..add(query);
    await blockedTagsRepository.saveBlockedTags(updated);
    _blockedTags = updated;
    notifyListeners();
  }

  Future<void> removeTag(String query) async {
    if (!_blockedTags.contains(query)) return;
    final updated = List<String>.from(_blockedTags)..remove(query);
    await blockedTagsRepository.saveBlockedTags(updated);
    _blockedTags = updated;
    notifyListeners();
  }

  bool isBlocked(String query) => _blockedTags.contains(query);
}
