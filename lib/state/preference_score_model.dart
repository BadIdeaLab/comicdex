import 'package:concept_nhv/application/tags/build_tag_preference_vector_use_case.dart';
import 'package:concept_nhv/application/tags/tag_preference_vector.dart';
import 'package:flutter/foundation.dart';

/// Holds the preference vector used to sort Downloads and to badge covers
/// (P84). One instance for the whole app: the vector describes the library,
/// not any one screen.
class PreferenceScoreModel extends ChangeNotifier {
  PreferenceScoreModel({required this.buildTagPreferenceVectorUseCase});

  final BuildTagPreferenceVectorUseCase buildTagPreferenceVectorUseCase;

  TagPreferenceVector _vector = const TagPreferenceVector.empty();
  bool _isLoading = false;
  bool _hasLoaded = false;

  TagPreferenceVector get vector => _vector;
  bool get hasLoaded => _hasLoaded;

  PreferenceTier tierFor(Iterable<int> tagIds) => _vector.tierFor(tagIds);

  Future<void> ensureLoaded() async {
    if (_hasLoaded) return;
    await refresh();
  }

  /// Recomputes from the current library. Worth doing whenever the user has
  /// plainly changed what they keep — the ranking screens already reload on
  /// every visit for the same reason (P78).
  Future<void> refresh() async {
    if (_isLoading) return;
    _isLoading = true;
    try {
      _vector = await buildTagPreferenceVectorUseCase.execute();
      _hasLoaded = true;
      notifyListeners();
    } finally {
      _isLoading = false;
    }
  }
}
