import 'package:concept_nhv/models/comic.dart';

/// Why a feed request failed, as a classification rather than a sentence.
///
/// The wording belongs to the UI, which is the only layer with a
/// `BuildContext` to localise it. Keeping the kind here also lets the caller
/// tell a momentary failure from a permanent one without matching on prose.
enum FeedLoadFailure {
  /// No usable connection — retrying now would not help.
  network,

  /// The API key is missing or rejected (403).
  forbidden,

  /// The endpoint answered that there is nothing there (404).
  notFound,

  /// The server is momentarily unable to answer (5xx, timeouts). Already
  /// retried before reaching here, so it has been failing for a few seconds.
  server,

  unknown,
}

class FeedLoadResult {
  const FeedLoadResult({
    required this.comics,
    required this.pageLoaded,
    required this.noMorePage,
    required this.statusCode,
    this.numPages,
    this.failure,
  });

  final List<Comic> comics;
  final int pageLoaded;

  /// The server answered, and there was nothing more to send.
  ///
  /// Strictly "the end of the results" — never "the request failed". They
  /// were the same flag once, and one gateway timeout switched off infinite
  /// scrolling for the rest of the session (P89).
  final bool noMorePage;

  final int statusCode;
  final int? numPages;
  final FeedLoadFailure? failure;

  bool get hasFailed => failure != null;
}
