import 'package:concept_nhv/application/downloads/download_settings_repository.dart';
import 'package:concept_nhv/application/search/blocked_tags_repository.dart';
import 'package:concept_nhv/application/tags/build_tag_preference_vector_use_case.dart';
import 'package:concept_nhv/application/tags/find_similar_comics_use_case.dart';
import 'package:concept_nhv/application/tags/tag_preference_vector.dart';
import 'package:concept_nhv/application/favorites/clear_favorite_auth_use_case.dart';
import 'package:concept_nhv/application/favorites/initialize_favorites_use_case.dart';
import 'package:concept_nhv/application/favorites/save_api_key_use_case.dart';
import 'package:concept_nhv/application/favorites/sync_remote_favorites_use_case.dart';
import 'package:concept_nhv/application/favorites/toggle_favorite_use_case.dart';
import 'package:concept_nhv/application/feed/load_collection_summaries_use_case.dart';
import 'package:concept_nhv/application/feed/search_comics_use_case.dart';
import 'package:concept_nhv/application/home/app_shell_navigation_controller.dart';
import 'package:concept_nhv/application/home/home_shell_controller.dart';
import 'package:concept_nhv/application/library/collection_page_coordinator.dart';
import 'package:concept_nhv/application/library/comic_card_action_coordinator.dart';
import 'package:concept_nhv/application/library/load_collection_comics_use_case.dart';
import 'package:concept_nhv/application/library/remove_comic_from_collection_use_case.dart';
import 'package:concept_nhv/application/library/save_comic_to_collection_use_case.dart';
import 'package:concept_nhv/application/reader/load_comic_detail_use_case.dart';
import 'package:concept_nhv/application/reader/load_offline_comic_use_case.dart';
import 'package:concept_nhv/application/reader/open_comic_use_case.dart';
import 'package:concept_nhv/application/reader/reader_launcher.dart';
import 'package:concept_nhv/application/reader/reader_settings_repository.dart';
import 'package:concept_nhv/application/tags/check_tag_catalog_update_use_case.dart';
import 'package:concept_nhv/application/tags/load_tag_cooccurrence_use_case.dart';
import 'package:concept_nhv/application/tags/load_tag_coverage_use_case.dart';
import 'package:concept_nhv/application/tags/load_tag_preferences_use_case.dart';
import 'package:concept_nhv/application/tags/load_comic_meta_use_case.dart';
import 'package:concept_nhv/application/tags/update_local_tag_catalog_use_case.dart';
import 'package:concept_nhv/services/image_url_resolver.dart';
import 'package:concept_nhv/state/app_locale_model.dart';
import 'package:concept_nhv/services/backup/backup_client.dart';
import 'package:concept_nhv/services/backup/backup_control_client.dart';
import 'package:concept_nhv/services/backup/backup_restore_service.dart';
import 'package:concept_nhv/services/backup/pairing_code_reader.dart';
import 'package:concept_nhv/services/backup/pairing_memory.dart';
import 'package:concept_nhv/services/backup/restore_progress_flag.dart';
import 'package:concept_nhv/services/backup/backup_sync_service.dart';
import 'package:concept_nhv/services/backup/snapshot_database_reader.dart';
import 'package:concept_nhv/services/backup/device_name_service.dart';
import 'package:concept_nhv/services/download_asset_store.dart';
import 'package:concept_nhv/services/local_tag_catalog_service.dart';
import 'package:concept_nhv/services/tag_display_service.dart';
import 'package:concept_nhv/services/image_compression_service.dart';
import 'package:concept_nhv/services/library_import_service.dart';
import 'package:concept_nhv/services/comic_page_source_resolver.dart';
import 'package:concept_nhv/services/nhentai_auth_service.dart';
import 'package:concept_nhv/services/nhentai_api_client.dart';
import 'package:concept_nhv/services/nhentai_cdn_config_service.dart';
import 'package:concept_nhv/services/remote_asset_fetcher.dart';
import 'package:concept_nhv/services/remote_favorite_gateway.dart';
import 'package:concept_nhv/services/search_query_builder.dart';
import 'package:concept_nhv/services/tag_search_query_builder.dart';
import 'package:concept_nhv/state/blocked_tags_model.dart';
import 'package:concept_nhv/state/backup_control_model.dart';
import 'package:concept_nhv/state/comic_feed_model.dart';
import 'package:concept_nhv/state/reader_settings_model.dart';
import 'package:concept_nhv/state/download_manager_model.dart';
import 'package:concept_nhv/state/favorite_sync_model.dart';
import 'package:concept_nhv/state/home_ui_model.dart';
import 'package:concept_nhv/state/preference_score_model.dart';
import 'package:concept_nhv/state/tag_catalog_browser_model.dart';
import 'package:concept_nhv/state/tag_preference_model.dart';
import 'package:concept_nhv/storage/collection_repository.dart';
import 'package:concept_nhv/storage/comic_repository.dart';
import 'package:concept_nhv/storage/comic_tag_repository.dart';
import 'package:concept_nhv/storage/tag_preference_store.dart';
import 'package:concept_nhv/storage/download_queue_repository.dart';
import 'package:concept_nhv/storage/blocked_tags_store.dart';
import 'package:concept_nhv/storage/download_settings_store.dart';
import 'package:concept_nhv/storage/downloaded_library_repository.dart';
import 'package:concept_nhv/storage/local_database.dart';
import 'package:concept_nhv/storage/nhentai_api_key_store.dart';
import 'package:concept_nhv/storage/options_store.dart';
import 'package:concept_nhv/storage/reader_settings_store.dart';
import 'package:concept_nhv/storage/search_history_repository.dart';
import 'package:concept_nhv/storage/secure_key_value_store.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Builds the full provider tree for the app.
///
/// Registration order matters: later providers may depend on earlier ones
/// via `context.read()` inside their `create` callbacks, so the buckets
/// below are concatenated in the same order the dependencies require
/// (infrastructure → storage → services → use cases → state → coordinators).
List<SingleChildWidget> buildAppProviders(
  LocalDatabase localDatabase,
  TagDisplayService tagDisplayService,
  LocalTagCatalogService localTagCatalogService,
  AppLocaleModel appLocaleModel,
) {
  return <SingleChildWidget>[
    ..._buildInfrastructureProviders(
      localDatabase,
      tagDisplayService,
      localTagCatalogService,
      appLocaleModel,
    ),
    ..._buildStorageProviders(),
    ..._buildServiceProviders(),
    ..._buildUseCaseProviders(),
    ..._buildStateProviders(),
    ..._buildCoordinatorProviders(),
  ];
}

