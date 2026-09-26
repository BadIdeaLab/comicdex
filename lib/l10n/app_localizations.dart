import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @sectionNhentaiApi.
  ///
  /// In en, this message translates to:
  /// **'nhentai API'**
  String get sectionNhentaiApi;

  /// No description provided for @sectionReader.
  ///
  /// In en, this message translates to:
  /// **'Reader'**
  String get sectionReader;

  /// No description provided for @sectionDownloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get sectionDownloads;

  /// No description provided for @sectionBlockedTags.
  ///
  /// In en, this message translates to:
  /// **'Blocked Tags'**
  String get sectionBlockedTags;

  /// No description provided for @sectionTagDatabase.
  ///
  /// In en, this message translates to:
  /// **'Tag Database'**
  String get sectionTagDatabase;

  /// No description provided for @sectionGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get sectionGeneral;

  /// No description provided for @sectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get sectionAbout;

  /// No description provided for @autoResumeDownloadsTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto Resume Downloads'**
  String get autoResumeDownloadsTitle;

  /// No description provided for @autoResumeDownloadsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Resume interrupted downloads when the app returns to foreground or restarts'**
  String get autoResumeDownloadsSubtitle;

  /// No description provided for @pageDownloadIntervalTitle.
  ///
  /// In en, this message translates to:
  /// **'Page Download Interval'**
  String get pageDownloadIntervalTitle;

  /// No description provided for @appliesToNewDownloadsNote.
  ///
  /// In en, this message translates to:
  /// **'Applies to new downloads or after resume'**
  String get appliesToNewDownloadsNote;

  /// No description provided for @statusTitle.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusTitle;

  /// No description provided for @statusAuthenticated.
  ///
  /// In en, this message translates to:
  /// **'Authenticated'**
  String get statusAuthenticated;

  /// No description provided for @statusNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get statusNotConfigured;

  /// No description provided for @statusSyncingWithProgress.
  ///
  /// In en, this message translates to:
  /// **'Syncing... page {page} / {total}'**
  String statusSyncingWithProgress(int page, int total);

  /// No description provided for @statusSyncingGeneric.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get statusSyncingGeneric;

  /// No description provided for @statusRateLimitedRetrying.
  ///
  /// In en, this message translates to:
  /// **'Rate limited, retrying in {seconds}s...'**
  String statusRateLimitedRetrying(int seconds);

  /// No description provided for @statusLastSync.
  ///
  /// In en, this message translates to:
  /// **'Last sync: {value}'**
  String statusLastSync(String value);

  /// No description provided for @statusNeverSynced.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get statusNeverSynced;

  /// No description provided for @setUpdateApiKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Set / Update API Key'**
  String get setUpdateApiKeyTitle;

  /// No description provided for @setUpdateApiKeySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Paste your personal nhentai API key from account settings'**
  String get setUpdateApiKeySubtitle;

  /// No description provided for @apiKeySavedMessage.
  ///
  /// In en, this message translates to:
  /// **'API key saved and validated'**
  String get apiKeySavedMessage;

  /// No description provided for @syncFavoritesNowTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync Favorites Now'**
  String get syncFavoritesNowTitle;

  /// No description provided for @syncFavoritesNowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Refresh the local favorite cache from the official API'**
  String get syncFavoritesNowSubtitle;

  /// No description provided for @favoritesSyncedMessage.
  ///
  /// In en, this message translates to:
  /// **'Favorites synced from API'**
  String get favoritesSyncedMessage;

  /// No description provided for @syncFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get syncFailedMessage;

  /// No description provided for @clearApiKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear API Key'**
  String get clearApiKeyTitle;

  /// No description provided for @clearApiKeySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remove the saved API key from secure storage'**
  String get clearApiKeySubtitle;

  /// No description provided for @clearApiKeyDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear API key?'**
  String get clearApiKeyDialogTitle;

  /// No description provided for @clearApiKeyDialogContent.
  ///
  /// In en, this message translates to:
  /// **'This removes the saved API key from secure storage. You will need to enter it again to sync favorites.'**
  String get clearApiKeyDialogContent;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @clearButton.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearButton;

  /// No description provided for @apiKeyClearedMessage.
  ///
  /// In en, this message translates to:
  /// **'API key cleared'**
  String get apiKeyClearedMessage;

  /// No description provided for @updateApiKeyDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Update API Key'**
  String get updateApiKeyDialogTitle;

  /// No description provided for @setApiKeyDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Set API Key'**
  String get setApiKeyDialogTitle;

  /// No description provided for @apiKeyFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get apiKeyFieldLabel;

  /// No description provided for @apiKeyFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Paste your nhentai API key'**
  String get apiKeyFieldHint;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @prefetchPagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Pre-fetch Pages'**
  String get prefetchPagesTitle;

  /// No description provided for @prefetchPagesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cache {count} page(s) before and after the current page (default: {defaultCount})'**
  String prefetchPagesSubtitle(int count, int defaultCount);

  /// No description provided for @prefetchDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Pre-cache {count} page(s) before and after the current page.'**
  String prefetchDialogBody(int count);

  /// No description provided for @clearImageCacheTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Image Cache'**
  String get clearImageCacheTitle;

  /// No description provided for @clearImageCacheSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all cached comic images from disk'**
  String get clearImageCacheSubtitle;

  /// No description provided for @imageCacheClearedMessage.
  ///
  /// In en, this message translates to:
  /// **'Image cache cleared'**
  String get imageCacheClearedMessage;

  /// No description provided for @noBlockedTagsMessage.
  ///
  /// In en, this message translates to:
  /// **'No blocked tags. Long-press a tag on a comic to block it.'**
  String get noBlockedTagsMessage;

  /// No description provided for @removeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeTooltip;

  /// No description provided for @checkForTagDatabaseUpdatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Check for Tag Database Updates'**
  String get checkForTagDatabaseUpdatesTitle;

  /// No description provided for @tagDatabaseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} tags loaded (version {version}, {origin})'**
  String tagDatabaseSubtitle(int count, String version, String origin);

  /// No description provided for @tagDatabaseOriginBundled.
  ///
  /// In en, this message translates to:
  /// **'bundled'**
  String get tagDatabaseOriginBundled;

  /// No description provided for @tagDatabaseOriginUpdated.
  ///
  /// In en, this message translates to:
  /// **'updated'**
  String get tagDatabaseOriginUpdated;

  /// No description provided for @tagDatabaseCheckFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to check for tag database updates'**
  String get tagDatabaseCheckFailedMessage;

  /// No description provided for @tagDatabaseUpToDateMessage.
  ///
  /// In en, this message translates to:
  /// **'Tag database is already up to date'**
  String get tagDatabaseUpToDateMessage;

  /// No description provided for @tagDatabaseUpdateAvailableDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Tag Database Update Available'**
  String get tagDatabaseUpdateAvailableDialogTitle;

  /// No description provided for @tagDatabaseUpdateAvailableDialogContent.
  ///
  /// In en, this message translates to:
  /// **'A newer tag database is available ({version}). Download and apply it now? (a few MB)'**
  String tagDatabaseUpdateAvailableDialogContent(String version);

  /// No description provided for @updateButton.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateButton;

  /// No description provided for @tagDatabaseUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Tag database updated ({count} tags)'**
  String tagDatabaseUpdatedMessage(int count);

  /// No description provided for @tagDatabaseUpdateFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to download tag database update'**
  String get tagDatabaseUpdateFailedMessage;

  /// No description provided for @appLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguageTitle;

  /// No description provided for @appLanguageSystemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get appLanguageSystemDefault;

  /// No description provided for @appLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get appLanguageEnglish;

  /// No description provided for @appLanguageTraditionalChinese.
  ///
  /// In en, this message translates to:
  /// **'繁體中文'**
  String get appLanguageTraditionalChinese;

  /// No description provided for @appLanguageChangedMessage.
  ///
  /// In en, this message translates to:
  /// **'App language set to {name}'**
  String appLanguageChangedMessage(String name);

  /// No description provided for @diagnoseTitle.
  ///
  /// In en, this message translates to:
  /// **'Diagnose'**
  String get diagnoseTitle;

  /// No description provided for @diagnoseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reserved for future diagnostics'**
  String get diagnoseSubtitle;

  /// No description provided for @loadJsonNetworkTitle.
  ///
  /// In en, this message translates to:
  /// **'Load json (network)'**
  String get loadJsonNetworkTitle;

  /// No description provided for @enterUrlDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter URL'**
  String get enterUrlDialogTitle;

  /// No description provided for @urlFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get urlFieldLabel;

  /// No description provided for @openSourceLicensesTitle.
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get openSourceLicensesTitle;

  /// No description provided for @secondsFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Seconds'**
  String get secondsFieldLabel;

  /// No description provided for @secondsFieldSuffix.
  ///
  /// In en, this message translates to:
  /// **'s'**
  String get secondsFieldSuffix;

  /// No description provided for @presetSecondsLabel.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s'**
  String presetSecondsLabel(String seconds);

  /// No description provided for @applyButton.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get applyButton;

  /// No description provided for @enterNumberErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter a number in seconds'**
  String get enterNumberErrorMessage;

  /// No description provided for @onlyNumericErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Only plain numeric seconds are supported'**
  String get onlyNumericErrorMessage;

  /// No description provided for @valueMustBeZeroOrMoreErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Value must be 0 seconds or more'**
  String get valueMustBeZeroOrMoreErrorMessage;

  /// No description provided for @sectionBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get sectionBackup;

  /// No description provided for @backupTileTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to your computer'**
  String get backupTileTitle;

  /// No description provided for @backupTileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pair with the Comicdex backup server; control backup and restore on the computer'**
  String get backupTileSubtitle;

  /// No description provided for @backupScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to computer'**
  String get backupScreenTitle;

  /// No description provided for @backupAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address (shown on the computer)'**
  String get backupAddressLabel;

  /// No description provided for @backupAddressHint.
  ///
  /// In en, this message translates to:
  /// **'192.168.1.20:8787'**
  String get backupAddressHint;

  /// No description provided for @backupPinLabel.
  ///
  /// In en, this message translates to:
  /// **'Pairing PIN'**
  String get backupPinLabel;

  /// No description provided for @backupDeviceNameLabel.
  ///
  /// In en, this message translates to:
  /// **'This device\'s name'**
  String get backupDeviceNameLabel;

  /// No description provided for @backupDeviceNameHelp.
  ///
  /// In en, this message translates to:
  /// **'Names this device\'s folder on the computer. Backups can still be restored onto any device.'**
  String get backupDeviceNameHelp;

  /// No description provided for @backupStartButton.
  ///
  /// In en, this message translates to:
  /// **'Start backup'**
  String get backupStartButton;

  /// No description provided for @backupConnectButton.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get backupConnectButton;

  /// No description provided for @backupDisconnectButton.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get backupDisconnectButton;

  /// No description provided for @backupDesktopControlsNote.
  ///
  /// In en, this message translates to:
  /// **'Once connected, start or pause backups and restores from the computer; this phone runs the transfer and reports progress back.'**
  String get backupDesktopControlsNote;

  /// No description provided for @backupKeepForegroundNote.
  ///
  /// In en, this message translates to:
  /// **'Keep the app in the foreground while connected or transferring. Mobile operating systems may suspend a background app.'**
  String get backupKeepForegroundNote;

  /// No description provided for @backupControlDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get backupControlDisconnected;

  /// No description provided for @backupControlReady.
  ///
  /// In en, this message translates to:
  /// **'Connected · waiting for a command from the computer'**
  String get backupControlReady;

  /// No description provided for @backupControlRunning.
  ///
  /// In en, this message translates to:
  /// **'Backup started by the computer'**
  String get backupControlRunning;

  /// No description provided for @backupControlPausing.
  ///
  /// In en, this message translates to:
  /// **'Pausing after the current file…'**
  String get backupControlPausing;

  /// No description provided for @backupControlPaused.
  ///
  /// In en, this message translates to:
  /// **'Backup paused'**
  String get backupControlPaused;

  /// No description provided for @backupControlCompleted.
  ///
  /// In en, this message translates to:
  /// **'Backup completed'**
  String get backupControlCompleted;

  /// No description provided for @backupControlError.
  ///
  /// In en, this message translates to:
  /// **'Connection or backup failed'**
  String get backupControlError;

  /// No description provided for @backupStageConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get backupStageConnecting;

  /// No description provided for @backupStageSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Preparing database…'**
  String get backupStageSnapshot;

  /// No description provided for @backupStageComparing.
  ///
  /// In en, this message translates to:
  /// **'Checking what the computer already has…'**
  String get backupStageComparing;

  /// No description provided for @backupStageUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading {current} of {total}'**
  String backupStageUploading(int current, int total);

  /// No description provided for @backupErrorInvalidAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter the address exactly as shown on the computer, for example 192.168.1.20:8787'**
  String get backupErrorInvalidAddress;

  /// No description provided for @backupErrorMissingFields.
  ///
  /// In en, this message translates to:
  /// **'Fill in the address, PIN, and device name'**
  String get backupErrorMissingFields;

  /// No description provided for @backupErrorWrongPin.
  ///
  /// In en, this message translates to:
  /// **'Wrong or expired pairing code. The computer refreshes it every 60 seconds, so scan the code again rather than reusing an old screenshot.'**
  String get backupErrorWrongPin;

  /// No description provided for @backupErrorLockedOut.
  ///
  /// In en, this message translates to:
  /// **'Too many wrong PINs. Wait a few minutes, then try again.'**
  String get backupErrorLockedOut;

  /// No description provided for @backupErrorUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Could not reach that computer. Check you are on the same Wi-Fi, that the address is right, and that Windows Firewall is allowing the server app.'**
  String get backupErrorUnreachable;

  /// No description provided for @backupErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Backup failed: {message}'**
  String backupErrorGeneric(String message);

  /// No description provided for @backupSummaryUploaded.
  ///
  /// In en, this message translates to:
  /// **'Backed up {uploaded} file(s)'**
  String backupSummaryUploaded(int uploaded);

  /// No description provided for @backupSummarySkipped.
  ///
  /// In en, this message translates to:
  /// **'{skipped} already on the computer'**
  String backupSummarySkipped(int skipped);

  /// No description provided for @backupSummaryFailed.
  ///
  /// In en, this message translates to:
  /// **'{failed} failed — run the backup again to retry just those'**
  String backupSummaryFailed(int failed);

  /// No description provided for @backupSummaryInFlight.
  ///
  /// In en, this message translates to:
  /// **'{count} comic(s) still downloading were skipped this time'**
  String backupSummaryInFlight(int count);

  /// No description provided for @backupApiKeyNote.
  ///
  /// In en, this message translates to:
  /// **'Your nhentai API key is not included in backups. You will sign in again after restoring.'**
  String get backupApiKeyNote;

  /// No description provided for @backupScanWithCamera.
  ///
  /// In en, this message translates to:
  /// **'Scan pairing code'**
  String get backupScanWithCamera;

  /// No description provided for @backupScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan pairing code'**
  String get backupScanTitle;

  /// No description provided for @backupScanAimHint.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the QR code shown by the backup server on your computer.'**
  String get backupScanAimHint;

  /// No description provided for @backupScanCameraDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera access is off, so the code cannot be scanned. You can still import a screenshot from your photos, or type the address and PIN.'**
  String get backupScanCameraDenied;

  /// No description provided for @backupScanCameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The camera is unavailable on this device. You can still import a screenshot from your photos, or type the address and PIN.'**
  String get backupScanCameraUnavailable;

  /// No description provided for @backupScanUseAnotherWay.
  ///
  /// In en, this message translates to:
  /// **'Pair another way'**
  String get backupScanUseAnotherWay;

  /// No description provided for @backupImportPairingCode.
  ///
  /// In en, this message translates to:
  /// **'Import pairing code from photos'**
  String get backupImportPairingCode;

  /// No description provided for @backupTryingAddress.
  ///
  /// In en, this message translates to:
  /// **'Trying {address} ({attempt} of {total})…'**
  String backupTryingAddress(String address, int attempt, int total);

  /// No description provided for @backupScanNoCodeFound.
  ///
  /// In en, this message translates to:
  /// **'No QR code in that image. Pick a screenshot of the Comicdex backup server window.'**
  String get backupScanNoCodeFound;

  /// No description provided for @backupScanNotOurCode.
  ///
  /// In en, this message translates to:
  /// **'That is not a Comicdex pairing code. Scan the code shown by the backup server on your computer.'**
  String get backupScanNotOurCode;

  /// No description provided for @backupScanNeedsAppUpdate.
  ///
  /// In en, this message translates to:
  /// **'That pairing code comes from a newer version of the desktop server. Update this app, then try again.'**
  String get backupScanNeedsAppUpdate;

  /// No description provided for @backupScanNoAddresses.
  ///
  /// In en, this message translates to:
  /// **'That pairing code contains no address. The computer may have no usable network connection — check it and generate a new code.'**
  String get backupScanNoAddresses;

  /// No description provided for @backupErrorPairingRejected.
  ///
  /// In en, this message translates to:
  /// **'The computer accepted the PIN but refused to pair. This usually means the device name contains characters it will not accept — try a simpler name using letters, digits, spaces, dots or hyphens.'**
  String get backupErrorPairingRejected;

  /// No description provided for @restoreInterruptedTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore did not finish'**
  String get restoreInterruptedTitle;

  /// No description provided for @restoreInterruptedBody.
  ///
  /// In en, this message translates to:
  /// **'A restore from \"{sourceDeviceId}\" was interrupted. Some downloaded comics were removed to make room and have not been fetched back yet, so parts of your library may not open. Run the restore again from the computer to finish it.'**
  String restoreInterruptedBody(String sourceDeviceId);

  /// No description provided for @restoreInterruptedDismiss.
  ///
  /// In en, this message translates to:
  /// **'Remind me again'**
  String get restoreInterruptedDismiss;

  /// No description provided for @restoreInterruptedAcknowledge.
  ///
  /// In en, this message translates to:
  /// **'I understand'**
  String get restoreInterruptedAcknowledge;

  /// No description provided for @restoreDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore finished'**
  String get restoreDoneTitle;

  /// No description provided for @restoreDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Your library has been restored. The app must be restarted to load the restored database — until then it is still showing the old one.'**
  String get restoreDoneBody;

  /// No description provided for @restoreDoneCloseApp.
  ///
  /// In en, this message translates to:
  /// **'Close the app'**
  String get restoreDoneCloseApp;

  /// No description provided for @restoreDoneManualHint.
  ///
  /// In en, this message translates to:
  /// **'Please close this app completely and open it again.'**
  String get restoreDoneManualHint;

  /// No description provided for @backupControlRestoreDone.
  ///
  /// In en, this message translates to:
  /// **'Restore finished · restart required'**
  String get backupControlRestoreDone;

  /// No description provided for @backupControlRestoreRunning.
  ///
  /// In en, this message translates to:
  /// **'The computer started a restore'**
  String get backupControlRestoreRunning;

  /// No description provided for @backupControlRestorePaused.
  ///
  /// In en, this message translates to:
  /// **'Restore paused'**
  String get backupControlRestorePaused;

  /// No description provided for @backupControlRestoreError.
  ///
  /// In en, this message translates to:
  /// **'Connection or restore failed'**
  String get backupControlRestoreError;

  /// No description provided for @downloadsSortTitle.
  ///
  /// In en, this message translates to:
  /// **'Sort Downloads'**
  String get downloadsSortTitle;

  /// No description provided for @downloadsSortLatestDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Latest Downloaded'**
  String get downloadsSortLatestDownloaded;

  /// No description provided for @downloadsSortLastRead.
  ///
  /// In en, this message translates to:
  /// **'Last Read'**
  String get downloadsSortLastRead;

  /// No description provided for @downloadsSortMostFavorited.
  ///
  /// In en, this message translates to:
  /// **'Most Favorited'**
  String get downloadsSortMostFavorited;

  /// No description provided for @downloadsSortByTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get downloadsSortByTitle;

  /// No description provided for @downloadsSortByAuthor.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get downloadsSortByAuthor;

  /// No description provided for @downloadsSortByPreference.
  ///
  /// In en, this message translates to:
  /// **'Preference'**
  String get downloadsSortByPreference;

  /// No description provided for @downloadsSortDescending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get downloadsSortDescending;

  /// No description provided for @downloadsSortAscending.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get downloadsSortAscending;

  /// No description provided for @resetButton.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetButton;

  /// No description provided for @downloadsClearTagFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear tags'**
  String get downloadsClearTagFilters;

  /// Fallback chip label when a tag id is not in the local catalog
  ///
  /// In en, this message translates to:
  /// **'Tag #{tagId}'**
  String downloadsUnknownTag(int tagId);

  /// No description provided for @downloadsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No downloads yet'**
  String get downloadsEmpty;

  /// No description provided for @downloadsEmptyForTags.
  ///
  /// In en, this message translates to:
  /// **'No downloads carry those tags'**
  String get downloadsEmptyForTags;

  /// No description provided for @downloadsEmptyForQuery.
  ///
  /// In en, this message translates to:
  /// **'No downloads match \"{query}\"'**
  String downloadsEmptyForQuery(String query);

  /// No description provided for @downloadsSectionActive.
  ///
  /// In en, this message translates to:
  /// **'Active Downloads'**
  String get downloadsSectionActive;

  /// No description provided for @downloadsSectionCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed Downloads'**
  String get downloadsSectionCompleted;

  /// No description provided for @downloadsRandomTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open a random completed download'**
  String get downloadsRandomTooltip;

  /// No description provided for @downloadsListViewTooltip.
  ///
  /// In en, this message translates to:
  /// **'List view'**
  String get downloadsListViewTooltip;

  /// No description provided for @downloadsGridViewTooltip.
  ///
  /// In en, this message translates to:
  /// **'Grid view'**
  String get downloadsGridViewTooltip;

  /// No description provided for @downloadsRepairAllTooltip.
  ///
  /// In en, this message translates to:
  /// **'Repair all completed downloads'**
  String get downloadsRepairAllTooltip;

  /// No description provided for @downloadsRepairAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Repair all completed downloads?'**
  String get downloadsRepairAllTitle;

  /// No description provided for @downloadsRepairAllBody.
  ///
  /// In en, this message translates to:
  /// **'This scans every completed download for missing pages or a missing cover and re-downloads anything broken. It may take a while and will use network data.'**
  String get downloadsRepairAllBody;

  /// No description provided for @downloadsRepairAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'Repair All'**
  String get downloadsRepairAllConfirm;

  /// No description provided for @downloadsRepairAllIntact.
  ///
  /// In en, this message translates to:
  /// **'All {total} downloads are intact'**
  String downloadsRepairAllIntact(int total);

  /// No description provided for @downloadsRepairAllRepaired.
  ///
  /// In en, this message translates to:
  /// **'Repaired {repaired} of {total} downloads'**
  String downloadsRepairAllRepaired(int repaired, int total);

  /// No description provided for @downloadsRepairAllStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped after repeated failures — repaired {repaired}, failed {failed} (of {total} total)'**
  String downloadsRepairAllStopped(int repaired, int failed, int total);

  /// No description provided for @downloadsRepairAllMixed.
  ///
  /// In en, this message translates to:
  /// **'Repaired {repaired}, failed {failed}, of {total} downloads'**
  String downloadsRepairAllMixed(int repaired, int failed, int total);

  /// No description provided for @downloadsRepairAllError.
  ///
  /// In en, this message translates to:
  /// **'Repair all failed: {error}'**
  String downloadsRepairAllError(String error);

  /// No description provided for @downloadsDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete Download'**
  String get downloadsDeleteAction;

  /// No description provided for @downloadsReloadAction.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get downloadsReloadAction;

  /// No description provided for @downloadsRepairAction.
  ///
  /// In en, this message translates to:
  /// **'Repair'**
  String get downloadsRepairAction;

  /// No description provided for @downloadsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete downloaded comic?'**
  String get downloadsDeleteTitle;

  /// No description provided for @downloadsDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This deletes the saved download, cover, offline snapshot, and the completed job record.'**
  String get downloadsDeleteBody;

  /// No description provided for @downloadsDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Downloaded comic deleted'**
  String get downloadsDeletedMessage;

  /// No description provided for @downloadsReloadTitle.
  ///
  /// In en, this message translates to:
  /// **'Reload download?'**
  String get downloadsReloadTitle;

  /// No description provided for @downloadsReloadBody.
  ///
  /// In en, this message translates to:
  /// **'This deletes the saved pages and re-downloads the comic from scratch. Reading history and metadata are preserved.'**
  String get downloadsReloadBody;

  /// No description provided for @downloadsReloadQueued.
  ///
  /// In en, this message translates to:
  /// **'Reload queued'**
  String get downloadsReloadQueued;

  /// No description provided for @downloadsRepairQueued.
  ///
  /// In en, this message translates to:
  /// **'Repair queued'**
  String get downloadsRepairQueued;

  /// No description provided for @downloadsNothingToRepair.
  ///
  /// In en, this message translates to:
  /// **'All pages and cover are intact — nothing to repair'**
  String get downloadsNothingToRepair;

  /// No description provided for @downloadsPausedMessage.
  ///
  /// In en, this message translates to:
  /// **'Download paused'**
  String get downloadsPausedMessage;

  /// No description provided for @downloadsPauseAction.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get downloadsPauseAction;

  /// No description provided for @downloadsResumedMessage.
  ///
  /// In en, this message translates to:
  /// **'Download resumed'**
  String get downloadsResumedMessage;

  /// No description provided for @downloadsResumeAction.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get downloadsResumeAction;

  /// No description provided for @downloadsRemoveJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove download job?'**
  String get downloadsRemoveJobTitle;

  /// No description provided for @downloadsRemoveJobBody.
  ///
  /// In en, this message translates to:
  /// **'This removes the download job and deletes any partial files already saved.'**
  String get downloadsRemoveJobBody;

  /// No description provided for @downloadsJobRemovedMessage.
  ///
  /// In en, this message translates to:
  /// **'Download job removed'**
  String get downloadsJobRemovedMessage;

  /// No description provided for @downloadsRemoveAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get downloadsRemoveAction;

  /// No description provided for @downloadsRetriedMessage.
  ///
  /// In en, this message translates to:
  /// **'Download retried'**
  String get downloadsRetriedMessage;

  /// No description provided for @downloadsRetryAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get downloadsRetryAction;

  /// No description provided for @downloadsRemoveFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove failed download?'**
  String get downloadsRemoveFailedTitle;

  /// No description provided for @downloadsRemoveFailedBody.
  ///
  /// In en, this message translates to:
  /// **'This removes the failed job and deletes any partial files already saved.'**
  String get downloadsRemoveFailedBody;

  /// No description provided for @downloadsFailedRemovedMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed download removed'**
  String get downloadsFailedRemovedMessage;

  /// No description provided for @downloadsStatusDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get downloadsStatusDownloading;

  /// No description provided for @downloadsStatusQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get downloadsStatusQueued;

  /// No description provided for @downloadsStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get downloadsStatusPaused;

  /// No description provided for @downloadsStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get downloadsStatusFailed;

  /// No description provided for @downloadsStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get downloadsStatusCompleted;

  /// Compact page count on a grid tile, e.g. "24p"
  ///
  /// In en, this message translates to:
  /// **'{count}p'**
  String downloadsPageCountShort(int count);

  /// The one string here that genuinely needs a plural: English says "1 page" but "2 pages". Chinese has no plural form, so its translation is a single case.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 page} other{{count} pages}}'**
  String downloadsPageCount(int count);

  /// No description provided for @confirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmButton;

  /// No description provided for @collectionFavorite.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get collectionFavorite;

  /// No description provided for @collectionNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get collectionNext;

  /// No description provided for @collectionHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get collectionHistory;

  /// No description provided for @collectionUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown collection: {name}'**
  String collectionUnknown(String name);

  /// No description provided for @collectionSelectComics.
  ///
  /// In en, this message translates to:
  /// **'Select comics'**
  String get collectionSelectComics;

  /// No description provided for @collectionSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String collectionSelectedCount(int count);

  /// No description provided for @collectionSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get collectionSelectAll;

  /// No description provided for @collectionDeselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get collectionDeselectAll;

  /// No description provided for @collectionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get collectionDone;

  /// No description provided for @collectionOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get collectionOpenSettings;

  /// No description provided for @collectionLoginFromSettings.
  ///
  /// In en, this message translates to:
  /// **'Login from Settings'**
  String get collectionLoginFromSettings;

  /// No description provided for @collectionEmptyForTag.
  ///
  /// In en, this message translates to:
  /// **'No comics here carry that tag'**
  String get collectionEmptyForTag;

  /// No description provided for @collectionEmpty.
  ///
  /// In en, this message translates to:
  /// **'No comics in {collection}'**
  String collectionEmpty(String collection);

  /// No description provided for @collectionCollectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} collected'**
  String collectionCollectedCount(int count);

  /// No description provided for @collectionUnknownTag.
  ///
  /// In en, this message translates to:
  /// **'Tag #{tagId}'**
  String collectionUnknownTag(int tagId);

  /// No description provided for @collectionNoneSelected.
  ///
  /// In en, this message translates to:
  /// **'No comics selected'**
  String get collectionNoneSelected;

  /// No description provided for @collectionAllAlreadyDownloaded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{That comic is already in Downloads} other{All {count} comics are already in Downloads}}'**
  String collectionAllAlreadyDownloaded(int count);

  /// No description provided for @collectionDownloadSelected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Download 1 comic} other{Download {count} comics}}'**
  String collectionDownloadSelected(int count);

  /// No description provided for @collectionBatchProgress.
  ///
  /// In en, this message translates to:
  /// **'Adding {processed}/{total} to Downloads…'**
  String collectionBatchProgress(int processed, int total);

  /// No description provided for @collectionBatchQueued.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 comic added to Downloads} other{{count} comics added to Downloads}}'**
  String collectionBatchQueued(int count);

  /// No description provided for @collectionBatchSkipped.
  ///
  /// In en, this message translates to:
  /// **'{count} skipped (already downloaded)'**
  String collectionBatchSkipped(int count);

  /// No description provided for @collectionBatchFailed.
  ///
  /// In en, this message translates to:
  /// **'{count} failed'**
  String collectionBatchFailed(int count);

  /// No description provided for @collectionBatchStoppedEarly.
  ///
  /// In en, this message translates to:
  /// **'stopped early after repeated failures'**
  String get collectionBatchStoppedEarly;

  /// No description provided for @tagActionBlock.
  ///
  /// In en, this message translates to:
  /// **'Block \"{tag}\"'**
  String tagActionBlock(String tag);

  /// No description provided for @tagActionUnblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock \"{tag}\"'**
  String tagActionUnblock(String tag);

  /// No description provided for @tagActionBlocked.
  ///
  /// In en, this message translates to:
  /// **'\"{tag}\" added to blocked tags'**
  String tagActionBlocked(String tag);

  /// No description provided for @tagActionUnblocked.
  ///
  /// In en, this message translates to:
  /// **'\"{tag}\" removed from blocked tags'**
  String tagActionUnblocked(String tag);

  /// No description provided for @tagActionSearchFavorites.
  ///
  /// In en, this message translates to:
  /// **'Search \"{tag}\" in Favorites'**
  String tagActionSearchFavorites(String tag);

  /// No description provided for @tagActionFilterDownloads.
  ///
  /// In en, this message translates to:
  /// **'Filter Downloads by \"{tag}\"'**
  String tagActionFilterDownloads(String tag);

  /// No description provided for @analysisTitle.
  ///
  /// In en, this message translates to:
  /// **'Tag Analysis'**
  String get analysisTitle;

  /// No description provided for @analysisNothingKept.
  ///
  /// In en, this message translates to:
  /// **'Nothing kept yet. Favorite or download some comics and this page fills in.'**
  String get analysisNothingKept;

  /// No description provided for @analysisComicsKept.
  ///
  /// In en, this message translates to:
  /// **'{count} comics kept'**
  String analysisComicsKept(int count);

  /// No description provided for @analysisTaggedRatio.
  ///
  /// In en, this message translates to:
  /// **'{count} of them carry tags ({percent}%)'**
  String analysisTaggedRatio(int count, int percent);

  /// No description provided for @analysisCoverageHint.
  ///
  /// In en, this message translates to:
  /// **'Everything below is based on the tagged ones. Sync favorites from Settings to fill in the rest.'**
  String get analysisCoverageHint;

  /// No description provided for @analysisCombinationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Taste Combinations'**
  String get analysisCombinationsTitle;

  /// No description provided for @analysisCombinationsHint.
  ///
  /// In en, this message translates to:
  /// **'Two or three tags that show up together more often than each tag on its own would suggest. Tap to search them; long-press to filter Downloads by them.'**
  String get analysisCombinationsHint;

  /// No description provided for @tagPreferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Tag Preferences'**
  String get tagPreferencesTitle;

  /// No description provided for @tagPreferencesFullAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Full analysis ›'**
  String get tagPreferencesFullAnalysis;

  /// No description provided for @tagPreferencesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tag data yet. Sync favorites from Settings, or download a few comics, and preferences will build up here.'**
  String get tagPreferencesEmpty;

  /// No description provided for @tagPreferencesShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get tagPreferencesShowLess;

  /// No description provided for @tagPreferencesShowMore.
  ///
  /// In en, this message translates to:
  /// **'Show {count} more'**
  String tagPreferencesShowMore(int count);

  /// No description provided for @tagSectionTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tagSectionTags;

  /// No description provided for @tagSectionArtists.
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get tagSectionArtists;

  /// No description provided for @tagSectionParodies.
  ///
  /// In en, this message translates to:
  /// **'Parodies'**
  String get tagSectionParodies;

  /// No description provided for @tagSectionCharacters.
  ///
  /// In en, this message translates to:
  /// **'Characters'**
  String get tagSectionCharacters;

  /// No description provided for @sortMostKept.
  ///
  /// In en, this message translates to:
  /// **'Most kept'**
  String get sortMostKept;

  /// No description provided for @sortMostDistinctive.
  ///
  /// In en, this message translates to:
  /// **'Most distinctive'**
  String get sortMostDistinctive;

  /// No description provided for @tagSheetNoTags.
  ///
  /// In en, this message translates to:
  /// **'No tags'**
  String get tagSheetNoTags;

  /// No description provided for @tagSheetLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load tags.'**
  String get tagSheetLoadFailed;

  /// No description provided for @tagSheetSelectToSearch.
  ///
  /// In en, this message translates to:
  /// **'Select tags to search'**
  String get tagSheetSelectToSearch;

  /// No description provided for @tagSheetSearchSelected.
  ///
  /// In en, this message translates to:
  /// **'Search {count} tags'**
  String tagSheetSearchSelected(int count);

  /// No description provided for @tagActionSearchDownloads.
  ///
  /// In en, this message translates to:
  /// **'Search \"{tag}\" in Downloads'**
  String tagActionSearchDownloads(String tag);

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// No description provided for @feedErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check the network and try again.'**
  String get feedErrorNetwork;

  /// No description provided for @feedErrorForbidden.
  ///
  /// In en, this message translates to:
  /// **'Authentication issue (403).'**
  String get feedErrorForbidden;

  /// No description provided for @feedErrorNotFound.
  ///
  /// In en, this message translates to:
  /// **'The site had nothing at that address (404).'**
  String get feedErrorNotFound;

  /// No description provided for @feedErrorServer.
  ///
  /// In en, this message translates to:
  /// **'The site is not responding right now. It was tried a few times already — give it a moment.'**
  String get feedErrorServer;

  /// No description provided for @feedErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Failed to load comics from the site.'**
  String get feedErrorUnknown;

  /// No description provided for @readerSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reader Settings'**
  String get readerSettingsTitle;

  /// No description provided for @readerReadingDirection.
  ///
  /// In en, this message translates to:
  /// **'Reading Direction'**
  String get readerReadingDirection;

  /// No description provided for @readerDirectionLtr.
  ///
  /// In en, this message translates to:
  /// **'LTR'**
  String get readerDirectionLtr;

  /// No description provided for @readerDirectionRtl.
  ///
  /// In en, this message translates to:
  /// **'RTL'**
  String get readerDirectionRtl;

  /// No description provided for @readerTapZoneWidth.
  ///
  /// In en, this message translates to:
  /// **'Tap zone width'**
  String get readerTapZoneWidth;

  /// No description provided for @readerPrefetchPages.
  ///
  /// In en, this message translates to:
  /// **'Pre-fetch pages (before & after)'**
  String get readerPrefetchPages;

  /// No description provided for @readerPrefetchExplanation.
  ///
  /// In en, this message translates to:
  /// **'Currently caching {count} page(s) on each side of the current page.'**
  String readerPrefetchExplanation(int count);

  /// No description provided for @readerResumedFromPage.
  ///
  /// In en, this message translates to:
  /// **'Resumed from page {page}'**
  String readerResumedFromPage(int page);

  /// No description provided for @readerGoToStart.
  ///
  /// In en, this message translates to:
  /// **'Go to start'**
  String get readerGoToStart;

  /// No description provided for @readerNotDownloaded.
  ///
  /// In en, this message translates to:
  /// **'This comic is not downloaded, so there is nothing to read offline. Download it first, or repair it from the Downloads tab.'**
  String get readerNotDownloaded;

  /// No description provided for @readerLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load this comic. Check your connection and try again.'**
  String get readerLoadFailed;

  /// No description provided for @readerGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get readerGoBack;

  /// No description provided for @readerEnd.
  ///
  /// In en, this message translates to:
  /// **'The End'**
  String get readerEnd;

  /// No description provided for @readerSettingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Reader settings'**
  String get readerSettingsTooltip;

  /// No description provided for @readerPreviousPage.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get readerPreviousPage;

  /// No description provided for @readerNextPage.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get readerNextPage;

  /// No description provided for @readerPageOfTotal.
  ///
  /// In en, this message translates to:
  /// **'/ {total}'**
  String readerPageOfTotal(int total);

  /// No description provided for @searchTabHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get searchTabHistory;

  /// No description provided for @searchTabTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get searchTabTags;

  /// No description provided for @searchNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No search history'**
  String get searchNoHistory;

  /// No description provided for @searchClearFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get searchClearFilter;

  /// No description provided for @searchInCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'Search this category'**
  String get searchInCategoryHint;

  /// No description provided for @searchNoTagsInCategory.
  ///
  /// In en, this message translates to:
  /// **'No tags in this category'**
  String get searchNoTagsInCategory;

  /// No description provided for @searchNoTagsMatching.
  ///
  /// In en, this message translates to:
  /// **'No tags match \"{query}\"'**
  String searchNoTagsMatching(String query);

  /// No description provided for @searchTagWithCount.
  ///
  /// In en, this message translates to:
  /// **'{name} ({count})'**
  String searchTagWithCount(String name, int count);

  /// No description provided for @searchSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'Selected {count}'**
  String searchSelectedCount(int count);

  /// No description provided for @homeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search comic'**
  String get homeSearchHint;

  /// No description provided for @homeRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get homeRefreshTooltip;

  /// No description provided for @homeCollectionsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load collections'**
  String get homeCollectionsFailed;

  /// No description provided for @homeLoadingPage.
  ///
  /// In en, this message translates to:
  /// **'Loading… page {page}'**
  String homeLoadingPage(int page);

  /// No description provided for @downloadsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search downloaded comics'**
  String get downloadsSearchHint;

  /// No description provided for @bootstrapLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading index…'**
  String get bootstrapLoading;

  /// No description provided for @sortFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Sort & Filter'**
  String get sortFilterTitle;

  /// No description provided for @sortFilterSortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortFilterSortBy;

  /// No description provided for @sortFilterLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get sortFilterLatest;

  /// No description provided for @sortFilterTagFilters.
  ///
  /// In en, this message translates to:
  /// **'Tag filters'**
  String get sortFilterTagFilters;

  /// No description provided for @sortFilterTagHelp.
  ///
  /// In en, this message translates to:
  /// **'Tags are combined with the current search. Format: type:name (e.g. tag:full-color)'**
  String get sortFilterTagHelp;

  /// No description provided for @sortFilterTagHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. tag:full-color'**
  String get sortFilterTagHint;

  /// No description provided for @sortFilterAddTag.
  ///
  /// In en, this message translates to:
  /// **'Add tag filter'**
  String get sortFilterAddTag;

  /// No description provided for @comicCardDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get comicCardDownload;

  /// No description provided for @comicCardStartingDownload.
  ///
  /// In en, this message translates to:
  /// **'Starting download…'**
  String get comicCardStartingDownload;

  /// No description provided for @comicCardManageInDownloads.
  ///
  /// In en, this message translates to:
  /// **'Manage in Downloads tab'**
  String get comicCardManageInDownloads;

  /// No description provided for @comicCardStatusDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get comicCardStatusDownloaded;

  /// No description provided for @comicCardRemoveFrom.
  ///
  /// In en, this message translates to:
  /// **'Remove from {collection}'**
  String comicCardRemoveFrom(String collection);

  /// No description provided for @comicCardRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this comic from {collection}?'**
  String comicCardRemoveTitle(String collection);

  /// No description provided for @comicCardRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'Careful! You can\'t undo this action. You are removing: {title}'**
  String comicCardRemoveBody(String title);

  /// No description provided for @comicCardRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'REMOVE'**
  String get comicCardRemoveConfirm;

  /// No description provided for @imageCopyUrl.
  ///
  /// In en, this message translates to:
  /// **'Copy image URL'**
  String get imageCopyUrl;

  /// No description provided for @imageLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard'**
  String get imageLinkCopied;

  /// No description provided for @readerSimilarInLibrary.
  ///
  /// In en, this message translates to:
  /// **'Similar ones in your library'**
  String get readerSimilarInLibrary;

  /// No description provided for @readerSharedTags.
  ///
  /// In en, this message translates to:
  /// **'Shares {tags}'**
  String readerSharedTags(String tags);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
