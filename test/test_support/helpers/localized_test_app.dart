import 'package:concept_nhv/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// A [MaterialApp] carrying the app's localisation delegates.
///
/// Any widget that reads `AppLocalizations.of(context)!` throws a bare null
/// check error under a plain `MaterialApp`, and the message says nothing
/// about localisation — so every localised widget test wants this instead.
///
/// [locale] pins the language when a test asserts on translated text; leave
/// it unset to get the template (English).
MaterialApp localizedTestApp({required Widget home, Locale? locale}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}

/// [localizedTestApp] for tests that drive the screen through a router.
MaterialApp localizedTestRouterApp({
  required RouterConfig<Object> routerConfig,
  Locale? locale,
}) {
  return MaterialApp.router(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: routerConfig,
  );
}
