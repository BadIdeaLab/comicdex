import 'package:concept_nhv/application/settings/app_locale_repository.dart';
import 'package:concept_nhv/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Tracks the user's chosen app display language (distinct from any comic
/// search language filter). `null` [locale] means "follow the system
/// language" — [MaterialApp.locale] already treats `null` this way.
class AppLocaleModel extends ChangeNotifier {
  AppLocaleModel({required this.repository});

  final AppLocaleRepository repository;

  String _selectedOption = AppLocaleRepository.systemOption;

  /// The persisted option string (`'system'`, or a locale code such as
  /// `'en'` / `'zh_Hant'`).
  String get selectedOption => _selectedOption;

  /// `null` means "follow the system language".
  Locale? get locale => _localeForOption(_selectedOption);

  /// All selectable options shown in Settings. Hardcoded rather than derived
  /// from [AppLocalizations.supportedLocales] because that list also
  /// includes a generic `zh` fallback (required by `flutter gen-l10n`
  /// alongside `zh_Hant`) that isn't meant to be its own picker entry.
  static const List<String> availableOptions = <String>[
    AppLocaleRepository.systemOption,
    'en',
    'zh_Hant',
  ];

  Future<void> initialize() async {
    _selectedOption = await repository.loadLocaleOption();
    notifyListeners();
  }

  Future<void> setOption(String option) async {
    if (_selectedOption == option) {
      return;
    }
    _selectedOption = option;
    await repository.saveLocaleOption(option);
    notifyListeners();
  }

  static Locale? _localeForOption(String option) {
    if (option == AppLocaleRepository.systemOption) {
      return null;
    }
    for (final locale in AppLocalizations.supportedLocales) {
      if (_optionCodeForLocale(locale) == option) {
        return locale;
      }
    }
    return null;
  }

  static String _optionCodeForLocale(Locale locale) {
    if (locale.scriptCode != null) {
      return '${locale.languageCode}_${locale.scriptCode}';
    }
    return locale.languageCode;
  }
}
