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
  /// **'Once connected, start or pause backup from the computer. This phone performs the transfer and reports its progress there.'**
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
  /// **'Wrong PIN. Check the number shown on the computer — it changes every time that app restarts.'**
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
