// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Comicdex 備份伺服器';

  @override
  String get languageLabel => '語言';

  @override
  String get languageSystem => '跟隨系統';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTraditionalChinese => '繁體中文';

  @override
  String get refreshDevices => '重新整理裝置清單';

  @override
  String get connectTitle => '從手機連線';

  @override
  String get connectAddressLabel => '位址';

  @override
  String get connectPinLabel => '配對碼';

  @override
  String get connectNewPin => '換一組';

  @override
  String get connectPinChangesNote => '每次重新啟動這個程式，配對碼都會更換。';

  @override
  String get connectNoNetwork => '找不到網路連線';

  @override
  String get connectServerStopped => '伺服器未執行。';

  @override
  String get connectVirtualAdapterTag => '虛擬網卡，手機多半連不到';

  @override
  String get connectCopyAddress => '複製位址';

  @override
  String connectAddressCopied(String address) {
    return '已複製 $address';
  }

  @override
  String get firewallHint =>
      '還沒有任何裝置連線過。如果手機連不到這台電腦，先確認 Windows 防火牆有允許這個程式使用私人網路——這是最常見的原因，而且症狀看起來跟位址打錯一模一樣。';

  @override
  String lockedOutHint(String addresses) {
    return '因為連續輸入錯誤配對碼而暫時封鎖：$addresses';
  }

  @override
  String get folderTitle => '備份資料夾';

  @override
  String get folderNotSet => '（尚未設定）';

  @override
  String get folderChange => '變更';

  @override
  String get folderPickConfirm => '使用這個資料夾';

  @override
  String get folderMissingWarning =>
      '目前找不到這個資料夾（可能是外接硬碟沒接上）。在它恢復之前一律拒絕備份，以免手機把空的鏡像誤判成「還沒備份過」而重傳整個圖庫。';

  @override
  String get devicesTitle => '已備份的裝置';

  @override
  String get devicesEmpty => '還沒有任何備份。';

  @override
  String devicesSubtitle(int fileCount, String size, int snapshotCount) {
    return '$fileCount 個檔案 · $size · $snapshotCount 份資料庫快照';
  }

  @override
  String devicesLastSync(String timestamp) {
    return '上次同步 $timestamp';
  }

  @override
  String get activityTitle => '活動紀錄';

  @override
  String get activityEmpty => '等待裝置連線…';

  @override
  String activityFolderChanged(String path) {
    return '備份資料夾已改為 $path';
  }

  @override
  String get activityPinRegenerated => '已產生新的配對碼';

  @override
  String activityCleanedPartFiles(int count) {
    return '已清除 $count 個中斷的傳輸暫存檔';
  }

  @override
  String activityDeletedStaleFiles(int count, String deviceId) {
    return '已刪除 $deviceId 的 $count 個過期檔案';
  }

  @override
  String activityReceivedFile(String path, String deviceId) {
    return '已從 $deviceId 收到 $path';
  }

  @override
  String activitySentFile(String path, String deviceId) {
    return '已傳送 $path 給 $deviceId';
  }

  @override
  String activityStoredDatabase(String deviceId) {
    return '已儲存 $deviceId 的資料庫快照';
  }

  @override
  String activitySentDatabase(String deviceId) {
    return '已傳送資料庫快照給 $deviceId';
  }

  @override
  String activityBlockedPin(String address) {
    return '已封鎖來自 $address 的連續錯誤配對碼';
  }

  @override
  String activityPruneRequested(String deviceId, int count) {
    return '$deviceId 要求清理：$count 個過期檔案';
  }

  @override
  String get pruneTitle => '刪除手機上已經沒有的檔案？';

  @override
  String pruneSummary(String deviceId, int count, String size) {
    return '$deviceId 要求清理 $count 個檔案，可釋出 $size。';
  }

  @override
  String get pruneExplanation =>
      '這些檔案存在於備份中，但手機上已經沒有了。刪除無法復原——如果是手機端誤刪，這裡就是僅存的一份。';

  @override
  String get pruneKeep => '全部保留';

  @override
  String get pruneDelete => '刪除';

  @override
  String pruneDeletedToast(int count) {
    return '已刪除 $count 個檔案';
  }
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get appTitle => 'Comicdex 備份伺服器';

  @override
  String get languageLabel => '語言';

  @override
  String get languageSystem => '跟隨系統';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTraditionalChinese => '繁體中文';

  @override
  String get refreshDevices => '重新整理裝置清單';

  @override
  String get connectTitle => '從手機連線';

  @override
  String get connectAddressLabel => '位址';

  @override
  String get connectPinLabel => '配對碼';

  @override
  String get connectNewPin => '換一組';

  @override
  String get connectPinChangesNote => '每次重新啟動這個程式，配對碼都會更換。';

  @override
  String get connectNoNetwork => '找不到網路連線';

  @override
  String get connectServerStopped => '伺服器未執行。';

  @override
  String get connectVirtualAdapterTag => '虛擬網卡，手機多半連不到';

  @override
  String get connectCopyAddress => '複製位址';

  @override
  String connectAddressCopied(String address) {
    return '已複製 $address';
  }

  @override
  String get firewallHint =>
      '還沒有任何裝置連線過。如果手機連不到這台電腦，先確認 Windows 防火牆有允許這個程式使用私人網路——這是最常見的原因，而且症狀看起來跟位址打錯一模一樣。';

  @override
  String lockedOutHint(String addresses) {
    return '因為連續輸入錯誤配對碼而暫時封鎖：$addresses';
  }

  @override
  String get folderTitle => '備份資料夾';

  @override
  String get folderNotSet => '（尚未設定）';

  @override
  String get folderChange => '變更';

  @override
  String get folderPickConfirm => '使用這個資料夾';

  @override
  String get folderMissingWarning =>
      '目前找不到這個資料夾（可能是外接硬碟沒接上）。在它恢復之前一律拒絕備份，以免手機把空的鏡像誤判成「還沒備份過」而重傳整個圖庫。';

  @override
  String get devicesTitle => '已備份的裝置';

  @override
  String get devicesEmpty => '還沒有任何備份。';

  @override
  String devicesSubtitle(int fileCount, String size, int snapshotCount) {
    return '$fileCount 個檔案 · $size · $snapshotCount 份資料庫快照';
  }

  @override
  String devicesLastSync(String timestamp) {
    return '上次同步 $timestamp';
  }

  @override
  String get activityTitle => '活動紀錄';

  @override
  String get activityEmpty => '等待裝置連線…';

  @override
  String activityFolderChanged(String path) {
    return '備份資料夾已改為 $path';
  }

  @override
  String get activityPinRegenerated => '已產生新的配對碼';

  @override
  String activityCleanedPartFiles(int count) {
    return '已清除 $count 個中斷的傳輸暫存檔';
  }

  @override
  String activityDeletedStaleFiles(int count, String deviceId) {
    return '已刪除 $deviceId 的 $count 個過期檔案';
  }

  @override
  String activityReceivedFile(String path, String deviceId) {
    return '已從 $deviceId 收到 $path';
  }

  @override
  String activitySentFile(String path, String deviceId) {
    return '已傳送 $path 給 $deviceId';
  }

  @override
  String activityStoredDatabase(String deviceId) {
    return '已儲存 $deviceId 的資料庫快照';
  }

  @override
  String activitySentDatabase(String deviceId) {
    return '已傳送資料庫快照給 $deviceId';
  }

  @override
  String activityBlockedPin(String address) {
    return '已封鎖來自 $address 的連續錯誤配對碼';
  }

  @override
  String activityPruneRequested(String deviceId, int count) {
    return '$deviceId 要求清理：$count 個過期檔案';
  }

  @override
  String get pruneTitle => '刪除手機上已經沒有的檔案？';

  @override
  String pruneSummary(String deviceId, int count, String size) {
    return '$deviceId 要求清理 $count 個檔案，可釋出 $size。';
  }

  @override
  String get pruneExplanation =>
      '這些檔案存在於備份中，但手機上已經沒有了。刪除無法復原——如果是手機端誤刪，這裡就是僅存的一份。';

  @override
  String get pruneKeep => '全部保留';

  @override
  String get pruneDelete => '刪除';

  @override
  String pruneDeletedToast(int count) {
    return '已刪除 $count 個檔案';
  }
}
