import 'dart:io';

import 'package:concept_nhv/app/bootstrap_app.dart';
import 'package:concept_nhv/services/local_tag_catalog_service.dart';
import 'package:concept_nhv/services/tag_display_service.dart';
import 'package:concept_nhv/state/app_locale_model.dart';
import 'package:concept_nhv/storage/app_locale_store.dart';
import 'package:concept_nhv/storage/local_database.dart';
import 'package:concept_nhv/storage/options_store.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    await FlutterDisplayMode.setHighRefreshRate();
  }

  final localDatabase = LocalDatabase();
  await localDatabase.initialize();
  final tagDisplayService = await TagDisplayService.load();
  final localTagCatalogService = await LocalTagCatalogService.load();
  final appLocaleModel = AppLocaleModel(
    repository: AppLocaleStore(
      optionsStore: OptionsStore(localDatabase: localDatabase),
    ),
  );
  await appLocaleModel.initialize();

  runApp(
    BootstrapApp(
      localDatabase: localDatabase,
      tagDisplayService: tagDisplayService,
      localTagCatalogService: localTagCatalogService,
      appLocaleModel: appLocaleModel,
    ),
  );
}
