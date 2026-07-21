import 'package:concept_nhv/app/app_router.dart';
import 'package:concept_nhv/app/app_providers.dart';
import 'package:concept_nhv/l10n/app_localizations.dart';
import 'package:concept_nhv/services/local_tag_catalog_service.dart';
import 'package:concept_nhv/services/tag_display_service.dart';
import 'package:concept_nhv/state/app_locale_model.dart';
import 'package:concept_nhv/storage/local_database.dart';
import 'package:concept_nhv/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

class BootstrapApp extends StatelessWidget {
  const BootstrapApp({
    super.key,
    required this.localDatabase,
    required this.tagDisplayService,
    required this.localTagCatalogService,
    required this.appLocaleModel,
  });

  final LocalDatabase localDatabase;
  final TagDisplayService tagDisplayService;
  final LocalTagCatalogService localTagCatalogService;
  final AppLocaleModel appLocaleModel;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: buildAppProviders(
        localDatabase,
        tagDisplayService,
        localTagCatalogService,
        appLocaleModel,
      ),
      child: Consumer<AppLocaleModel>(
        builder: (context, localeModel, _) {
          return MaterialApp.router(
            theme: buildAppTheme(),
            locale: localeModel.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const <LocalizationsDelegate<Object?>>[
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: createAppRouter(),
          );
        },
      ),
    );
  }
}