List<SingleChildWidget> _buildInfrastructureProviders(
  LocalDatabase localDatabase,
  TagDisplayService tagDisplayService,
  LocalTagCatalogService localTagCatalogService,
  AppLocaleModel appLocaleModel,
) {
  return <SingleChildWidget>[
    Provider<TagDisplayService>.value(value: tagDisplayService),
    ChangeNotifierProvider<LocalTagCatalogService>.value(
      value: localTagCatalogService,
    ),
    ChangeNotifierProvider<AppLocaleModel>.value(value: appLocaleModel),
    Provider<LocalDatabase>.value(value: localDatabase),
    Provider(create: (context) => OptionsStore(localDatabase: context.read())),
    Provider<SecureKeyValueStore>(create: (_) => FlutterSecureKeyValueStore()),
    Provider(
      create: (context) => NhentaiApiKeyStore(secureStore: context.read()),
    ),
  ];
}

List<SingleChildWidget> _buildStorageProviders() {
  return <SingleChildWidget>[
    Provider(
      create: (context) => ComicRepository(localDatabase: context.read()),
    ),
    Provider(
      create: (context) => CollectionRepository(localDatabase: context.read()),
    ),
    Provider(
      create: (context) => ComicTagRepository(localDatabase: context.read()),
    ),
    Provider(
      create: (context) => TagPreferenceStore(optionsStore: context.read()),
    ),
    Provider(
      create: (context) =>
          SearchHistoryRepository(localDatabase: context.read()),
    ),
    Provider<ReaderSettingsRepository>(
      create: (context) => ReaderSettingsStore(optionsStore: context.read()),
    ),
    Provider<DownloadSettingsRepository>(
      create: (context) => DownloadSettingsStore(optionsStore: context.read()),
    ),
    Provider<BlockedTagsRepository>(
      create: (context) => BlockedTagsStore(optionsStore: context.read()),
    ),
    Provider(
      create: (context) =>
          DownloadQueueRepository(localDatabase: context.read()),
    ),
    Provider(
      create: (context) =>
          DownloadedLibraryRepository(localDatabase: context.read()),
    ),
  ];
}

