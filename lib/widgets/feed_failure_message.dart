import 'package:concept_nhv/application/feed/feed_load_result.dart';
import 'package:concept_nhv/l10n/app_localizations.dart';

/// Turns a [FeedLoadFailure] into something to show the reader.
///
/// Lives in the widget layer because that is where the localisations are; the
/// use case classifies, the UI words it.
String feedFailureMessage(AppLocalizations l10n, FeedLoadFailure failure) {
  return switch (failure) {
    FeedLoadFailure.network => l10n.feedErrorNetwork,
    FeedLoadFailure.forbidden => l10n.feedErrorForbidden,
    FeedLoadFailure.notFound => l10n.feedErrorNotFound,
    FeedLoadFailure.server => l10n.feedErrorServer,
    FeedLoadFailure.unknown => l10n.feedErrorUnknown,
  };
}
