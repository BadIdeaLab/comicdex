import 'package:flutter/material.dart';

import '../storage/server_config.dart';

/// Chosen UI language for the desktop app.
///
/// Mirrors the mobile app's approach (see its `AppLocaleModel`): `null` locale
/// means "follow the OS", which is the default.
class AppLocaleModel extends ChangeNotifier {
  AppLocaleModel({required ServerConfigStore configStore})
    : _configStore = configStore;

  static const String systemOption = ServerConfig.defaultLanguage;

  /// Hard-coded rather than derived from `AppLocalizations.supportedLocales`
  /// because that list also contains the bare `zh` entry that `flutter gen-l10n`
  /// requires as a fallback but which is not a user-facing choice.
  static const List<String> availableOptions = <String>[
    systemOption,
    'en',
    'zh_Hant',
  ];

  final ServerConfigStore _configStore;

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

  /// Seeds from an already-loaded config so startup only reads the file once.
  void adoptConfig(ServerConfig config) {
    if (availableOptions.contains(config.language)) {
      _option = config.language;
      notifyListeners();
    }
  }

  Future<void> setOption(String option) async {
    if (!availableOptions.contains(option) || option == _option) {
      return;
    }
    _option = option;
    notifyListeners();
    final current = await _configStore.load();
    await _configStore.save(current.copyWith(language: option));
  }
}