List<SingleChildWidget> _buildServiceProviders() {
  return <SingleChildWidget>[
    Provider(create: (_) => const SearchQueryBuilder()),
    Provider(create: (_) => const TagSearchQueryBuilder()),
    Provider(create: (_) => const ComicPageSourceResolver()),
    Provider(create: (_) => DownloadAssetStore()),
    Provider<ImageCompressionService>(
      create: (_) => const FlutterImageCompressionService(),
    ),
    Provider<RemoteAssetFetcher>(create: (_) => DioRemoteAssetFetcher()),
    Provider<BackupClient>(create: (_) => DioBackupClient()),
    Provider<BackupSyncService>(
      create: (context) {
        final database = context.read<LocalDatabase>();
        return BackupSyncService(
          client: context.read(),
          downloadAssetStore: context.read(),
          downloadQueueRepository: context.read(),
          schemaVersion: database.schemaVersion,
          snapshotBuilder: vacuumSnapshotBuilder(
            database: database,
            temporaryDirectory: getTemporaryDirectory,
          ),
        );
      },
    ),
    // Registered separately so the bootstrap screen can read the flag without
    // building the whole restore service, and so both see the same instance.
    Provider<RestoreProgressFlag>(
      create: (_) =>
          RestoreProgressFlag(supportDirectory: getApplicationSupportDirectory),
    ),
    Provider<BackupRestoreService>(
      create: (context) => BackupRestoreService(
        client: context.read(),
        downloadAssetStore: context.read(),
        appSchemaVersion: context.read<LocalDatabase>().schemaVersion,
        databaseReader: sqliteSnapshotReader,
        supportDirectory: getApplicationSupportDirectory,
        progressFlag: context.read(),
      ),
    ),
    Provider<BackupControlClient>(
      create: (_) => WebSocketBackupControlClient(),
    ),
    Provider(create: (_) => DeviceNameService()),
    // Built lazily: constructing it touches the camera and photo-library
    // plugins, which no other screen needs.
    Provider(create: (_) => PairingCodeReader.platform()),
    Provider(
      create: (_) =>
          PairingMemory(supportDirectory: getApplicationSupportDirectory),
    ),
    ChangeNotifierProvider(
      create: (context) => BackupControlModel(
        client: context.read(),
        healthClient: context.read(),
        syncService: context.read(),
        restoreService: context.read(),
      ),
    ),
    Provider(
      create: (_) {
        final service = NhentaiCdnConfigService();
        service.refreshInBackground();
        return service;
      },
    ),
    Provider(
      create: (context) => ImageUrlResolver(cdnConfigService: context.read()),
    ),
    Provider(
      create: (context) => NhentaiAuthService(apiKeyStore: context.read()),
    ),
    Provider<NhentaiGateway>(
      create: (context) => NhentaiApiClient(
        apiKeyStore: context.read(),
        cdnConfigService: context.read(),
      ),
    ),
    Provider<RemoteFavoriteGateway>(
      create: (context) => NhentaiApiRemoteFavoriteGateway(
        apiKeyStore: context.read(),
        authService: context.read(),
      ),
    ),
  ];
}

