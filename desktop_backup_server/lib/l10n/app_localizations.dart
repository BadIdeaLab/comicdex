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

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Comicdex Backup Server'**
  String get appTitle;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageTraditionalChinese.
  ///
  /// In en, this message translates to:
  /// **'繁體中文'**
  String get languageTraditionalChinese;

  /// No description provided for @refreshDevices.
  ///
  /// In en, this message translates to:
  /// **'Refresh addresses and devices'**
  String get refreshDevices;

  /// No description provided for @connectTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect from your phone'**
  String get connectTitle;

  /// No description provided for @connectAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get connectAddressLabel;

  /// No description provided for @connectPinLabel.
  ///
  /// In en, this message translates to:
  /// **'Pairing PIN'**
  String get connectPinLabel;

  /// No description provided for @connectNewPin.
  ///
  /// In en, this message translates to:
  /// **'New PIN'**
  String get connectNewPin;

  /// No description provided for @connectPinChangesNote.
  ///
  /// In en, this message translates to:
  /// **'The PIN changes every time this app restarts.'**
  String get connectPinChangesNote;

  /// No description provided for @connectNoNetwork.
  ///
  /// In en, this message translates to:
  /// **'No network connection found'**
  String get connectNoNetwork;

  /// No description provided for @connectServerStopped.
  ///
  /// In en, this message translates to:
  /// **'Server is not running.'**
  String get connectServerStopped;

  /// No description provided for @connectVirtualAdapterTag.
  ///
  /// In en, this message translates to:
  /// **'virtual — probably not this one'**
  String get connectVirtualAdapterTag;

  /// No description provided for @connectCopyAddress.
  ///
  /// In en, this message translates to:
  /// **'Copy address'**
  String get connectCopyAddress;

  /// No description provided for @connectAddressCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied {address}'**
  String connectAddressCopied(String address);

  /// No description provided for @firewallHint.
  ///
  /// In en, this message translates to:
  /// **'No device has connected yet. If your phone cannot reach this machine, check that Windows Firewall is allowing this app on private networks — that prompt is the most common cause, and it looks the same as a wrong address.'**
  String get firewallHint;

  /// No description provided for @lockedOutHint.
  ///
  /// In en, this message translates to:
  /// **'Temporarily blocked after repeated wrong PINs: {addresses}'**
  String lockedOutHint(String addresses);

  /// No description provided for @folderTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup folder'**
  String get folderTitle;

  /// No description provided for @folderNotSet.
  ///
  /// In en, this message translates to:
  /// **'(not set)'**
  String get folderNotSet;

  /// No description provided for @folderChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get folderChange;

  /// No description provided for @folderPickConfirm.
  ///
  /// In en, this message translates to:
  /// **'Use this folder'**
  String get folderPickConfirm;

  /// No description provided for @folderMissingWarning.
  ///
  /// In en, this message translates to:
  /// **'This folder is not available right now (an external drive may be disconnected). Backups are refused until it is back so the phone never mistakes an empty mirror for \"nothing backed up yet\" and re-uploads everything.'**
  String get folderMissingWarning;

  /// No description provided for @devicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Backed up devices'**
  String get devicesTitle;

  /// No description provided for @devicesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing backed up yet.'**
  String get devicesEmpty;

  /// No description provided for @devicesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{fileCount} files · {size} · {snapshotCount} database snapshot(s)'**
  String devicesSubtitle(int fileCount, String size, int snapshotCount);

  /// No description provided for @devicesLastSync.
  ///
  /// In en, this message translates to:
  /// **'last sync {timestamp}'**
  String devicesLastSync(String timestamp);

  /// No description provided for @controlTitle.
  ///
  /// In en, this message translates to:
  /// **'Connected phones'**
  String get controlTitle;

  /// No description provided for @controlEmpty.
  ///
  /// In en, this message translates to:
  /// **'No phone is connected. Open Backup in the mobile app and pair it first.'**
  String get controlEmpty;

  /// No description provided for @controlStartBackup.
  ///
  /// In en, this message translates to:
  /// **'Start backup'**
  String get controlStartBackup;

  /// No description provided for @controlPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get controlPause;

  /// No description provided for @controlStateIdle.
  ///
  /// In en, this message translates to:
  /// **'Connected · ready'**
  String get controlStateIdle;

  /// No description provided for @controlStateRunning.
  ///
  /// In en, this message translates to:
  /// **'Backing up…'**
  String get controlStateRunning;

  /// No description provided for @controlStatePausing.
  ///
  /// In en, this message translates to:
  /// **'Pausing after the current file…'**
  String get controlStatePausing;

  /// No description provided for @controlStatePaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get controlStatePaused;

  /// No description provided for @controlStateCompleted.
  ///
  /// In en, this message translates to:
  /// **'Backup completed'**
  String get controlStateCompleted;

  /// No description provided for @controlStateError.
  ///
  /// In en, this message translates to:
  /// **'Backup failed'**
  String get controlStateError;

  /// No description provided for @activityTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activityTitle;

  /// No description provided for @activityEmpty.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a device to connect…'**
  String get activityEmpty;

  /// No description provided for @activityFolderChanged.
  ///
  /// In en, this message translates to:
  /// **'Backup folder changed to {path}'**
  String activityFolderChanged(String path);

  /// No description provided for @activityPinRegenerated.
  ///
  /// In en, this message translates to:
  /// **'PIN regenerated'**
  String get activityPinRegenerated;

  /// No description provided for @activityCleanedPartFiles.
  ///
  /// In en, this message translates to:
  /// **'Cleaned up {count} interrupted transfer(s)'**
  String activityCleanedPartFiles(int count);

  /// No description provided for @activityDeletedStaleFiles.
  ///
  /// In en, this message translates to:
  /// **'Deleted {count} stale file(s) for {deviceId}'**
  String activityDeletedStaleFiles(int count, String deviceId);

  /// No description provided for @activityReceivedFile.
  ///
  /// In en, this message translates to:
  /// **'Received {path} from {deviceId}'**
  String activityReceivedFile(String path, String deviceId);

  /// No description provided for @activitySentFile.
  ///
  /// In en, this message translates to:
  /// **'Sent {path} to {deviceId}'**
  String activitySentFile(String path, String deviceId);

  /// No description provided for @activityStoredDatabase.
  ///
  /// In en, this message translates to:
  /// **'Stored database snapshot for {deviceId}'**
  String activityStoredDatabase(String deviceId);

  /// No description provided for @activitySentDatabase.
  ///
  /// In en, this message translates to:
  /// **'Sent database snapshot to {deviceId}'**
  String activitySentDatabase(String deviceId);

  /// No description provided for @activityBlockedPin.
  ///
  /// In en, this message translates to:
  /// **'Blocked repeated wrong PIN from {address}'**
  String activityBlockedPin(String address);

  /// No description provided for @activityPruneRequested.
  ///
  /// In en, this message translates to:
  /// **'Prune requested by {deviceId}: {count} stale files'**
  String activityPruneRequested(String deviceId, int count);

  /// No description provided for @pruneTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete files the phone no longer has?'**
  String get pruneTitle;

  /// No description provided for @pruneSummary.
  ///
  /// In en, this message translates to:
  /// **'{deviceId} asked to clean up {count} file(s), freeing {size}.'**
  String pruneSummary(String deviceId, int count, String size);

  /// No description provided for @pruneExplanation.
  ///
  /// In en, this message translates to:
  /// **'These exist in the backup but not on the phone. Deleting is permanent — if they were removed from the phone by mistake, keeping them here is the only remaining copy.'**
  String get pruneExplanation;

  /// No description provided for @pruneKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep everything'**
  String get pruneKeep;

  /// No description provided for @pruneDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get pruneDelete;

  /// No description provided for @pruneDeletedToast.
  ///
  /// In en, this message translates to:
  /// **'Deleted {count} file(s)'**
  String pruneDeletedToast(int count);

  /// No description provided for @controlRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore…'**
  String get controlRestore;

  /// No description provided for @restoreDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore {deviceId} from a backup?'**
  String restoreDialogTitle(String deviceId);

  /// No description provided for @restoreDialogChooseSource.
  ///
  /// In en, this message translates to:
  /// **'Which backup should it be restored from?'**
  String get restoreDialogChooseSource;

  /// No description provided for @restoreDialogWarning.
  ///
  /// In en, this message translates to:
  /// **'The phone will delete downloaded comics that this backup does not contain, then fetch back everything it is missing. Its database is replaced too, and the app restarts when it finishes. The nhentai API key is not part of a backup, so it will need signing in again.'**
  String get restoreDialogWarning;

  /// No description provided for @restoreDialogNoBackups.
  ///
  /// In en, this message translates to:
  /// **'There are no backups on this computer yet.'**
  String get restoreDialogNoBackups;

  /// No description provided for @restoreConfirm.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreConfirm;

  /// No description provided for @restoreCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get restoreCancel;

  /// No description provided for @restoreStarted.
  ///
  /// In en, this message translates to:
  /// **'Restore started on {deviceId}'**
  String restoreStarted(String deviceId);

  /// No description provided for @controlStateRestoring.
  ///
  /// In en, this message translates to:
  /// **'Restoring…'**
  String get controlStateRestoring;
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
