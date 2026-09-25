import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

typedef DownloadDirectoryResolver = Future<Directory> Function();

/// Where a stored download path stops being container-specific.
///
/// Shared with `normaliseRestorePath`, which answers the same question for a
/// backed-up database. Two copies of this constant would drift.
const String kDownloadsSegment = '/downloads/';

/// The part of [storedPath] that identifies a file inside the downloads root,
/// or null when it cannot be worked out.
///
/// Relative paths (the convention since P51) are already that. Absolute ones
/// name some container — possibly another device's — and only the tail after
/// `/downloads/` is portable.
String? relativeDownloadPath(String storedPath) {
  final trimmed = storedPath.trim();
  if (trimmed.isEmpty) return null;

  // Separators are compared, not rebuilt: a row written on Windows holds
  // backslashes, one written on a phone holds slashes, and both name the same
  // file inside the downloads root.
  final normalised = trimmed.replaceAll(r'\', '/');
  final isAbsolute = p.isAbsolute(normalised) || normalised.startsWith('/');
  if (!isAbsolute) {
    return trimmed;
  }

  final marker = normalised.lastIndexOf(kDownloadsSegment);
  if (marker < 0) return null;
  final tail = normalised.substring(marker + kDownloadsSegment.length);
  if (tail.isEmpty) return null;
  // Rebuilt with this platform's separator, so the result can be joined with
  // a local root without ending up half slashes and half backslashes.
  return p.joinAll(tail.split('/'));
}


class DownloadAssetStore {
  DownloadAssetStore({DownloadDirectoryResolver? directoryResolver})
    : _directoryResolver = directoryResolver ?? _defaultDirectoryResolver;

  final DownloadDirectoryResolver _directoryResolver;

  /// The directory every comic folder lives under.
  ///
  /// Exposed for whole-library operations (backup walks the tree); per-comic
  /// callers should use [resolveRootDirectory] instead.
  Future<Directory> resolveDownloadsRoot() => _directoryResolver();

  Future<Directory> resolveRootDirectory(String comicId) async {
    final baseDirectory = await _directoryResolver();
    final comicDirectory = Directory(p.join(baseDirectory.path, comicId));
    await comicDirectory.create(recursive: true);
    return comicDirectory;
  }

  /// Downloads a page and returns its path RELATIVE to the downloads root
  /// (e.g. `"<comicId>/pages/1.jpg"`). Callers must not persist an absolute
  /// path — the app container's root changes across reinstalls (see
  /// .codex/phases/P51-relative-download-paths.md). Resolve to an absolute
  /// path only at the point of use via [resolveAbsolutePath].
  Future<String> savePage({
    required String comicId,
    required int pageNumber,
    required Uint8List bytes,
    required String extension,
  }) async {
    final rootDirectory = await resolveRootDirectory(comicId);
    final pagesDirectory = Directory(p.join(rootDirectory.path, 'pages'));
    await pagesDirectory.create(recursive: true);
    final file = File(p.join(pagesDirectory.path, '$pageNumber.$extension'));
    await file.writeAsBytes(bytes, flush: true);
    return p.join(comicId, 'pages', '$pageNumber.$extension');
  }

  /// Downloads a cover and returns its path RELATIVE to the downloads root
  /// — see [savePage] for why this must not be an absolute path.
  Future<String> saveCover({
    required String comicId,
    required Uint8List bytes,
    required String extension,
  }) async {
    final rootDirectory = await resolveRootDirectory(comicId);
    final file = File(p.join(rootDirectory.path, 'cover.$extension'));
    await file.writeAsBytes(bytes, flush: true);
    return p.join(comicId, 'cover.$extension');
  }

  /// Resolves a path stored in the database to an absolute filesystem path
  /// rooted at the CURRENT app container's downloads directory.
  ///
  /// Paths written before the relative-path convention are absolute and name
  /// a container that may no longer exist: a different device after a
  /// restore, or the same device after a reinstall changed the container id
  /// (the reason for P51). Those are re-rooted here by keeping everything
  /// after the `/downloads/` segment, so the bytes already sitting on this
  /// device are found instead of reported missing. On a container that has
  /// not moved this produces exactly the same path as before, because the
  /// tail is what identifies the file either way.
  ///
  /// An absolute path with no `/downloads/` segment cannot be mapped, so it
  /// is returned unchanged rather than guessed at.
  Future<String> resolveAbsolutePath(String storedPath) async {
    final relative = relativeDownloadPath(storedPath);
    if (relative == null) {
      return storedPath;
    }
    final baseDirectory = await _directoryResolver();
    return p.join(baseDirectory.path, relative);
  }

  /// Returns the page numbers (1-based) that are missing or empty on disk.
  ///
  /// A page is considered missing if its file does not exist or its size is 0.
  /// [pageLocalPaths] maps page number → local path recorded in the DB
  /// (relative or, for legacy rows, absolute — both handled via
  /// [resolveAbsolutePath]).
  Future<List<int>> verifyPages(Map<int, String?> pageLocalPaths) async {
    final missing = <int>[];
    for (final entry in pageLocalPaths.entries) {
      final localPath = entry.value;
      if (localPath == null || localPath.isEmpty) {
        missing.add(entry.key);
        continue;
      }
      final file = File(await resolveAbsolutePath(localPath));
      if (!await file.exists() || await file.length() == 0) {
        missing.add(entry.key);
      }
    }
    missing.sort();
    return missing;
  }

  /// Returns true if [coverLocalPath] (relative or legacy absolute — see
  /// [resolveAbsolutePath]) points to an existing, non-empty file.
  Future<bool> coverExists(String? coverLocalPath) async {
    if (coverLocalPath == null || coverLocalPath.isEmpty) {
      return false;
    }
    final file = File(await resolveAbsolutePath(coverLocalPath));
    return await file.exists() && await file.length() > 0;
  }

  Future<void> deleteComicAssets(String comicId) async {
    final rootDirectory = Directory(
      p.join((await _directoryResolver()).path, comicId),
    );
    if (await rootDirectory.exists()) {
      await rootDirectory.delete(recursive: true);
    }
  }

  static Future<Directory> _defaultDirectoryResolver() async {
    final supportDirectory = await getApplicationSupportDirectory();
    final downloadsDirectory = Directory(
      p.join(supportDirectory.path, 'downloads'),
    );
    await downloadsDirectory.create(recursive: true);
    return downloadsDirectory;
  }
}
