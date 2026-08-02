import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Chosen UI language for the desktop app.
///
/// Mirrors the mobile app's approach (see its `AppLocaleModel`): `null` locale
/// means "follow the OS", which is the default.
class AppLocaleModel extends ChangeNotifier {
  static const String systemOption = 'system';
  static const String _prefsKey = 'appLocaleOption';

  /// Hard-coded rather than derived from `AppLocalizations.supportedLocales`
  /// because that list also contains the bare `zh` entry that `flutter gen-l10n`
  /// requires as a fallback but which is not a user-facing choice.
  static const List<String> availableOptions = <String>[
    systemOption,
    'en',
    'zh_Hant',
  ];

  String _option = systemOption;

  String get option => _option;

  Locale? get locale => switch (_option) {
    'en' => const Locale('en'),
    'zh_Hant' => const Locale.fromSubtags(
      languageCode: 'zh',
      scriptCode: 'Hant',
    ),
    _ => null,
  };

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null && availableOptions.contains(saved)) {
      _option = saved;
    }
    notifyListeners();
  }

  Future<void> setOption(String option) async {
    if (!availableOptions.contains(option) || option == _option) {
      return;
    }
    _option = option;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, option);
  }
}
