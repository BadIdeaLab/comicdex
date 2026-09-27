import 'package:concept_nhv/application/tags/find_similar_comics_online_use_case.dart';
import 'package:concept_nhv/application/tags/find_similar_comics_use_case.dart';
import 'package:concept_nhv/application/tags/tag_preference_vector.dart';
import 'package:flutter/foundation.dart';

/// Owns what the reader shows on the page past the last one.
///
/// Separate from the reading session because none of this is part of reading
/// the comic: it is loaded as soon as the comic is, and the reader may never
/// swipe far enough to see it.
///
/// See .codex/phases/P92-similar-comics-end-page.md.
class ReaderEndPageModel extends ChangeNotifier {
  ReaderEndPageModel({
    required this.comicId,
    required this.findSimilar,
    required this.findSimilarOnline,
    required this.readPreferences,
  });

  final String comicId;
  final FindSimilarComicsUseCase findSimilar;
  final FindSimilarComicsOnlineUseCase findSimilarOnline;

  /// Read at each lookup rather than held as a value: the vector is built in
  /// the background and may not exist yet when the reader opens.
  final TagPreferenceVector? Function() readPreferences;

  List<SimilarComic> _similar = const <SimilarComic>[];
  bool _canShowPage = false;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Comics from the library that resemble this one.
  List<SimilarComic> get similar => _similar;

  /// Whether the trailing page is worth showing at all.
  ///
  /// True as soon as the comic carries a tag, not only when the library
  /// happens to hold something similar: an empty library result is exactly
  /// when looking on the site is most useful, and the button lives on that
  /// page. Still false for a comic with no tags, where neither half has
  /// anything to work with and swiping past the end should keep doing nothing.
  bool get canShowPage => _canShowPage;

  /// Loads the library half. [hasTags] is the comic's own tags, which decide
  /// whether the page exists even when the lookup comes back empty.
  ///
  /// Called once, as soon as the comic is ready rather than on reaching the
  /// end: growing the page count while the reader is already swiping at the
  /// edge would be visible.
  Future<void> load({required bool hasTags}) async {
    final similar = await findSimilar.execute(
      comicId,
      preferences: readPreferences(),
    );
    // The reader can be closed while the lookup is still running, and
    // notifying after that throws.
    if (_disposed) return;
    _similar = similar;
    _canShowPage = hasTags || similar.isNotEmpty;
    notifyListeners();
  }

  /// The site half, run only when the reader asks for it.
  Future<OnlineSimilarResult> findOnline() {
    return findSimilarOnline.execute(comicId, preferences: readPreferences());
  }
}
