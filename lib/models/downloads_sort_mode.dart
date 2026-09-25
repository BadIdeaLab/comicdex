/// How the completed downloads list is ordered.
///
/// The labels live in the UI layer, not here: they are localised, which needs
/// a `BuildContext` an enum cannot hold. Mapping them with a `switch` there
/// also means adding a value without a label fails to compile, rather than
/// quietly showing the wrong text.
enum DownloadsSortMode {
  latestDownloaded,
  lastRead,
  mostFavorited,
  title,
  author,

  /// Ranked by how well the comic's tags match the user's taste (P84).
  /// Local data only, so unlike the home tab there is no pagination to make
  /// the order misleading.
  preference,
}

enum DownloadsSortDirection { descending, ascending }
