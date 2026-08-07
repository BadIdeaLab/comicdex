// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Comicdex Backup Server';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTraditionalChinese => '繁體中文';

  @override
  String get refreshDevices => 'Refresh addresses and devices';

  @override
  String get connectTitle => 'Connect from your phone';

  @override
  String get connectAddressLabel => 'Address';

  @override
  String get connectPinLabel => 'Pairing PIN';

  @override
  String get connectNewPin => 'New PIN';

  @override
  String get connectPinChangesNote =>
      'The PIN changes every time this app restarts.';

  @override
  String get connectNoNetwork => 'No network connection found';

  @override
  String get connectServerStopped => 'Server is not running.';

  @override
  String get connectVirtualAdapterTag => 'virtual — probably not this one';

  @override
  String get connectCopyAddress => 'Copy address';

  @override
  String connectAddressCopied(String address) {
    return 'Copied $address';
  }

  @override
  String get firewallHint =>
      'No device has connected yet. If your phone cannot reach this machine, check that Windows Firewall is allowing this app on private networks — that prompt is the most common cause, and it looks the same as a wrong address.';

  @override
  String lockedOutHint(String addresses) {
    return 'Temporarily blocked after repeated wrong PINs: $addresses';
  }

  @override
  String get folderTitle => 'Backup folder';

  @override
  String get folderNotSet => '(not set)';

  @override
  String get folderChange => 'Change';

  @override
  String get folderPickConfirm => 'Use this folder';

  @override
  String get folderMissingWarning =>
      'This folder is not available right now (an external drive may be disconnected). Backups are refused until it is back so the phone never mistakes an empty mirror for \"nothing backed up yet\" and re-uploads everything.';

  @override
  String get devicesTitle => 'Backed up devices';

  @override
  String get devicesEmpty => 'Nothing backed up yet.';

  @override
  String devicesSubtitle(int fileCount, String size, int snapshotCount) {
    return '$fileCount files · $size · $snapshotCount database snapshot(s)';
  }

  @override
  String devicesLastSync(String timestamp) {
    return 'last sync $timestamp';
  }

  @override
  String get controlTitle => 'Connected phones';

  @override
  String get controlEmpty =>
      'No phone is connected. Open Backup in the mobile app and pair it first.';

  @override
  String get controlStartBackup => 'Start backup';

  @override
  String get controlPause => 'Pause';

  @override
  String get controlStateIdle => 'Connected · ready';

  @override
  String get controlStateRunning => 'Backing up…';

  @override
  String get controlStatePausing => 'Pausing after the current file…';

  @override
  String get controlStatePaused => 'Paused';

  @override
  String get controlStateCompleted => 'Backup completed';

  @override
  String get controlStateError => 'Backup failed';

  @override
  String get activityTitle => 'Activity';

  @override
  String get activityEmpty => 'Waiting for a device to connect…';

  @override
  String activityFolderChanged(String path) {
    return 'Backup folder changed to $path';
  }

  @override
  String get activityPinRegenerated => 'PIN regenerated';

  @override
  String activityCleanedPartFiles(int count) {
    return 'Cleaned up $count interrupted transfer(s)';
  }

  @override
  String activityDeletedStaleFiles(int count, String deviceId) {
    return 'Deleted $count stale file(s) for $deviceId';
  }

  @override
  String activityReceivedFile(String path, String deviceId) {
    return 'Received $path from $deviceId';
  }

  @override
  String activitySentFile(String path, String deviceId) {
    return 'Sent $path to $deviceId';
  }

  @override
  String activityStoredDatabase(String deviceId) {
    return 'Stored database snapshot for $deviceId';
  }

  @override
  String activitySentDatabase(String deviceId) {
    return 'Sent database snapshot to $deviceId';
  }

  @override
  String activityBlockedPin(String address) {
    return 'Blocked repeated wrong PIN from $address';
  }

  @override
  String activityPruneRequested(String deviceId, int count) {
    return 'Prune requested by $deviceId: $count stale files';
  }

  @override
  String get pruneTitle => 'Delete files the phone no longer has?';

  @override
  String pruneSummary(String deviceId, int count, String size) {
    return '$deviceId asked to clean up $count file(s), freeing $size.';
  }

  @override
  String get pruneExplanation =>
      'These exist in the backup but not on the phone. Deleting is permanent — if they were removed from the phone by mistake, keeping them here is the only remaining copy.';

  @override
  String get pruneKeep => 'Keep everything';

  @override
  String get pruneDelete => 'Delete';

  @override
  String pruneDeletedToast(int count) {
    return 'Deleted $count file(s)';
  }

  @override
  String get controlRestore => 'Restore…';

  @override
  String restoreDialogTitle(String deviceId) {
    return 'Restore $deviceId from a backup?';
  }

  @override
  String get restoreDialogChooseSource =>
      'Which backup should it be restored from?';

  @override
  String get restoreDialogWarning =>
      'The phone will delete downloaded comics that this backup does not contain, then fetch back everything it is missing. Its database is replaced too, and the app restarts when it finishes. The nhentai API key is not part of a backup, so it will need signing in again.';

  @override
  String get restoreDialogNoBackups =>
      'There are no backups on this computer yet.';

  @override
  String get restoreConfirm => 'Restore';

  @override
  String get restoreCancel => 'Cancel';

  @override
  String restoreStarted(String deviceId) {
    return 'Restore started on $deviceId';
  }

  @override
  String get controlStateRestoring => 'Restoring…';

  @override
  String get controlStateRestored =>
      'Restore completed · restart the phone app';

  @override
  String get controlStateRestoreError => 'Restore failed';
}
