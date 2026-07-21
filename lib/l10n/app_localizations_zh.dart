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
}
