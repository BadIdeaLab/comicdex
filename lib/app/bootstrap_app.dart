import 'package:concept_nhv/app/app_router.dart';
import 'package:concept_nhv/app/app_providers.dart';
import 'package:concept_nhv/services/local_tag_catalog_service.dart';
import 'package:concept_nhv/services/tag_display_service.dart';
import 'package:concept_nhv/storage/local_database.dart';
import 'package:concept_nhv/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BootstrapApp extends StatelessWidget {
  const BootstrapApp({
    super.key,
    required this.localDatabase,
    required this.tagDisplayService,
    required this.localTagCatalogService,
  });

  final LocalDatabase localDatabase;
  final TagDisplayService tagDisplayService;
  final LocalTagCatalogService localTagCatalogService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: buildAppProviders(localDatabase, tagDisplayService, localTagCatalogService),
      child: MaterialApp.router(
        theme: buildAppTheme(),
        routerConfig: createAppRouter(),
      ),
    );
  }
}