List<SingleChildWidget> _buildUseCaseProviders() {
  return <SingleChildWidget>[
    Provider(
      create: (context) => SearchComicsUseCase(
        nhentaiGateway: context.read(),
        searchQueryBuilder: context.read(),
      ),
    ),
    Provider(
      create: (context) =>
          LoadCollectionSummariesUseCase(collectionRepository: context.read()),
    ),
    Provider(
      create: (context) =>
          LoadCollectionComicsUseCase(collectionRepository: context.read()),
    ),
    Provider(
      create: (context) =>
          LoadComicDetailUseCase(nhentaiGateway: context.read()),
    ),
    Provider(
      create: (context) => LoadOfflineComicUseCase(
        downloadQueueRepository: context.read(),
        downloadedLibraryRepository: context.read(),
        downloadAssetStore: context.read(),
      ),
    ),
    Provider(
      create: (context) => OpenComicUseCase(
        comicRepository: context.read(),
        collectionRepository: context.read(),
        comicTagRepository: context.read(),
      ),
    ),
    Provider(
      create: (context) => LoadComicMetaUseCase(nhentaiGateway: context.read()),
    ),
    Provider(
      create: (context) => LoadTagPreferencesUseCase(
        comicTagRepository: context.read(),
        localTagCatalogService: context.read(),
        blockedTagsRepository: context.read(),
      ),
    ),
    Provider(
      create: (context) => BuildTagPreferenceVectorUseCase(
        loadTagPreferencesUseCase: context.read(),
        comicTagRepository: context.read(),
      ),
    ),
    Provider(
      create: (context) => FindSimilarComicsUseCase(
        comicTagRepository: context.read(),
        comicRepository: context.read(),
        localTagCatalogService: context.read(),
      ),
    ),
    Provider(
      create: (context) => LoadTagCooccurrenceUseCase(
        comicTagRepository: context.read(),
        localTagCatalogService: context.read(),
        blockedTagsRepository: context.read(),
      ),
    ),
    Provider(
      create: (context) =>
          LoadTagCoverageUseCase(comicTagRepository: context.read()),
    ),
    Provider(
      create: (context) => CheckTagCatalogUpdateUseCase(
        remoteAssetFetcher: context.read(),
        localTagCatalogService: context.read(),
      ),
    ),
    Provider(
      create: (context) => UpdateLocalTagCatalogUseCase(
        remoteAssetFetcher: context.read(),
        localTagCatalogService: context.read(),
      ),
    ),
    Provider(
      create: (context) => SaveComicToCollectionUseCase(
        comicRepository: context.read(),
        collectionRepository: context.read(),
      ),
    ),
    Provider(
      create: (context) => RemoveComicFromCollectionUseCase(
        collectionRepository: context.read(),
      ),
    ),
    Provider(
      create: (context) => InitializeFavoritesUseCase(
        collectionRepository: context.read(),
        authService: context.read(),
      ),
    ),
    Provider(
      create: (context) => SaveApiKeyUseCase(authService: context.read()),
    ),
    Provider(
      create: (context) =>
          ClearFavoriteAuthUseCase(authService: context.read()),
    ),
    Provider(
      create: (context) => SyncRemoteFavoritesUseCase(
        collectionRepository: context.read(),
        comicTagRepository: context.read(),
        remoteFavoriteGateway: context.read(),
      ),
    ),
    Provider(
      create: (context) => ToggleFavoriteUseCase(
        collectionRepository: context.read(),
        comicTagRepository: context.read(),
        remoteFavoriteGateway: context.read(),
        authService: context.read(),
      ),
    ),
    Provider(
      create: (context) => LibraryImportService(
        comicRepository: context.read(),
        collectionRepository: context.read(),
      ),
    ),
  ];
}

