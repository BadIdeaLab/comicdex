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
      'Wrong or expired pairing code. The computer refreshes it every 60 seconds, so scan the code again rather than reusing an old screenshot.';

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
  String get backupScanWithCamera => 'Scan pairing code';

  @override
  String get backupScanTitle => 'Scan pairing code';

  @override
  String get backupScanAimHint =>
      'Point the camera at the QR code shown by the backup server on your computer.';

  @override
  String get backupScanCameraDenied =>
      'Camera access is off, so the code cannot be scanned. You can still import a screenshot from your photos, or type the address and PIN.';

  @override
  String get backupScanCameraUnavailable =>
      'The camera is unavailable on this device. You can still import a screenshot from your photos, or type the address and PIN.';

  @override
  String get backupScanUseAnotherWay => 'Pair another way';

  @override
  String get backupImportPairingCode => 'Import pairing code from photos';

  @override
  String backupTryingAddress(String address, int attempt, int total) {
    return 'Trying $address ($attempt of $total)…';
  }

  @override
  String get backupScanNoCodeFound =>
      'No QR code in that image. Pick a screenshot of the Comicdex backup server window.';

  @override
  String get backupScanNotOurCode =>
      'That is not a Comicdex pairing code. Scan the code shown by the backup server on your computer.';

  @override
  String get backupScanNeedsAppUpdate =>
      'That pairing code comes from a newer version of the desktop server. Update this app, then try again.';

  @override
  String get backupScanNoAddresses =>
      'That pairing code contains no address. The computer may have no usable network connection — check it and generate a new code.';

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

  @override
  String get downloadsSortTitle => 'Sort Downloads';

  @override
  String get downloadsSortLatestDownloaded => 'Latest Downloaded';

  @override
  String get downloadsSortLastRead => 'Last Read';

  @override
  String get downloadsSortMostFavorited => 'Most Favorited';

  @override
  String get downloadsSortByTitle => 'Title';

  @override
  String get downloadsSortByAuthor => 'Author';

  @override
  String get downloadsSortByPreference => 'Preference';

  @override
  String get downloadsSortDescending => 'Descending';

  @override
  String get downloadsSortAscending => 'Ascending';

  @override
  String get resetButton => 'Reset';

  @override
  String get downloadsClearTagFilters => 'Clear tags';

  @override
  String downloadsUnknownTag(int tagId) {
    return 'Tag #$tagId';
  }

  @override
  String get downloadsEmpty => 'No downloads yet';

  @override
  String get downloadsEmptyForTags => 'No downloads carry those tags';

  @override
  String downloadsEmptyForQuery(String query) {
    return 'No downloads match \"$query\"';
  }

  @override
  String get downloadsSectionActive => 'Active Downloads';

  @override
  String get downloadsSectionCompleted => 'Completed Downloads';

  @override
  String get downloadsRandomTooltip => 'Open a random completed download';

  @override
  String get downloadsListViewTooltip => 'List view';

  @override
  String get downloadsGridViewTooltip => 'Grid view';

  @override
  String get downloadsRepairAllTooltip => 'Repair all completed downloads';

  @override
  String get downloadsRepairAllTitle => 'Repair all completed downloads?';

  @override
  String get downloadsRepairAllBody =>
      'This scans every completed download for missing pages or a missing cover and re-downloads anything broken. It may take a while and will use network data.';

  @override
  String get downloadsRepairAllConfirm => 'Repair All';

  @override
  String downloadsRepairAllIntact(int total) {
    return 'All $total downloads are intact';
  }

  @override
  String downloadsRepairAllRepaired(int repaired, int total) {
    return 'Repaired $repaired of $total downloads';
  }

  @override
  String downloadsRepairAllStopped(int repaired, int failed, int total) {
    return 'Stopped after repeated failures — repaired $repaired, failed $failed (of $total total)';
  }

  @override
  String downloadsRepairAllMixed(int repaired, int failed, int total) {
    return 'Repaired $repaired, failed $failed, of $total downloads';
  }

  @override
  String downloadsRepairAllError(String error) {
    return 'Repair all failed: $error';
  }

  @override
  String get downloadsDeleteAction => 'Delete Download';

  @override
  String get downloadsReloadAction => 'Reload';

  @override
  String get downloadsRepairAction => 'Repair';

  @override
  String get downloadsDeleteTitle => 'Delete downloaded comic?';

  @override
  String get downloadsDeleteBody =>
      'This deletes the saved download, cover, offline snapshot, and the completed job record.';

  @override
  String get downloadsDeletedMessage => 'Downloaded comic deleted';

  @override
  String get downloadsReloadTitle => 'Reload download?';

  @override
  String get downloadsReloadBody =>
      'This deletes the saved pages and re-downloads the comic from scratch. Reading history and metadata are preserved.';

  @override
  String get downloadsReloadQueued => 'Reload queued';

  @override
  String get downloadsRepairQueued => 'Repair queued';

  @override
  String get downloadsNothingToRepair =>
      'All pages and cover are intact — nothing to repair';

  @override
  String get downloadsPausedMessage => 'Download paused';

  @override
  String get downloadsPauseAction => 'Pause';

  @override
  String get downloadsResumedMessage => 'Download resumed';

  @override
  String get downloadsResumeAction => 'Resume';

  @override
  String get downloadsRemoveJobTitle => 'Remove download job?';

  @override
  String get downloadsRemoveJobBody =>
      'This removes the download job and deletes any partial files already saved.';

  @override
  String get downloadsJobRemovedMessage => 'Download job removed';

  @override
  String get downloadsRemoveAction => 'Remove';

  @override
  String get downloadsRetriedMessage => 'Download retried';

  @override
  String get downloadsRetryAction => 'Retry';

  @override
  String get downloadsRemoveFailedTitle => 'Remove failed download?';

  @override
  String get downloadsRemoveFailedBody =>
      'This removes the failed job and deletes any partial files already saved.';

  @override
  String get downloadsFailedRemovedMessage => 'Failed download removed';

  @override
  String get downloadsStatusDownloading => 'Downloading';

  @override
  String get downloadsStatusQueued => 'Queued';

  @override
  String get downloadsStatusPaused => 'Paused';

  @override
  String get downloadsStatusFailed => 'Failed';

  @override
  String get downloadsStatusCompleted => 'Completed';

  @override
  String downloadsPageCountShort(int count) {
    return '${count}p';
  }

  @override
  String downloadsPageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '1 page',
    );
    return '$_temp0';
  }

  @override
  String get confirmButton => 'Confirm';

  @override
  String get collectionFavorite => 'Favorites';

  @override
  String get collectionNext => 'Next';

  @override
  String get collectionHistory => 'History';

  @override
  String collectionUnknown(String name) {
    return 'Unknown collection: $name';
  }

  @override
  String get collectionSelectComics => 'Select comics';

  @override
  String collectionSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get collectionSelectAll => 'Select all';

  @override
  String get collectionDeselectAll => 'Deselect all';

  @override
  String get collectionDone => 'Done';

  @override
  String get collectionOpenSettings => 'Open Settings';

  @override
  String get collectionLoginFromSettings => 'Login from Settings';

  @override
  String get collectionEmptyForTag => 'No comics here carry that tag';

  @override
  String collectionEmpty(String collection) {
    return 'No comics in $collection';
  }

  @override
  String collectionCollectedCount(int count) {
    return '$count collected';
  }

  @override
  String collectionUnknownTag(int tagId) {
    return 'Tag #$tagId';
  }

  @override
  String get collectionNoneSelected => 'No comics selected';

  @override
  String collectionAllAlreadyDownloaded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'All $count comics are already in Downloads',
      one: 'That comic is already in Downloads',
    );
    return '$_temp0';
  }

  @override
  String collectionDownloadSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Download $count comics',
      one: 'Download 1 comic',
    );
    return '$_temp0';
  }

  @override
  String collectionBatchProgress(int processed, int total) {
    return 'Adding $processed/$total to Downloads…';
  }

  @override
  String collectionBatchQueued(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comics added to Downloads',
      one: '1 comic added to Downloads',
    );
    return '$_temp0';
  }

  @override
  String collectionBatchSkipped(int count) {
    return '$count skipped (already downloaded)';
  }

  @override
  String collectionBatchFailed(int count) {
    return '$count failed';
  }

  @override
  String get collectionBatchStoppedEarly =>
      'stopped early after repeated failures';

  @override
  String tagActionBlock(String tag) {
    return 'Block \"$tag\"';
  }

  @override
  String tagActionUnblock(String tag) {
    return 'Unblock \"$tag\"';
  }

  @override
  String tagActionBlocked(String tag) {
    return '\"$tag\" added to blocked tags';
  }

  @override
  String tagActionUnblocked(String tag) {
    return '\"$tag\" removed from blocked tags';
  }

  @override
  String tagActionSearchFavorites(String tag) {
    return 'Search \"$tag\" in Favorites';
  }

  @override
  String tagActionFilterDownloads(String tag) {
    return 'Filter Downloads by \"$tag\"';
  }

  @override
  String get analysisTitle => 'Tag Analysis';

  @override
  String get analysisNothingKept =>
      'Nothing kept yet. Favorite or download some comics and this page fills in.';

  @override
  String analysisComicsKept(int count) {
    return '$count comics kept';
  }

  @override
  String analysisTaggedRatio(int count, int percent) {
    return '$count of them carry tags ($percent%)';
  }

  @override
  String get analysisCoverageHint =>
      'Everything below is based on the tagged ones. Sync favorites from Settings to fill in the rest.';

  @override
  String get analysisCombinationsTitle => 'Taste Combinations';

  @override
  String get analysisCombinationsHint =>
      'Two or three tags that show up together more often than each tag on its own would suggest. Tap to search them; long-press to filter Downloads by them.';

  @override
  String get tagPreferencesTitle => 'Tag Preferences';

  @override
  String get tagPreferencesFullAnalysis => 'Full analysis ›';

  @override
  String get tagPreferencesEmpty =>
      'No tag data yet. Sync favorites from Settings, or download a few comics, and preferences will build up here.';

  @override
  String get tagPreferencesShowLess => 'Show less';

  @override
  String tagPreferencesShowMore(int count) {
    return 'Show $count more';
  }

  @override
  String get tagSectionTags => 'Tags';

  @override
  String get tagSectionArtists => 'Artists';

  @override
  String get tagSectionParodies => 'Parodies';

  @override
  String get tagSectionCharacters => 'Characters';

  @override
  String get sortMostKept => 'Most kept';

  @override
  String get sortMostDistinctive => 'Most distinctive';

  @override
  String get tagSheetNoTags => 'No tags';

  @override
  String get tagSheetLoadFailed => 'Failed to load tags.';

  @override
  String get tagSheetSelectToSearch => 'Select tags to search';

  @override
  String tagSheetSearchSelected(int count) {
    return 'Search $count tags';
  }

  @override
  String tagActionSearchDownloads(String tag) {
    return 'Search \"$tag\" in Downloads';
  }

  @override
  String get retryButton => 'Retry';

  @override
  String get feedErrorNetwork =>
      'No connection. Check the network and try again.';

  @override
  String get feedErrorForbidden => 'Authentication issue (403).';

  @override
  String get feedErrorNotFound => 'The site had nothing at that address (404).';

  @override
  String get feedErrorServer =>
      'The site is not responding right now. It was tried a few times already — give it a moment.';

  @override
  String get feedErrorUnknown => 'Failed to load comics from the site.';

  @override
  String get readerSettingsTitle => 'Reader Settings';

  @override
  String get readerReadingDirection => 'Reading Direction';

  @override
  String get readerDirectionLtr => 'LTR';

  @override
  String get readerDirectionRtl => 'RTL';

  @override
  String get readerTapZoneWidth => 'Tap zone width';

  @override
  String get readerPrefetchPages => 'Pre-fetch pages (before & after)';

  @override
  String readerPrefetchExplanation(int count) {
    return 'Currently caching $count page(s) on each side of the current page.';
  }

  @override
  String readerResumedFromPage(int page) {
    return 'Resumed from page $page';
  }

  @override
  String get readerGoToStart => 'Go to start';

  @override
  String get readerNotDownloaded =>
      'This comic is not downloaded, so there is nothing to read offline. Download it first, or repair it from the Downloads tab.';

  @override
  String get readerLoadFailed =>
      'Could not load this comic. Check your connection and try again.';

  @override
  String get readerGoBack => 'Go back';

  @override
  String get readerEnd => 'The End';

  @override
  String get readerSettingsTooltip => 'Reader settings';

  @override
  String get readerPreviousPage => 'Previous page';

  @override
  String get readerNextPage => 'Next page';

  @override
  String readerPageOfTotal(int total) {
    return '/ $total';
  }

  @override
  String get searchTabHistory => 'History';

  @override
  String get searchTabTags => 'Tags';

  @override
  String get searchNoHistory => 'No search history';

  @override
  String get searchClearFilter => 'Clear search';

  @override
  String get searchInCategoryHint => 'Search this category';

  @override
  String get searchNoTagsInCategory => 'No tags in this category';

  @override
  String searchNoTagsMatching(String query) {
    return 'No tags match \"$query\"';
  }

  @override
  String searchTagWithCount(String name, int count) {
    return '$name ($count)';
  }

  @override
  String searchSelectedCount(int count) {
    return 'Selected $count';
  }

  @override
  String get homeSearchHint => 'Search comic';

  @override
  String get homeRefreshTooltip => 'Refresh';

  @override
  String get homeCollectionsFailed => 'Failed to load collections';

  @override
  String homeLoadingPage(int page) {
    return 'Loading… page $page';
  }

  @override
  String get downloadsSearchHint => 'Search downloaded comics';

  @override
  String get bootstrapLoading => 'Loading index…';

  @override
  String get sortFilterTitle => 'Sort & Filter';

  @override
  String get sortFilterSortBy => 'Sort by';

  @override
  String get sortFilterLatest => 'Latest';

  @override
  String get sortFilterTagFilters => 'Tag filters';

  @override
  String get sortFilterTagHelp =>
      'Tags are combined with the current search. Format: type:name (e.g. tag:full-color)';

  @override
  String get sortFilterTagHint => 'e.g. tag:full-color';

  @override
  String get sortFilterAddTag => 'Add tag filter';

  @override
  String get comicCardDownload => 'Download';

  @override
  String get comicCardStartingDownload => 'Starting download…';

  @override
  String get comicCardManageInDownloads => 'Manage in Downloads tab';

  @override
  String get comicCardStatusDownloaded => 'Downloaded';

  @override
  String comicCardRemoveFrom(String collection) {
    return 'Remove from $collection';
  }

  @override
  String comicCardRemoveTitle(String collection) {
    return 'Remove this comic from $collection?';
  }

  @override
  String comicCardRemoveBody(String title) {
    return 'Careful! You can\'t undo this action. You are removing: $title';
  }

  @override
  String get comicCardRemoveConfirm => 'REMOVE';

  @override
  String get imageCopyUrl => 'Copy image URL';

  @override
  String get imageLinkCopied => 'Link copied to clipboard';
}
