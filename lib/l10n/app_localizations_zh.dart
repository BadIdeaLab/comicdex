// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get settingsTitle => '設定';

  @override
  String get sectionNhentaiApi => 'nhentai API';

  @override
  String get sectionReader => '閱讀器';

  @override
  String get sectionDownloads => '下載';

  @override
  String get sectionBlockedTags => '已封鎖標籤';

  @override
  String get sectionTagDatabase => '標籤資料庫';

  @override
  String get sectionGeneral => '一般';

  @override
  String get sectionAbout => '關於';

  @override
  String get autoResumeDownloadsTitle => '自動繼續下載';

  @override
  String get autoResumeDownloadsSubtitle => 'App 回到前景或重新啟動時自動繼續中斷的下載';

  @override
  String get pageDownloadIntervalTitle => '頁面下載間隔';

  @override
  String get appliesToNewDownloadsNote => '套用於新的下載或繼續下載時';

  @override
  String get statusTitle => '狀態';

  @override
  String get statusAuthenticated => '已驗證';

  @override
  String get statusNotConfigured => '尚未設定';

  @override
  String statusSyncingWithProgress(int page, int total) {
    return '同步中... 第 $page / $total 頁';
  }

  @override
  String get statusSyncingGeneric => '同步中...';

  @override
  String statusRateLimitedRetrying(int seconds) {
    return '已達速率限制，$seconds 秒後重試...';
  }

  @override
  String statusLastSync(String value) {
    return '上次同步：$value';
  }

  @override
  String get statusNeverSynced => '從未同步';

  @override
  String get setUpdateApiKeyTitle => '設定 / 更新 API Key';

  @override
  String get setUpdateApiKeySubtitle => '貼上你在 nhentai 帳號設定裡取得的個人 API Key';

  @override
  String get apiKeySavedMessage => 'API Key 已儲存並驗證成功';

  @override
  String get syncFavoritesNowTitle => '立即同步收藏';

  @override
  String get syncFavoritesNowSubtitle => '從官方 API 重新整理本機收藏快取';

  @override
  String get favoritesSyncedMessage => '已從 API 同步收藏';

  @override
  String get syncFailedMessage => '同步失敗';

  @override
  String get clearApiKeyTitle => '清除 API Key';

  @override
  String get clearApiKeySubtitle => '從安全儲存區移除已儲存的 API Key';

  @override
  String get clearApiKeyDialogTitle => '要清除 API Key 嗎？';

  @override
  String get clearApiKeyDialogContent =>
      '這會從安全儲存區移除已儲存的 API Key，之後要同步收藏時需要重新輸入。';

  @override
  String get cancelButton => '取消';

  @override
  String get clearButton => '清除';

  @override
  String get apiKeyClearedMessage => 'API Key 已清除';

  @override
  String get updateApiKeyDialogTitle => '更新 API Key';

  @override
  String get setApiKeyDialogTitle => '設定 API Key';

  @override
  String get apiKeyFieldLabel => 'API Key';

  @override
  String get apiKeyFieldHint => '貼上你的 nhentai API Key';

  @override
  String get saveButton => '儲存';

  @override
  String get prefetchPagesTitle => '預先載入頁數';

  @override
  String prefetchPagesSubtitle(int count, int defaultCount) {
    return '預先快取目前頁面前後 $count 頁（預設：$defaultCount）';
  }

  @override
  String prefetchDialogBody(int count) {
    return '預先快取目前頁面前後 $count 頁。';
  }

  @override
  String get clearImageCacheTitle => '清除圖片快取';

  @override
  String get clearImageCacheSubtitle => '刪除磁碟上所有已快取的漫畫圖片';

  @override
  String get imageCacheClearedMessage => '圖片快取已清除';

  @override
  String get noBlockedTagsMessage => '沒有已封鎖的標籤。長按漫畫上的標籤即可封鎖。';

  @override
  String get removeTooltip => '移除';

  @override
  String get checkForTagDatabaseUpdatesTitle => '檢查標籤資料庫更新';

  @override
  String tagDatabaseSubtitle(int count, String version, String origin) {
    return '已載入 $count 筆標籤（版本 $version，$origin）';
  }

  @override
  String get tagDatabaseOriginBundled => '內建';

  @override
  String get tagDatabaseOriginUpdated => '已更新';

  @override
  String get tagDatabaseCheckFailedMessage => '檢查標籤資料庫更新失敗';

  @override
  String get tagDatabaseUpToDateMessage => '標籤資料庫已是最新版本';

  @override
  String get tagDatabaseUpdateAvailableDialogTitle => '有標籤資料庫更新可用';

  @override
  String tagDatabaseUpdateAvailableDialogContent(String version) {
    return '有較新的標籤資料庫可用（$version）。要立即下載並套用嗎？（數 MB）';
  }

  @override
  String get updateButton => '更新';

  @override
  String tagDatabaseUpdatedMessage(int count) {
    return '標籤資料庫已更新（$count 筆）';
  }

  @override
  String get tagDatabaseUpdateFailedMessage => '下載標籤資料庫更新失敗';

  @override
  String get appLanguageTitle => 'App 顯示語言';

  @override
  String get appLanguageSystemDefault => '跟隨系統';

  @override
  String get appLanguageEnglish => 'English';

  @override
  String get appLanguageTraditionalChinese => '繁體中文';

  @override
  String appLanguageChangedMessage(String name) {
    return 'App 語言已設為 $name';
  }

  @override
  String get diagnoseTitle => '診斷';

  @override
  String get diagnoseSubtitle => '保留給未來的診斷功能使用';

  @override
  String get loadJsonNetworkTitle => '載入 json（網路）';

  @override
  String get enterUrlDialogTitle => '輸入網址';

  @override
  String get urlFieldLabel => '網址';

  @override
  String get openSourceLicensesTitle => '開放原始碼授權';

  @override
  String get secondsFieldLabel => '秒數';

  @override
  String get secondsFieldSuffix => '秒';

  @override
  String presetSecondsLabel(String seconds) {
    return '$seconds 秒';
  }

  @override
  String get applyButton => '套用';

  @override
  String get enterNumberErrorMessage => '請輸入秒數';

  @override
  String get onlyNumericErrorMessage => '只能輸入純數字秒數';

  @override
  String get valueMustBeZeroOrMoreErrorMessage => '數值必須大於等於 0 秒';

  @override
  String get sectionBackup => '備份';

  @override
  String get backupTileTitle => '備份到電腦';

  @override
  String get backupTileSubtitle => '透過 Wi-Fi 把書庫傳到 Comicdex 備份伺服器';

  @override
  String get backupScreenTitle => '備份到電腦';

  @override
  String get backupAddressLabel => '位址（電腦畫面上顯示的）';

  @override
  String get backupAddressHint => '192.168.1.20:8787';

  @override
  String get backupPinLabel => '配對碼';

  @override
  String get backupDeviceNameLabel => '這台裝置的名稱';

  @override
  String get backupDeviceNameHelp => '決定電腦上這台裝置的資料夾名稱。備份仍然可以還原到任何裝置。';

  @override
  String get backupStartButton => '開始備份';

  @override
  String get backupConnectButton => '連線';

  @override
  String get backupDisconnectButton => '中斷連線';

  @override
  String get backupDesktopControlsNote =>
      '連線後請在電腦端開始或暫停備份與還原；手機會執行傳輸，並把進度回報到電腦。';

  @override
  String get backupKeepForegroundNote => '備份期間請保持這個畫面開著。書庫較大時會需要一段時間。';

  @override
  String get backupControlDisconnected => '尚未連線';

  @override
  String get backupControlReady => '已連線，等待電腦端命令';

  @override
  String get backupControlRunning => '電腦端已開始備份';

  @override
  String get backupControlPausing => '目前檔案完成後暫停…';

  @override
  String get backupControlPaused => '備份已暫停';

  @override
  String get backupControlCompleted => '備份完成';

  @override
  String get backupControlError => '連線或備份失敗';

  @override
  String get backupStageConnecting => '連線中…';

  @override
  String get backupStageSnapshot => '準備資料庫中…';

  @override
  String get backupStageComparing => '比對電腦上已有的檔案…';

  @override
  String backupStageUploading(int current, int total) {
    return '上傳中 $current / $total';
  }

  @override
  String get backupErrorInvalidAddress => '請照電腦畫面上顯示的格式輸入，例如 192.168.1.20:8787';

  @override
  String get backupErrorMissingFields => '請填寫位址、配對碼與裝置名稱';

  @override
  String get backupErrorWrongPin => '配對碼錯誤或已過期。電腦每 60 秒會刷新一次，請重新掃描，不要沿用舊的截圖。';

  @override
  String get backupErrorLockedOut => '配對碼錯誤太多次，請等幾分鐘後再試。';

  @override
  String get backupErrorUnreachable =>
      '連不到那台電腦。請確認手機和電腦在同一個 Wi-Fi、位址正確，以及 Windows 防火牆有允許那個伺服器程式。';

  @override
  String backupErrorGeneric(String message) {
    return '備份失敗：$message';
  }

  @override
  String backupSummaryUploaded(int uploaded) {
    return '已備份 $uploaded 個檔案';
  }

  @override
  String backupSummarySkipped(int skipped) {
    return '$skipped 個電腦上已經有了';
  }

  @override
  String backupSummaryFailed(int failed) {
    return '$failed 個失敗——再執行一次備份就會只補傳這些';
  }

  @override
  String backupSummaryInFlight(int count) {
    return '有 $count 本仍在下載中，這次略過';
  }

  @override
  String get backupApiKeyNote => '備份不包含 nhentai API 金鑰，還原後需要重新登入。';

  @override
  String get backupScanWithCamera => '掃描配對碼';

  @override
  String get backupScanTitle => '掃描配對碼';

  @override
  String get backupScanAimHint => '把鏡頭對準電腦上備份伺服器顯示的 QR code。';

  @override
  String get backupScanCameraDenied => '相機權限未開啟，無法掃描。你仍然可以從相簿匯入截圖，或手動輸入位址與配對碼。';

  @override
  String get backupScanCameraUnavailable =>
      '這台裝置的相機無法使用。你仍然可以從相簿匯入截圖，或手動輸入位址與配對碼。';

  @override
  String get backupScanUseAnotherWay => '改用其他方式配對';

  @override
  String get backupImportPairingCode => '從相簿匯入配對碼';

  @override
  String backupTryingAddress(String address, int attempt, int total) {
    return '正在嘗試 $address（第 $attempt 個，共 $total 個）…';
  }

  @override
  String get backupScanNoCodeFound =>
      '這張圖片裡沒有 QR code。請選擇 Comicdex 備份伺服器視窗的截圖。';

  @override
  String get backupScanNotOurCode => '這不是 Comicdex 的配對碼。請掃描電腦上備份伺服器顯示的那個碼。';

  @override
  String get backupScanNeedsAppUpdate => '這個配對碼來自較新版的電腦端伺服器。請先更新這個 App 再試一次。';

  @override
  String get backupScanNoAddresses => '這個配對碼裡沒有位址。那台電腦可能沒有可用的網路連線——請確認後重新產生一組。';

  @override
  String get backupErrorPairingRejected =>
      '電腦接受了配對碼，但拒絕建立連線。通常是裝置名稱含有它不接受的字元——請改用只有英數字、空格、點或連字號的簡單名稱。';

  @override
  String get restoreInterruptedTitle => '還原沒有完成';

  @override
  String restoreInterruptedBody(String sourceDeviceId) {
    return '從「$sourceDeviceId」的還原被中斷了。部分已下載的漫畫為了騰出空間而被移除，但還沒補回來，所以書庫有些內容可能打不開。請到電腦端重新執行一次還原把它完成。';
  }

  @override
  String get restoreInterruptedDismiss => '下次再提醒我';

  @override
  String get restoreInterruptedAcknowledge => '我知道了';

  @override
  String get restoreDoneTitle => '還原完成';

  @override
  String get restoreDoneBody =>
      '圖庫已經還原完畢。必須重新啟動 App 才會載入還原後的資料庫——在那之前畫面上顯示的仍然是舊的。';

  @override
  String get restoreDoneCloseApp => '關閉 App';

  @override
  String get restoreDoneManualHint => '請完全關閉這個 App，然後重新開啟。';

  @override
  String get backupControlRestoreDone => '還原完成 · 需要重新啟動';

  @override
  String get backupControlRestoreRunning => '電腦端已開始還原';

  @override
  String get backupControlRestorePaused => '還原已暫停';

  @override
  String get backupControlRestoreError => '連線或還原失敗';

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
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get settingsTitle => '設定';

  @override
  String get sectionNhentaiApi => 'nhentai API';

  @override
  String get sectionReader => '閱讀器';

  @override
  String get sectionDownloads => '下載';

  @override
  String get sectionBlockedTags => '已封鎖標籤';

  @override
  String get sectionTagDatabase => '標籤資料庫';

  @override
  String get sectionGeneral => '一般';

  @override
  String get sectionAbout => '關於';

  @override
  String get autoResumeDownloadsTitle => '自動繼續下載';

  @override
  String get autoResumeDownloadsSubtitle => 'App 回到前景或重新啟動時自動繼續中斷的下載';

  @override
  String get pageDownloadIntervalTitle => '頁面下載間隔';

  @override
  String get appliesToNewDownloadsNote => '套用於新的下載或繼續下載時';

  @override
  String get statusTitle => '狀態';

  @override
  String get statusAuthenticated => '已驗證';

  @override
  String get statusNotConfigured => '尚未設定';

  @override
  String statusSyncingWithProgress(int page, int total) {
    return '同步中... 第 $page / $total 頁';
  }

  @override
  String get statusSyncingGeneric => '同步中...';

  @override
  String statusRateLimitedRetrying(int seconds) {
    return '已達速率限制，$seconds 秒後重試...';
  }

  @override
  String statusLastSync(String value) {
    return '上次同步：$value';
  }

  @override
  String get statusNeverSynced => '從未同步';

  @override
  String get setUpdateApiKeyTitle => '設定 / 更新 API Key';

  @override
  String get setUpdateApiKeySubtitle => '貼上你在 nhentai 帳號設定裡取得的個人 API Key';

  @override
  String get apiKeySavedMessage => 'API Key 已儲存並驗證成功';

  @override
  String get syncFavoritesNowTitle => '立即同步收藏';

  @override
  String get syncFavoritesNowSubtitle => '從官方 API 重新整理本機收藏快取';

  @override
  String get favoritesSyncedMessage => '已從 API 同步收藏';

  @override
  String get syncFailedMessage => '同步失敗';

  @override
  String get clearApiKeyTitle => '清除 API Key';

  @override
  String get clearApiKeySubtitle => '從安全儲存區移除已儲存的 API Key';

  @override
  String get clearApiKeyDialogTitle => '要清除 API Key 嗎？';

  @override
  String get clearApiKeyDialogContent =>
      '這會從安全儲存區移除已儲存的 API Key，之後要同步收藏時需要重新輸入。';

  @override
  String get cancelButton => '取消';

  @override
  String get clearButton => '清除';

  @override
  String get apiKeyClearedMessage => 'API Key 已清除';

  @override
  String get updateApiKeyDialogTitle => '更新 API Key';

  @override
  String get setApiKeyDialogTitle => '設定 API Key';

  @override
  String get apiKeyFieldLabel => 'API Key';

  @override
  String get apiKeyFieldHint => '貼上你的 nhentai API Key';

  @override
  String get saveButton => '儲存';

  @override
  String get prefetchPagesTitle => '預先載入頁數';

  @override
  String prefetchPagesSubtitle(int count, int defaultCount) {
    return '預先快取目前頁面前後 $count 頁（預設：$defaultCount）';
  }

  @override
  String prefetchDialogBody(int count) {
    return '預先快取目前頁面前後 $count 頁。';
  }

  @override
  String get clearImageCacheTitle => '清除圖片快取';

  @override
  String get clearImageCacheSubtitle => '刪除磁碟上所有已快取的漫畫圖片';

  @override
  String get imageCacheClearedMessage => '圖片快取已清除';

  @override
  String get noBlockedTagsMessage => '沒有已封鎖的標籤。長按漫畫上的標籤即可封鎖。';

  @override
  String get removeTooltip => '移除';

  @override
  String get checkForTagDatabaseUpdatesTitle => '檢查標籤資料庫更新';

  @override
  String tagDatabaseSubtitle(int count, String version, String origin) {
    return '已載入 $count 筆標籤（版本 $version，$origin）';
  }

  @override
  String get tagDatabaseOriginBundled => '內建';

  @override
  String get tagDatabaseOriginUpdated => '已更新';

  @override
  String get tagDatabaseCheckFailedMessage => '檢查標籤資料庫更新失敗';

  @override
  String get tagDatabaseUpToDateMessage => '標籤資料庫已是最新版本';

  @override
  String get tagDatabaseUpdateAvailableDialogTitle => '有標籤資料庫更新可用';

  @override
  String tagDatabaseUpdateAvailableDialogContent(String version) {
    return '有較新的標籤資料庫可用（$version）。要立即下載並套用嗎？（數 MB）';
  }

  @override
  String get updateButton => '更新';

  @override
  String tagDatabaseUpdatedMessage(int count) {
    return '標籤資料庫已更新（$count 筆）';
  }

  @override
  String get tagDatabaseUpdateFailedMessage => '下載標籤資料庫更新失敗';

  @override
  String get appLanguageTitle => 'App 顯示語言';

  @override
  String get appLanguageSystemDefault => '跟隨系統';

  @override
  String get appLanguageEnglish => 'English';

  @override
  String get appLanguageTraditionalChinese => '繁體中文';

  @override
  String appLanguageChangedMessage(String name) {
    return 'App 語言已設為 $name';
  }

  @override
  String get diagnoseTitle => '診斷';

  @override
  String get diagnoseSubtitle => '保留給未來的診斷功能使用';

  @override
  String get loadJsonNetworkTitle => '載入 json（網路）';

  @override
  String get enterUrlDialogTitle => '輸入網址';

  @override
  String get urlFieldLabel => '網址';

  @override
  String get openSourceLicensesTitle => '開放原始碼授權';

  @override
  String get secondsFieldLabel => '秒數';

  @override
  String get secondsFieldSuffix => '秒';

  @override
  String presetSecondsLabel(String seconds) {
    return '$seconds 秒';
  }

  @override
  String get applyButton => '套用';

  @override
  String get enterNumberErrorMessage => '請輸入秒數';

  @override
  String get onlyNumericErrorMessage => '只能輸入純數字秒數';

  @override
  String get valueMustBeZeroOrMoreErrorMessage => '數值必須大於等於 0 秒';

  @override
  String get sectionBackup => '備份';

  @override
  String get backupTileTitle => '連線到電腦';

  @override
  String get backupTileSubtitle => '與 Comicdex 備份伺服器配對，並從電腦端控制備份與還原';

  @override
  String get backupScreenTitle => '連線到電腦';

  @override
  String get backupAddressLabel => '位址（電腦畫面上顯示的）';

  @override
  String get backupAddressHint => '192.168.1.20:8787';

  @override
  String get backupPinLabel => '配對碼';

  @override
  String get backupDeviceNameLabel => '這台裝置的名稱';

  @override
  String get backupDeviceNameHelp => '決定電腦上這台裝置的資料夾名稱。備份仍然可以還原到任何裝置。';

  @override
  String get backupStartButton => '開始備份';

  @override
  String get backupConnectButton => '連線';

  @override
  String get backupDisconnectButton => '中斷連線';

  @override
  String get backupDesktopControlsNote =>
      '連線後請在電腦端開始或暫停備份與還原；手機會執行傳輸，並把進度回報到電腦。';

  @override
  String get backupKeepForegroundNote => '連線或傳輸期間請保持 App 在前景；行動作業系統可能暫停背景 App。';

  @override
  String get backupControlDisconnected => '尚未連線';

  @override
  String get backupControlReady => '已連線，等待電腦端命令';

  @override
  String get backupControlRunning => '電腦端已開始備份';

  @override
  String get backupControlPausing => '目前檔案完成後暫停…';

  @override
  String get backupControlPaused => '備份已暫停';

  @override
  String get backupControlCompleted => '備份完成';

  @override
  String get backupControlError => '連線或備份失敗';

  @override
  String get backupStageConnecting => '連線中…';

  @override
  String get backupStageSnapshot => '準備資料庫中…';

  @override
  String get backupStageComparing => '比對電腦上已有的檔案…';

  @override
  String backupStageUploading(int current, int total) {
    return '上傳中 $current / $total';
  }

  @override
  String get backupErrorInvalidAddress => '請照電腦畫面上顯示的格式輸入，例如 192.168.1.20:8787';

  @override
  String get backupErrorMissingFields => '請填寫位址、配對碼與裝置名稱';

  @override
  String get backupErrorWrongPin => '配對碼錯誤或已過期。電腦每 60 秒會刷新一次，請重新掃描，不要沿用舊的截圖。';

  @override
  String get backupErrorLockedOut => '配對碼錯誤太多次，請等幾分鐘後再試。';

  @override
  String get backupErrorUnreachable =>
      '連不到那台電腦。請確認手機和電腦在同一個 Wi-Fi、位址正確，以及 Windows 防火牆有允許那個伺服器程式。';

  @override
  String backupErrorGeneric(String message) {
    return '備份失敗：$message';
  }

  @override
  String backupSummaryUploaded(int uploaded) {
    return '已備份 $uploaded 個檔案';
  }

  @override
  String backupSummarySkipped(int skipped) {
    return '$skipped 個電腦上已經有了';
  }

  @override
  String backupSummaryFailed(int failed) {
    return '$failed 個失敗——再執行一次備份就會只補傳這些';
  }

  @override
  String backupSummaryInFlight(int count) {
    return '有 $count 本仍在下載中，這次略過';
  }

  @override
  String get backupApiKeyNote => '備份不包含 nhentai API 金鑰，還原後需要重新登入。';

  @override
  String get backupScanWithCamera => '掃描配對碼';

  @override
  String get backupScanTitle => '掃描配對碼';

  @override
  String get backupScanAimHint => '把鏡頭對準電腦上備份伺服器顯示的 QR code。';

  @override
  String get backupScanCameraDenied => '相機權限未開啟，無法掃描。你仍然可以從相簿匯入截圖，或手動輸入位址與配對碼。';

  @override
  String get backupScanCameraUnavailable =>
      '這台裝置的相機無法使用。你仍然可以從相簿匯入截圖，或手動輸入位址與配對碼。';

  @override
  String get backupScanUseAnotherWay => '改用其他方式配對';

  @override
  String get backupImportPairingCode => '從相簿匯入配對碼';

  @override
  String backupTryingAddress(String address, int attempt, int total) {
    return '正在嘗試 $address（第 $attempt 個，共 $total 個）…';
  }

  @override
  String get backupScanNoCodeFound =>
      '這張圖片裡沒有 QR code。請選擇 Comicdex 備份伺服器視窗的截圖。';

  @override
  String get backupScanNotOurCode => '這不是 Comicdex 的配對碼。請掃描電腦上備份伺服器顯示的那個碼。';

  @override
  String get backupScanNeedsAppUpdate => '這個配對碼來自較新版的電腦端伺服器。請先更新這個 App 再試一次。';

  @override
  String get backupScanNoAddresses => '這個配對碼裡沒有位址。那台電腦可能沒有可用的網路連線——請確認後重新產生一組。';

  @override
  String get backupErrorPairingRejected =>
      '電腦接受了配對碼，但拒絕建立連線。通常是裝置名稱含有它不接受的字元——請改用只有英數字、空格、點或連字號的簡單名稱。';

  @override
  String get restoreInterruptedTitle => '還原沒有完成';

  @override
  String restoreInterruptedBody(String sourceDeviceId) {
    return '從「$sourceDeviceId」的還原被中斷了。部分已下載的漫畫為了騰出空間而被移除，但還沒補回來，所以書庫有些內容可能打不開。請到電腦端重新執行一次還原把它完成。';
  }

  @override
  String get restoreInterruptedDismiss => '下次再提醒我';

  @override
  String get restoreInterruptedAcknowledge => '我知道了';

  @override
  String get restoreDoneTitle => '還原完成';

  @override
  String get restoreDoneBody =>
      '圖庫已經還原完畢。必須重新啟動 App 才會載入還原後的資料庫——在那之前畫面上顯示的仍然是舊的。';

  @override
  String get restoreDoneCloseApp => '關閉 App';

  @override
  String get restoreDoneManualHint => '請完全關閉這個 App，然後重新開啟。';

  @override
  String get backupControlRestoreDone => '還原完成 · 需要重新啟動';

  @override
  String get backupControlRestoreRunning => '電腦端已開始還原';

  @override
  String get backupControlRestorePaused => '還原已暫停';

  @override
  String get backupControlRestoreError => '連線或還原失敗';

  @override
  String get downloadsSortTitle => '已下載排序';

  @override
  String get downloadsSortLatestDownloaded => '最近下載';

  @override
  String get downloadsSortLastRead => '上次閱讀';

  @override
  String get downloadsSortMostFavorited => '最多收藏';

  @override
  String get downloadsSortByTitle => '標題';

  @override
  String get downloadsSortByAuthor => '作者';

  @override
  String get downloadsSortByPreference => '依喜好';

  @override
  String get downloadsSortDescending => '由大到小';

  @override
  String get downloadsSortAscending => '由小到大';

  @override
  String get resetButton => '重設';

  @override
  String get downloadsClearTagFilters => '清除標籤';

  @override
  String downloadsUnknownTag(int tagId) {
    return '標籤 #$tagId';
  }

  @override
  String get downloadsEmpty => '還沒有任何下載';

  @override
  String get downloadsEmptyForTags => '沒有下載帶有這些標籤';

  @override
  String downloadsEmptyForQuery(String query) {
    return '沒有下載符合「$query」';
  }

  @override
  String get downloadsSectionActive => '進行中的下載';

  @override
  String get downloadsSectionCompleted => '已完成的下載';

  @override
  String get downloadsRandomTooltip => '隨機開啟一本已下載';

  @override
  String get downloadsListViewTooltip => '清單檢視';

  @override
  String get downloadsGridViewTooltip => '格狀檢視';

  @override
  String get downloadsRepairAllTooltip => '修復所有已完成的下載';

  @override
  String get downloadsRepairAllTitle => '修復所有已完成的下載？';

  @override
  String get downloadsRepairAllBody =>
      '這會檢查每一本已完成的下載是否缺頁或缺封面，並重新下載損壞的部分。可能需要一段時間，而且會使用網路流量。';

  @override
  String get downloadsRepairAllConfirm => '全部修復';

  @override
  String downloadsRepairAllIntact(int total) {
    return '全部 $total 本下載都完整';
  }

  @override
  String downloadsRepairAllRepaired(int repaired, int total) {
    return '已修復 $total 本中的 $repaired 本';
  }

  @override
  String downloadsRepairAllStopped(int repaired, int failed, int total) {
    return '連續失敗後停止——已修復 $repaired 本，失敗 $failed 本（共 $total 本）';
  }

  @override
  String downloadsRepairAllMixed(int repaired, int failed, int total) {
    return '$total 本中已修復 $repaired 本、失敗 $failed 本';
  }

  @override
  String downloadsRepairAllError(String error) {
    return '全部修復失敗：$error';
  }

  @override
  String get downloadsDeleteAction => '刪除下載';

  @override
  String get downloadsReloadAction => '重新下載';

  @override
  String get downloadsRepairAction => '修復';

  @override
  String get downloadsDeleteTitle => '刪除已下載的漫畫？';

  @override
  String get downloadsDeleteBody => '這會刪除已儲存的下載、封面、離線快照以及完成紀錄。';

  @override
  String get downloadsDeletedMessage => '已刪除下載的漫畫';

  @override
  String get downloadsReloadTitle => '重新下載？';

  @override
  String get downloadsReloadBody => '這會刪除已儲存的頁面並重新下載整本。閱讀紀錄與中繼資料會保留。';

  @override
  String get downloadsReloadQueued => '已排入重新下載';

  @override
  String get downloadsRepairQueued => '已排入修復';

  @override
  String get downloadsNothingToRepair => '所有頁面與封面都完整，不需修復';

  @override
  String get downloadsPausedMessage => '已暫停下載';

  @override
  String get downloadsPauseAction => '暫停';

  @override
  String get downloadsResumedMessage => '已繼續下載';

  @override
  String get downloadsResumeAction => '繼續';

  @override
  String get downloadsRemoveJobTitle => '移除下載工作？';

  @override
  String get downloadsRemoveJobBody => '這會移除下載工作，並刪除已存下的部分檔案。';

  @override
  String get downloadsJobRemovedMessage => '已移除下載工作';

  @override
  String get downloadsRemoveAction => '移除';

  @override
  String get downloadsRetriedMessage => '已重新嘗試下載';

  @override
  String get downloadsRetryAction => '重試';

  @override
  String get downloadsRemoveFailedTitle => '移除失敗的下載？';

  @override
  String get downloadsRemoveFailedBody => '這會移除失敗的工作，並刪除已存下的部分檔案。';

  @override
  String get downloadsFailedRemovedMessage => '已移除失敗的下載';

  @override
  String get downloadsStatusDownloading => '下載中';

  @override
  String get downloadsStatusQueued => '排隊中';

  @override
  String get downloadsStatusPaused => '已暫停';

  @override
  String get downloadsStatusFailed => '失敗';

  @override
  String get downloadsStatusCompleted => '已完成';

  @override
  String downloadsPageCountShort(int count) {
    return '$count 頁';
  }

  @override
  String downloadsPageCount(int count) {
    return '$count 頁';
  }

  @override
  String get confirmButton => '確認';

  @override
  String get collectionFavorite => '已收藏';

  @override
  String get collectionNext => '稍後閱讀';

  @override
  String get collectionHistory => '閱讀紀錄';

  @override
  String collectionUnknown(String name) {
    return '找不到這個收藏：$name';
  }

  @override
  String get collectionSelectComics => '選取漫畫';

  @override
  String collectionSelectedCount(int count) {
    return '已選 $count 本';
  }

  @override
  String get collectionSelectAll => '全選';

  @override
  String get collectionDeselectAll => '取消全選';

  @override
  String get collectionDone => '完成';

  @override
  String get collectionOpenSettings => '開啟設定';

  @override
  String get collectionLoginFromSettings => '從設定登入';

  @override
  String get collectionEmptyForTag => '這裡沒有帶這個標籤的漫畫';

  @override
  String collectionEmpty(String collection) {
    return '$collection裡沒有漫畫';
  }

  @override
  String collectionCollectedCount(int count) {
    return '$count 本';
  }

  @override
  String collectionUnknownTag(int tagId) {
    return '標籤 #$tagId';
  }

  @override
  String get collectionNoneSelected => '沒有選取任何漫畫';

  @override
  String collectionAllAlreadyDownloaded(int count) {
    return '這 $count 本都已經在已下載裡了';
  }

  @override
  String collectionDownloadSelected(int count) {
    return '下載 $count 本';
  }

  @override
  String collectionBatchProgress(int processed, int total) {
    return '正在加入已下載 $processed/$total…';
  }

  @override
  String collectionBatchQueued(int count) {
    return '已加入 $count 本到已下載';
  }

  @override
  String collectionBatchSkipped(int count) {
    return '略過 $count 本（已經下載過）';
  }

  @override
  String collectionBatchFailed(int count) {
    return '$count 本失敗';
  }

  @override
  String get collectionBatchStoppedEarly => '連續失敗後提前停止';

  @override
  String tagActionBlock(String tag) {
    return '封鎖「$tag」';
  }

  @override
  String tagActionUnblock(String tag) {
    return '解除封鎖「$tag」';
  }

  @override
  String tagActionBlocked(String tag) {
    return '已將「$tag」加入封鎖標籤';
  }

  @override
  String tagActionUnblocked(String tag) {
    return '已將「$tag」移出封鎖標籤';
  }

  @override
  String tagActionSearchFavorites(String tag) {
    return '在已收藏中搜尋「$tag」';
  }

  @override
  String tagActionFilterDownloads(String tag) {
    return '用「$tag」篩選已下載';
  }

  @override
  String get analysisTitle => '標籤分析';

  @override
  String get analysisNothingKept => '還沒有留下任何漫畫。收藏或下載幾本，這一頁就會有內容。';

  @override
  String analysisComicsKept(int count) {
    return '留下了 $count 本';
  }

  @override
  String analysisTaggedRatio(int count, int percent) {
    return '其中 $count 本帶有標籤（$percent%）';
  }

  @override
  String get analysisCoverageHint => '以下都只根據有標籤的那些計算。到設定同步收藏可以補齊其餘的。';

  @override
  String get analysisCombinationsTitle => '取向組合';

  @override
  String get analysisCombinationsHint =>
      '兩到三個經常一起出現的標籤，出現頻率高於各自單獨出現所能預期的。點擊可搜尋，長按可用來篩選已下載。';

  @override
  String get tagPreferencesTitle => '標籤喜好';

  @override
  String get tagPreferencesFullAnalysis => '詳細分析 ›';

  @override
  String get tagPreferencesEmpty => '還沒有標籤資料。到設定同步收藏，或下載幾本漫畫，喜好就會在這裡累積。';

  @override
  String get tagPreferencesShowLess => '收合';

  @override
  String tagPreferencesShowMore(int count) {
    return '再顯示 $count 個';
  }

  @override
  String get tagSectionTags => '標籤';

  @override
  String get tagSectionArtists => '作者';

  @override
  String get tagSectionParodies => '原作';

  @override
  String get tagSectionCharacters => '角色';

  @override
  String get sortMostKept => '最常留下';

  @override
  String get sortMostDistinctive => '最具特色';

  @override
  String get tagSheetNoTags => '沒有標籤';

  @override
  String get tagSheetLoadFailed => '載入標籤失敗。';

  @override
  String get tagSheetSelectToSearch => '選擇要搜尋的標籤';

  @override
  String tagSheetSearchSelected(int count) {
    return '搜尋 $count 個標籤';
  }

  @override
  String tagActionSearchDownloads(String tag) {
    return '在已下載中搜尋「$tag」';
  }

  @override
  String get retryButton => '重試';
}