List<SingleChildWidget> _buildStateProviders() {
  return <SingleChildWidget>[
    ChangeNotifierProvider(create: (_) => HomeUiModel()),
    ChangeNotifierProvider(
      create: (context) {
        final model = BlockedTagsModel(blockedTagsRepository: context.read());
        model.load();
        return model;
      },
    ),
    ChangeNotifierProvider(
      create: (context) => TagPreferenceModel(
        loadTagPreferencesUseCase: context.read(),
        loadTagCooccurrenceUseCase: context.read(),
        loadTagCoverageUseCase: context.read(),
        tagPreferenceStore: context.read(),
      ),
    ),
    ChangeNotifierProvider(
      create: (context) => TagCatalogBrowserModel(
        localTagCatalogService: context.read(),
        tagDisplayService: context.read(),
      ),
    ),
    ChangeNotifierProvider(
      create: (context) => ComicFeedModel(
        searchComicsUseCase: context.read(),
        loadCollectionSummariesUseCase: context.read(),
        blockedTagsRepository: context.read(),
      ),
    ),
    ChangeNotifierProvider(
      create: (context) {
        final model = FavoriteSyncModel(
          initializeFavoritesUseCase: context.read(),
          saveApiKeyUseCase: context.read(),
          clearFavoriteAuthUseCase: context.read(),
          syncRemoteFavoritesUseCase: context.read(),
          toggleFavoriteUseCase: context.read(),
        );
        model.initialize();
        return model;
      },
    ),
    ChangeNotifierProvider(
      create: (context) {
        final model = PreferenceScoreModel(
          buildTagPreferenceVectorUseCase: context.read(),
        );
        model.ensureLoaded();
        return model;
      },
    ),
    // Republished as plain data so a comic card can read the vector without
    // depending on the model that loads it.
    ProxyProvider<PreferenceScoreModel, TagPreferenceVector>(
      update: (_, preferenceScores, _) => preferenceScores.vector,
    ),
    // Proxied rather than plain so the preference vector reaches the sort
    // comparator as soon as it is computed: the downloads list is built
    // before the first scoring pass finishes.
    ChangeNotifierProxyProvider<PreferenceScoreModel, DownloadManagerModel>(
      create: (context) {
        final model = DownloadManagerModel(
          nhentaiGateway: context.read(),
          cdnConfigService: context.read(),
          downloadQueueRepository: context.read(),
          downloadedLibraryRepository: context.read(),
          downloadSettingsRepository: context.read(),
          downloadAssetStore: context.read(),
          imageCompressionService: context.read(),
          remoteAssetFetcher: context.read(),
        );
        model.initialize();
        return model;
      },
      update: (_, preferenceScores, model) =>
          model!..setPreferenceVector(preferenceScores.vector),
    ),
    // Only the *preferences* are app-scoped. The state of an open comic lives
    // on the reader screen that shows it (ReaderSessionModel), so nothing
    // outside the reader can be woken by a page turn.
    ChangeNotifierProvider(
      create: (context) {
        final model = ReaderSettingsModel(
          readerSettingsRepository: context.read(),
        );
        model.loadSettings();
        return model;
      },
    ),
  ];
}

List<SingleChildWidget> _buildCoordinatorProviders() {
  return <SingleChildWidget>[
    Provider(
      create: (context) => AppShellNavigationController(
        homeUiModel: context.read(),
        feedModel: context.read(),
      ),
    ),
    Provider(
      create: (context) => HomeShellController(
        searchHistoryRepository: context.read(),
        homeUiModel: context.read(),
        feedModel: context.read(),
        tagSearchQueryBuilder: context.read(),
      ),
    ),
    Provider(
      create: (context) => CollectionPageCoordinator(
        loadCollectionComicsUseCase: context.read(),
        favoriteSyncModel: context.read(),
        feedModel: context.read(),
      ),
    ),
    Provider(
      create: (context) => ReaderLauncher(downloadManagerModel: context.read()),
    ),
    Provider(
      create: (context) => ComicCardActionCoordinator(
        saveComicToCollectionUseCase: context.read(),
        removeComicFromCollectionUseCase: context.read(),
        favoriteSyncModel: context.read(),
        feedModel: context.read(),
        downloadManagerModel: context.read(),
        loadComicMetaUseCase: context.read(),
      ),
    ),
  ];
}
