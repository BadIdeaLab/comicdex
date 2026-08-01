/// Base for every failure the storage layer reports to the HTTP layer.
///
/// Each subtype maps to exactly one status code so routing code never has to
/// guess (see `BackupServer._statusForException`).
sealed class BackupLibraryException implements Exception {
  const BackupLibraryException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Device id or relative path failed validation — `400`.
///
/// Also covers path traversal attempts (`..`, absolute paths, separators
/// smuggled inside a device id).
class InvalidBackupPathException extends BackupLibraryException {
  const InvalidBackupPathException(super.message);
}

/// Streamed content did not match the `X-Content-Sha256` the client promised —
/// `422`. The partial file is always removed before this is thrown.
class DigestMismatchException extends BackupLibraryException {
  const DigestMismatchException(super.message);
}

/// The configured backup root is missing (external drive unplugged, folder
/// moved, drive letter changed) — `503`.
///
/// Deliberately fatal rather than self-healing: silently falling back to a
/// default location would make the mirror look empty, and the phone would then
/// re-upload the entire library.
class BackupRootUnavailableException extends BackupLibraryException {
  const BackupRootUnavailableException(super.message);
}

/// Ran out of disk space (or the filesystem rejected the write) — `507`.
class BackupStorageException extends BackupLibraryException {
  const BackupStorageException(super.message);
}
