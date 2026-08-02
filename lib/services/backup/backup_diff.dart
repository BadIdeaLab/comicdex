import 'package:concept_nhv/services/backup/backup_models.dart';

/// Decides what still needs uploading.
///
/// Identity is `relative path + size`, deliberately not a content hash. A
/// downloaded page never changes once written, so the pair is enough — whereas
/// hashing every file on every backup would mean reading the entire library
/// from disk each time, which is exactly the slow, battery-hungry work this
/// design avoids. A hash is still computed for each file actually transferred,
/// to verify that one transfer.
List<LocalBackupFile> computeUploadList({
  required List<LocalBackupFile> localFiles,
  required Map<String, int> remoteInventory,
}) {
  return localFiles.where((file) {
    final remoteSize = remoteInventory[file.relativePath];
    // Absent, or present at a different size (e.g. re-downloaded at another
    // quality, or a previous transfer stored something truncated).
    return remoteSize == null || remoteSize != file.sizeBytes;
  }).toList(growable: false);
}
