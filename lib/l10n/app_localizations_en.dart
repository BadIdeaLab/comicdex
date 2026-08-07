// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionNhentaiApi => 'nhentai API';

  @override
  String get sectionReader => 'Reader';

  @override
  String get sectionDownloads => 'Downloads';

  @override
  String get sectionBlockedTags => 'Blocked Tags';

  @override
  String get sectionTagDatabase => 'Tag Database';

  @override
  String get sectionGeneral => 'General';

  @override
  String get sectionAbout => 'About';

  @override
  String get autoResumeDownloadsTitle => 'Auto Resume Downloads';

  @override
  String get autoResumeDownloadsSubtitle =>
      'Resume interrupted downloads when the app returns to foreground or restarts';

  @override
  String get pageDownloadIntervalTitle => 'Page Download Interval';

  @override
  String get appliesToNewDownloadsNote =>
      'Applies to new downloads or after resume';

  @override
  String get statusTitle => 'Status';

  @override
  String get statusAuthenticated => 'Authenticated';

  @override
  String get statusNotConfigured => 'Not configured';

  @override
  String statusSyncingWithProgress(int page, int total) {
    return 'Syncing... page $page / $total';
  }

  @override
  String get statusSyncingGeneric => 'Syncing...';

  @override
  String statusRateLimitedRetrying(int seconds) {
    return 'Rate limited, retrying in ${seconds}s...';
  }

  @override
  String statusLastSync(String value) {
    return 'Last sync: $value';
  }

  @override
  String get statusNeverSynced => 'Never';

  @override
  String get setUpdateApiKeyTitle => 'Set / Update API Key';

  @override
  String get setUpdateApiKeySubtitle =>
      'Paste your personal nhentai API key from account settings';

  @override
  String get apiKeySavedMessage => 'API key saved and validated';

  @override
  String get syncFavoritesNowTitle => 'Sync Favorites Now';

  @override
  String get syncFavoritesNowSubtitle =>
      'Refresh the local favorite cache from the official API';

  @override
  String get favoritesSyncedMessage => 'Favorites synced from API';

  @override
  String get syncFailedMessage => 'Sync failed';

  @override
  String get clearApiKeyTitle => 'Clear API Key';

  @override
  String get clearApiKeySubtitle =>
      'Remove the saved API key from secure storage';

  @override
  String get clearApiKeyDialogTitle => 'Clear API key?';

  @override
  String get clearApiKeyDialogContent =>
      'This removes the saved API key from secure storage. You will need to enter it again to sync favorites.';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get clearButton => 'Clear';

  @override
  String get apiKeyClearedMessage => 'API key cleared';

  @override
  String get updateApiKeyDialogTitle => 'Update API Key';

  @override
  String get setApiKeyDialogTitle => 'Set API Key';

  @override
  String get apiKeyFieldLabel => 'API Key';

  @override
  String get apiKeyFieldHint => 'Paste your nhentai API key';

  @override
  String get saveButton => 'Save';

  @override
  String get prefetchPagesTitle => 'Pre-fetch Pages';

  @override
  String prefetchPagesSubtitle(int count, int defaultCount) {
    return 'Cache $count page(s) before and after the current page (default: $defaultCount)';
  }

  @override
  String prefetchDialogBody(int count) {
    return 'Pre-cache $count page(s) before and after the current page.';
  }

  @override
  String get clearImageCacheTitle => 'Clear Image Cache';

  @override
  String get clearImageCacheSubtitle =>
      'Delete all cached comic images from disk';

  @override
  String get imageCacheClearedMessage => 'Image cache cleared';

  @override
  String get noBlockedTagsMessage =>
      'No blocked tags. Long-press a tag on a comic to block it.';

  @override
  String get removeTooltip => 'Remove';

  @override
  String get checkForTagDatabaseUpdatesTitle =>
      'Check for Tag Database Updates';

  @override
  String tagDatabaseSubtitle(int count, String version, String origin) {
    return '$count tags loaded (version $version, $origin)';
  }

  @override
  String get tagDatabaseOriginBundled => 'bundled';

  @override
  String get tagDatabaseOriginUpdated => 'updated';

  @override
  String get tagDatabaseCheckFailedMessage =>
      'Failed to check for tag database updates';

  @override
  String get tagDatabaseUpToDateMessage => 'Tag database is already up to date';

  @override
  String get tagDatabaseUpdateAvailableDialogTitle =>
      'Tag Database Update Available';

  @override
  String tagDatabaseUpdateAvailableDialogContent(String version) {
    return 'A newer tag database is available ($version). Download and apply it now? (a few MB)';
  }

  @override
  String get updateButton => 'Update';

  @override
  String tagDatabaseUpdatedMessage(int count) {
    return 'Tag database updated ($count tags)';
  }

  @override
  String get tagDatabaseUpdateFailedMessage =>
      'Failed to download tag database update';

  @override
  String get appLanguageTitle => 'App Language';

  @override
  String get appLanguageSystemDefault => 'System Default';

  @override
  String get appLanguageEnglish => 'English';

  @override
  String get appLanguageTraditionalChinese => '繁體中文';

  @override
  String appLanguageChangedMessage(String name) {
    return 'App language set to $name';
  }

  @override
  String get diagnoseTitle => 'Diagnose';

  @override
  String get diagnoseSubtitle => 'Reserved for future diagnostics';

  @override
  String get loadJsonNetworkTitle => 'Load json (network)';

  @override
  String get enterUrlDialogTitle => 'Enter URL';

  @override
  String get urlFieldLabel => 'URL';

  @override
  String get openSourceLicensesTitle => 'Open Source Licenses';

  @override
  String get secondsFieldLabel => 'Seconds';

  @override
  String get secondsFieldSuffix => 's';

  @override
  String presetSecondsLabel(String seconds) {
    return '$seconds s';
  }

  @override
  String get applyButton => 'Apply';

  @override
  String get enterNumberErrorMessage => 'Enter a number in seconds';

  @override
  String get onlyNumericErrorMessage =>
      'Only plain numeric seconds are supported';

  @override
  String get valueMustBeZeroOrMoreErrorMessage =>
      'Value must be 0 seconds or more';

  @override
  String get sectionBackup => 'Backup';

  @override
  String get backupTileTitle => 'Connect to your computer';

  @override
  String get backupTileSubtitle =>
      'Pair with the Comicdex backup server; control backup and restore on the computer';

  @override
  String get backupScreenTitle => 'Connect to computer';

  @override
  String get backupAddressLabel => 'Address (shown on the computer)';

  @override
  String get backupAddressHint => '192.168.1.20:8787';

  @override
  String get backupPinLabel => 'Pairing PIN';

  @override
  String get backupDeviceNameLabel => 'This device\'s name';

  @override
  String get backupDeviceNameHelp =>
      'Names this device\'s folder on the computer. Backups can still be restored onto any device.';

  @override
  String get backupStartButton => 'Start backup';

  @override
  String get backupConnectButton => 'Connect';

  @override
  String get backupDisconnectButton => 'Disconnect';

  @override
  String get backupDesktopControlsNote =>
      'Once connected, start or pause backups and restores from the computer; this phone runs the transfer and reports progress back.';

  @override
  String get backupKeepForegroundNote =>
      'Keep the app in the foreground while connected or transferring. Mobile operating systems may suspend a background app.';

  @override
  String get backupControlDisconnected => 'Not connected';

  @override
  String get backupControlReady =>
      'Connected · waiting for a command from the computer';

  @override
  String get backupControlRunning => 'Backup started by the computer';

  @override
  String get backupControlPausing => 'Pausing after the current file…';

  @override
  String get backupControlPaused => 'Backup paused';

  @override
  String get backupControlCompleted => 'Backup completed';

  @override
  String get backupControlError => 'Connection or backup failed';

  @override
  String get backupStageConnecting => 'Connecting…';

  @override
  String get backupStageSnapshot => 'Preparing database…';

  @override
  String get backupStageComparing => 'Checking what the computer already has…';

  @override
  String backupStageUploading(int current, int total) {
    return 'Uploading $current of $total';
  }

  @override
  String get backupErrorInvalidAddress =>
      'Enter the address exactly as shown on the computer, for example 192.168.1.20:8787';

  @override
  String get backupErrorMissingFields =>
      'Fill in the address, PIN, and device name';

  @override
  String get backupErrorWrongPin =>
      'Wrong PIN. Check the number shown on the computer — it changes every time that app restarts.';

  @override
  String get backupErrorLockedOut =>
      'Too many wrong PINs. Wait a few minutes, then try again.';

  @override
  String get backupErrorUnreachable =>
      'Could not reach that computer. Check you are on the same Wi-Fi, that the address is right, and that Windows Firewall is allowing the server app.';

  @override
  String backupErrorGeneric(String message) {
    return 'Backup failed: $message';
  }

  @override
  String backupSummaryUploaded(int uploaded) {
    return 'Backed up $uploaded file(s)';
  }

  @override
  String backupSummarySkipped(int skipped) {
    return '$skipped already on the computer';
  }

  @override
  String backupSummaryFailed(int failed) {
    return '$failed failed — run the backup again to retry just those';
  }

  @override
  String backupSummaryInFlight(int count) {
    return '$count comic(s) still downloading were skipped this time';
  }

  @override
  String get backupApiKeyNote =>
      'Your nhentai API key is not included in backups. You will sign in again after restoring.';

  @override
  String get backupErrorPairingRejected =>
      'The computer accepted the PIN but refused to pair. This usually means the device name contains characters it will not accept — try a simpler name using letters, digits, spaces, dots or hyphens.';

  @override
  String get restoreInterruptedTitle => 'Restore did not finish';

  @override
  String restoreInterruptedBody(String sourceDeviceId) {
    return 'A restore from \"$sourceDeviceId\" was interrupted. Some downloaded comics were removed to make room and have not been fetched back yet, so parts of your library may not open. Run the restore again from the computer to finish it.';
  }

  @override
  String get restoreInterruptedDismiss => 'Remind me again';

  @override
  String get restoreInterruptedAcknowledge => 'I understand';

  @override
  String get restoreDoneTitle => 'Restore finished';

  @override
  String get restoreDoneBody =>
      'Your library has been restored. The app must be restarted to load the restored database — until then it is still showing the old one.';

  @override
  String get restoreDoneCloseApp => 'Close the app';

  @override
  String get restoreDoneManualHint =>
      'Please close this app completely and open it again.';

  @override
  String get backupControlRestoreDone => 'Restore finished · restart required';

  @override
  String get backupControlRestoreRunning => 'The computer started a restore';

  @override
  String get backupControlRestorePaused => 'Restore paused';

  @override
  String get backupControlRestoreError => 'Connection or restore failed';
}
