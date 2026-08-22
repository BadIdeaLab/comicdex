import 'package:concept_nhv/state/download_manager_model.dart';

/// Single entry point for opening the reader.
///
/// Exists to stop a double tap from stacking two reader routes (P65). The
/// reader now owns its own state, so two routes no longer corrupt each other —
/// but two readers for one tap is still wrong, and a second tap is never what
/// the user meant.
///
/// The guard lives here rather than in each caller because the entry points are
/// stateless widgets with nowhere to keep a flag, and because tapping card A
/// then card B must be blocked just as surely as tapping card A twice — a
/// per-widget flag would miss that.
class ReaderLauncher {
  ReaderLauncher({required this.downloadManagerModel});

  final DownloadManagerModel downloadManagerModel;

  bool _opening = false;

  /// True from the moment an open request starts until the reader is closed.
  bool get isOpening => _opening;

  /// Shows the reader, ignoring the request if one is already on screen.
  ///
  /// [show] pushes the route and completes when the reader is popped, which is
  /// why the guard covers the whole reading session.
  ///
  /// Callers must capture whatever they need from their `BuildContext` before
  /// calling this: [show] runs across an await boundary.
  Future<void> open({required Future<void> Function() show}) async {
    if (_opening) return;
    _opening = true;
    try {
      await show();
      // Last-read timestamps and job states change while reading, so the
      // Downloads list needs a refresh once the reader closes.
      await downloadManagerModel.refresh();
    } finally {
      // Must be a finally: anything thrown from `show` would otherwise leave
      // the flag raised and make every later attempt to open any comic
      // silently do nothing — worse than the bug this fixes.
      _opening = false;
    }
  }
}
