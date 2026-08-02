/// Marks where a stored path stops being container-specific.
const String _downloadsSegment = '/downloads/';

/// Turns a path recorded in a backed-up database into one that can be compared
/// against the server's inventory.
///
/// Two shapes exist in real databases:
///
/// * relative, e.g. `177013/pages/1.webp` — the convention since P51;
/// * absolute, e.g.
///   `/var/mobile/Containers/Data/Application/<uuid>/…/downloads/177013/cover.webp`
///   — written before that convention and still special-cased by
///   `DownloadAssetStore.resolveAbsolutePath`.
///
/// A real backup audited on 2026-08-02 was **41% absolute** (12,345 of 30,101
/// rows). Comparing those raw against an inventory of relative paths silently
/// finds nothing, so a restore would skip that 41% of the library without
/// reporting a single error. Normalising here is what prevents that.
String? normaliseRestorePath(String? stored) {
  if (stored == null) {
    return null;
  }
  // Windows-style separators never occur in these records (they are written on
  // Android/iOS), but normalising costs nothing and keeps comparison total.
  var path = stored.trim().replaceAll(r'\', '/');
  if (path.isEmpty) {
    return null;
  }
  final marker = path.lastIndexOf(_downloadsSegment);
  if (marker >= 0) {
    path = path.substring(marker + _downloadsSegment.length);
  }
  // A leading slash would survive an absolute path that had no `/downloads/`
  // segment at all; such a row cannot be mapped into the mirror.
  if (path.startsWith('/') || path.isEmpty) {
    return null;
  }
  return path;
}

/// Files to pull, given what the backup's database references and what the
/// mirror actually holds.
///
/// The intersection is deliberate: the mirror keeps comics the user has since
/// deleted (it never mirrors deletions), and pulling those back would resurrect
/// them as files the restored database cannot see — pure wasted storage on the
/// very device whose storage pressure motivated this feature.
///
/// [localFiles] lets an interrupted restore resume: anything already present at
/// the right size is skipped.
List<String> computeRestoreDownloadList({
  required Iterable<String?> databasePaths,
  required Map<String, int> remoteInventory,
  Map<String, int> localFiles = const <String, int>{},
}) {
  final wanted = <String>{};
  for (final raw in databasePaths) {
    final path = normaliseRestorePath(raw);
    if (path == null) {
      continue;
    }
    final remoteSize = remoteInventory[path];
    if (remoteSize == null) {
      // Referenced by the database but absent from the mirror — nothing to pull.
      continue;
    }
    if (localFiles[path] == remoteSize) {
      continue;
    }
    wanted.add(path);
  }
  final ordered = wanted.toList()..sort();
  return ordered;
}
