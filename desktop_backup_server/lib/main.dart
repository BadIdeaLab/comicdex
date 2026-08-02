import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'state/app_locale_model.dart';
import 'state/server_model.dart';
import 'storage/server_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // One read of config.json, shared by both models.
  final configStore = ServerConfigStore();
  final config = await configStore.load();

  final localeModel = AppLocaleModel(configStore: configStore)
    ..adoptConfig(config);
  final model = ServerModel(configStore: configStore);
  // Started before the first frame so the connection details (address, port,
  // PIN) are already on screen when the window appears.
  await model.initialize(config);

  runApp(BackupServerApp(model: model, localeModel: localeModel));
}

class BackupServerApp extends StatelessWidget {
  const BackupServerApp({
    super.key,
    required this.model,
    required this.localeModel,
  });

  final ServerModel model;
  final AppLocaleModel localeModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: localeModel,
      builder: (context, _) {
        return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
          // null follows the OS language, which is the default.
          locale: localeModel.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF4A6FA5),
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF4A6FA5),
              brightness: Brightness.dark,
            ),
          ),
          home: HomeScreen(model: model, localeModel: localeModel),
        );
      },
    );
  }
}
