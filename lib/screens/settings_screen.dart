import 'package:concept_nhv/application/downloads/download_settings_repository.dart';
import 'package:concept_nhv/application/reader/reader_settings_repository.dart';
import 'package:concept_nhv/application/settings/app_locale_repository.dart';
import 'package:concept_nhv/application/tags/check_tag_catalog_update_use_case.dart';
import 'package:concept_nhv/application/tags/update_local_tag_catalog_use_case.dart';
import 'package:concept_nhv/l10n/app_localizations.dart';
import 'package:concept_nhv/services/library_import_service.dart';
import 'package:concept_nhv/services/local_tag_catalog_service.dart';
import 'package:concept_nhv/services/nhentai_auth_service.dart';
import 'package:concept_nhv/state/app_locale_model.dart';
import 'package:concept_nhv/state/blocked_tags_model.dart';
import 'package:concept_nhv/state/comic_feed_model.dart';
import 'package:concept_nhv/state/comic_reader_model.dart';
import 'package:concept_nhv/state/favorite_sync_model.dart';
import 'package:concept_nhv/widgets/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Future<_DownloadSettingsSnapshot> _downloadSettingsFuture;

  @override
  void initState() {
    super.initState();
    _downloadSettingsFuture = _loadDownloadSettings();
  }

  Future<_DownloadSettingsSnapshot> _loadDownloadSettings() async {
    final repository = context.read<DownloadSettingsRepository>();
    final autoResumeEnabled = await repository.loadAutoResumeEnabled();
    final pageIntervalMs = await repository.loadPageIntervalMs();
    return _DownloadSettingsSnapshot(
      autoResumeEnabled: autoResumeEnabled,
      pageIntervalMs: pageIntervalMs,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: GlassContainer.bar(child: const SizedBox.expand()),
            title: Text(l10n.settingsTitle),
          ),
          SliverList.list(
            children: <Widget>[
              _SettingsSection(
                title: l10n.sectionNhentaiApi,
                children: <Widget>[
                  _buildSessionStatusTile(context),
                  _buildLoginTile(context),
                  _buildSyncFavoritesTile(context),
                  _buildLogoutTile(context),
                ],
              ),
              _SettingsSection(
                title: l10n.sectionReader,
                children: <Widget>[
                  _buildPrefetchCountTile(context),
                  _buildClearCacheTile(context),
                ],
              ),
              _SettingsSection(
                title: l10n.sectionDownloads,
                children: <Widget>[
                  _buildAutoResumeDownloadsTile(context),
                  _buildPageDownloadIntervalTile(context),
                ],
              ),
              _SettingsSection(
                title: l10n.sectionBlockedTags,
                children: <Widget>[_buildBlockedTagsSection(context)],
              ),
              _SettingsSection(
                title: l10n.sectionTagDatabase,
                children: <Widget>[_buildTagDatabaseTile(context)],
              ),
              _SettingsSection(
                title: l10n.sectionGeneral,
                children: <Widget>[
                  _buildAppLanguageTile(context),
                  _buildDiagnoseTile(context),
                ],
              ),
              _SettingsSection(
                title: l10n.sectionAbout,
                children: <Widget>[
                  _buildImportTile(context),
                  _buildLicenseTile(context),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAutoResumeDownloadsTile(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<_DownloadSettingsSnapshot>(
      future: _downloadSettingsFuture,
      builder: (context, snapshot) {
        final enabled =
            snapshot.data?.autoResumeEnabled ??
            DownloadSettingsRepository.defaultAutoResumeEnabled;
        return SwitchListTile(
          title: Text(l10n.autoResumeDownloadsTitle),
          subtitle: Text(l10n.autoResumeDownloadsSubtitle),
          value: enabled,
          onChanged: (value) async {
            await context.read<DownloadSettingsRepository>().saveAutoResumeEnabled(
              value,
            );
            if (!mounted) {
              return;
            }
            setState(() {
              _downloadSettingsFuture = Future<_DownloadSettingsSnapshot>.value(
                _DownloadSettingsSnapshot(
                  autoResumeEnabled: value,
                  pageIntervalMs:
                      snapshot.data?.pageIntervalMs ??
                      DownloadSettingsRepository.defaultPageIntervalMs,
                ),
              );
            });
          },
        );
      },
    );
  }

  Widget _buildPageDownloadIntervalTile(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<_DownloadSettingsSnapshot>(
      future: _downloadSettingsFuture,
      builder: (context, snapshot) {
        final pageIntervalMs =
            snapshot.data?.pageIntervalMs ??
            DownloadSettingsRepository.defaultPageIntervalMs;
        return ListTile(
          title: Text(l10n.pageDownloadIntervalTitle),
          subtitle: Text(
            '${_formatIntervalSeconds(pageIntervalMs)}\n${l10n.appliesToNewDownloadsNote}',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            final updatedMilliseconds = await showDialog<int>(
              context: context,
              builder: (dialogContext) {
                return _PageDownloadIntervalDialog(
                  initialMilliseconds: pageIntervalMs,
                );
              },
            );

            if (updatedMilliseconds == null || !context.mounted) {
              return;
            }

            await context.read<DownloadSettingsRepository>().savePageIntervalMs(
              updatedMilliseconds,
            );
            setState(() {
              _downloadSettingsFuture = Future<_DownloadSettingsSnapshot>.value(
                _DownloadSettingsSnapshot(
                  autoResumeEnabled:
                      snapshot.data?.autoResumeEnabled ??
                      DownloadSettingsRepository.defaultAutoResumeEnabled,
                  pageIntervalMs: updatedMilliseconds,
                ),
              );
            });
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // nhentai API tiles
  // ---------------------------------------------------------------------------

  Widget _buildSessionStatusTile(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final favoriteModel = context.watch<FavoriteSyncModel>();
    final status = favoriteModel.isAuthenticated
        ? l10n.statusAuthenticated
        : l10n.statusNotConfigured;
    final syncError = favoriteModel.syncError;

    String subtitle;
    if (favoriteModel.isSyncing) {
      final page = favoriteModel.syncPage;
      final total = favoriteModel.syncTotalPages;
      final retryDeadline = favoriteModel.syncRetryDeadline;
      final progressPart = (page != null && total != null)
          ? l10n.statusSyncingWithProgress(page, total)
          : l10n.statusSyncingGeneric;
      if (retryDeadline != null) {
        final secondsLeft = retryDeadline
            .difference(DateTime.now())
            .inSeconds
            .clamp(0, 9999);
        subtitle =
            '$status\n$progressPart\n${l10n.statusRateLimitedRetrying(secondsLeft)}';
      } else {
        subtitle = '$status\n$progressPart';
      }
    } else if (syncError != null) {
      subtitle = '$status\n$syncError';
    } else {
      final lastSync =
          favoriteModel.lastSyncAt?.toLocal().toString() ?? l10n.statusNeverSynced;
      subtitle = '$status\n${l10n.statusLastSync(lastSync)}';
    }

    return ListTile(
      title: Text(l10n.statusTitle),
      subtitle: Text(subtitle),
    );
  }

  Widget _buildLoginTile(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      title: Text(l10n.setUpdateApiKeyTitle),
      subtitle: Text(l10n.setUpdateApiKeySubtitle),
      onTap: () async {
        final favoriteModel = context.read<FavoriteSyncModel>();
        final feedModel = context.read<ComicFeedModel>();
        final messenger = ScaffoldMessenger.of(context);
        final apiKey = await _promptApiKey(
          context,
          favoriteModel.isAuthenticated,
        );
        if (apiKey == null || apiKey.trim().isEmpty || !context.mounted) {
          return;
        }

        try {
          await favoriteModel.saveAndValidateApiKey(apiKey);
          await favoriteModel.syncFavorites();
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.apiKeySavedMessage)),
          );
        } on NhentaiAuthException catch (error) {
          messenger.showSnackBar(SnackBar(content: Text(error.message)));
        }
        feedModel.refreshCollections();
      },
    );
  }

  Widget _buildSyncFavoritesTile(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      title: Text(l10n.syncFavoritesNowTitle),
      subtitle: Text(l10n.syncFavoritesNowSubtitle),
      onTap: () async {
        final favoriteModel = context.read<FavoriteSyncModel>();
        final feedModel = context.read<ComicFeedModel>();
        final ok = await favoriteModel.syncFavorites();
        if (!context.mounted) return;

        feedModel.refreshCollections();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok
                  ? l10n.favoritesSyncedMessage
                  : favoriteModel.syncError ?? l10n.syncFailedMessage,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogoutTile(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      title: Text(l10n.clearApiKeyTitle),
      subtitle: Text(l10n.clearApiKeySubtitle),
      onTap: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: Text(l10n.clearApiKeyDialogTitle),
              content: Text(l10n.clearApiKeyDialogContent),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(l10n.cancelButton),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(l10n.clearButton),
                ),
              ],
            );
          },
        );
        if (confirmed != true || !context.mounted) {
          return;
        }

        final favoriteModel = context.read<FavoriteSyncModel>();
        final messenger = ScaffoldMessenger.of(context);
        await favoriteModel.clearApiKey();
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.apiKeyClearedMessage)),
        );
      },
    );
  }

  Future<String?> _promptApiKey(BuildContext context, bool isEditing) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            isEditing ? l10n.updateApiKeyDialogTitle : l10n.setApiKeyDialogTitle,
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            obscureText: true,
            decoration: InputDecoration(
              labelText: l10n.apiKeyFieldLabel,
              hintText: l10n.apiKeyFieldHint,
            ),
            onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancelButton),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: Text(l10n.saveButton),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Reader tiles
  // ---------------------------------------------------------------------------

  /// Shows the current prefetch page count and allows changing it via a slider.
  Widget _buildPrefetchCountTile(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final readerModel = context.watch<ComicReaderModel>();
    final count = readerModel.prefetchPageCount;
    return ListTile(
      title: Text(l10n.prefetchPagesTitle),
      subtitle: Text(
        l10n.prefetchPagesSubtitle(
          count,
          ReaderSettingsRepository.defaultPrefetchPageCount,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showPrefetchDialog(context, readerModel),
    );
  }

  Future<void> _showPrefetchDialog(
    BuildContext context,
    ComicReaderModel model,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _PrefetchCountDialog(model: model);
      },
    );
  }

  /// Clears all cached images from disk and memory.
  Widget _buildClearCacheTile(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      title: Text(l10n.clearImageCacheTitle),
      subtitle: Text(l10n.clearImageCacheSubtitle),
      trailing: const Icon(Icons.delete_outline),
      onTap: () async {
        final messenger = ScaffoldMessenger.of(context);
        // Disk cache (flutter_cache_manager / cached_network_image)
        await DefaultCacheManager().emptyCache();
        // Flutter's in-memory image cache
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();

        if (!context.mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.imageCacheClearedMessage)),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Blocked Tags tiles
  // ---------------------------------------------------------------------------

  Widget _buildBlockedTagsSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final blockedTagsModel = context.watch<BlockedTagsModel>();
    final tags = blockedTagsModel.blockedTags;

    if (tags.isEmpty) {
      return ListTile(
        dense: true,
        subtitle: Text(l10n.noBlockedTagsMessage),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: tags.map((query) {
        return ListTile(
          dense: true,
          title: Text(query),
          trailing: IconButton(
            icon: const Icon(Icons.close),
            tooltip: l10n.removeTooltip,
            onPressed: () => blockedTagsModel.removeTag(query),
          ),
        );
      }).toList(growable: false),
    );
  }

  // ---------------------------------------------------------------------------
  // Tag Database tiles
  // ---------------------------------------------------------------------------

  Widget _buildTagDatabaseTile(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final service = context.watch<LocalTagCatalogService>();
    final origin = service.isUsingOverride
        ? l10n.tagDatabaseOriginUpdated
        : l10n.tagDatabaseOriginBundled;
    return ListTile(
      title: Text(l10n.checkForTagDatabaseUpdatesTitle),
      subtitle: Text(
        l10n.tagDatabaseSubtitle(service.entryCount, service.version, origin),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _checkForTagCatalogUpdate(context),
    );
  }

  Future<void> _checkForTagCatalogUpdate(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final checkUseCase = context.read<CheckTagCatalogUpdateUseCase>();

    String? newVersion;
    try {
      newVersion = await checkUseCase.execute();
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.tagDatabaseCheckFailedMessage)),
      );
      return;
    }

    if (newVersion == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.tagDatabaseUpToDateMessage)),
      );
      return;
    }

    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.tagDatabaseUpdateAvailableDialogTitle),
          content: Text(
            l10n.tagDatabaseUpdateAvailableDialogContent(newVersion!),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancelButton),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.updateButton),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    final updateUseCase = context.read<UpdateLocalTagCatalogUseCase>();
    try {
      final count = await updateUseCase.execute();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.tagDatabaseUpdatedMessage(count))),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.tagDatabaseUpdateFailedMessage)),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // General tiles
  // ---------------------------------------------------------------------------

  Widget _buildAppLanguageTile(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeModel = context.watch<AppLocaleModel>();
    return ListTile(
      title: Text(l10n.appLanguageTitle),
      subtitle: Text(_appLanguageOptionLabel(l10n, localeModel.selectedOption)),
      onTap: () async {
        final messenger = ScaffoldMessenger.of(context);
        final selected = await showDialog<String>(
          context: context,
          builder: (dialogContext) {
            return SimpleDialog(
              title: Text(l10n.appLanguageTitle),
              children: AppLocaleModel.availableOptions.map((option) {
                return SimpleDialogOption(
                  onPressed: () => Navigator.of(dialogContext).pop(option),
                  child: Text(_appLanguageOptionLabel(l10n, option)),
                );
              }).toList(),
            );
          },
        );

        if (selected == null || !context.mounted) return;

        await localeModel.setOption(selected);
        if (!context.mounted) return;
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              l10n.appLanguageChangedMessage(
                _appLanguageOptionLabel(l10n, selected),
              ),
            ),
          ),
        );
      },
    );
  }

  String _appLanguageOptionLabel(AppLocalizations l10n, String option) {
    switch (option) {
      case AppLocaleRepository.systemOption:
        return l10n.appLanguageSystemDefault;
      case 'en':
        return l10n.appLanguageEnglish;
      case 'zh_Hant':
        return l10n.appLanguageTraditionalChinese;
      default:
        return option;
    }
  }

  Widget _buildDiagnoseTile(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      title: Text(l10n.diagnoseTitle),
      subtitle: Text(l10n.diagnoseSubtitle),
    );
  }

  // ---------------------------------------------------------------------------
  // About tiles
  // ---------------------------------------------------------------------------

  Widget _buildImportTile(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      title: Text(l10n.loadJsonNetworkTitle),
      onTap: () async {
        final feedModel = context.read<ComicFeedModel>();
        final url = await showDialog<String>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(l10n.enterUrlDialogTitle),
              content: TextField(
                autofocus: true,
                decoration: InputDecoration(labelText: l10n.urlFieldLabel),
                onSubmitted: (value) => Navigator.of(context).pop(value),
              ),
            );
          },
        );

        if (url == null || url.isEmpty || !context.mounted) return;

        await context.read<LibraryImportService>().importFromBaseUrl(url);
        feedModel.refreshCollections();
      },
    );
  }

  Widget _buildLicenseTile(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      title: Text(l10n.openSourceLicensesTitle),
      onTap: () => showLicensePage(context: context),
    );
  }
}

// ---------------------------------------------------------------------------
// Prefetch count dialog widget
// ---------------------------------------------------------------------------

class _PrefetchCountDialog extends StatefulWidget {
  const _PrefetchCountDialog({required this.model});

  final ComicReaderModel model;

  @override
  State<_PrefetchCountDialog> createState() => _PrefetchCountDialogState();
}

class _PrefetchCountDialogState extends State<_PrefetchCountDialog> {
  late int _count;

  @override
  void initState() {
    super.initState();
    _count = widget.model.prefetchPageCount;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.prefetchPagesTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.prefetchDialogBody(_count)),
          const SizedBox(height: 16),
          Slider(
            value: _count.toDouble(),
            min: ReaderSettingsRepository.minPrefetchPageCount.toDouble(),
            max: ReaderSettingsRepository.maxPrefetchPageCount.toDouble(),
            divisions: ReaderSettingsRepository.maxPrefetchPageCount -
                ReaderSettingsRepository.minPrefetchPageCount,
            label: '$_count',
            onChanged: (value) => setState(() => _count = value.round()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${ReaderSettingsRepository.minPrefetchPageCount}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '${ReaderSettingsRepository.maxPrefetchPageCount}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(
          onPressed: () {
            widget.model.savePrefetchPageCount(_count);
            Navigator.of(context).pop();
          },
          child: Text(l10n.saveButton),
        ),
      ],
    );
  }
}

class _PageDownloadIntervalDialog extends StatefulWidget {
  const _PageDownloadIntervalDialog({required this.initialMilliseconds});

  final int initialMilliseconds;

  @override
  State<_PageDownloadIntervalDialog> createState() =>
      _PageDownloadIntervalDialogState();
}

class _PageDownloadIntervalDialogState
    extends State<_PageDownloadIntervalDialog> {
  static const List<double> _presetSeconds = <double>[0, 0.5, 1.0];

  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: _formatSecondsInput(widget.initialMilliseconds),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.pageDownloadIntervalTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.secondsFieldLabel,
              hintText: '0.5',
              suffixText: l10n.secondsFieldSuffix,
              errorText: _errorText,
            ),
            onSubmitted: (_) => _submit(l10n),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presetSeconds.map((seconds) {
              return ActionChip(
                label: Text(l10n.presetSecondsLabel(_formatPresetSeconds(seconds))),
                onPressed: () => _savePreset(seconds),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.appliesToNewDownloadsNote,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(
          onPressed: () => _submit(l10n),
          child: Text(l10n.applyButton),
        ),
      ],
    );
  }

  void _savePreset(double seconds) {
    final milliseconds = _secondsToMilliseconds(seconds);
    Navigator.of(context).pop(milliseconds);
  }

  void _submit(AppLocalizations l10n) {
    final raw = _controller.text.trim();
    if (raw.isEmpty) {
      setState(() {
        _errorText = l10n.enterNumberErrorMessage;
      });
      return;
    }

    final seconds = double.tryParse(raw);
    if (seconds == null) {
      setState(() {
        _errorText = l10n.onlyNumericErrorMessage;
      });
      return;
    }
    if (seconds < 0) {
      setState(() {
        _errorText = l10n.valueMustBeZeroOrMoreErrorMessage;
      });
      return;
    }

    final milliseconds = _secondsToMilliseconds(seconds);
    final clampedMilliseconds = milliseconds.clamp(
      DownloadSettingsRepository.minPageIntervalMs,
      DownloadSettingsRepository.maxPageIntervalMs,
    );

    if (clampedMilliseconds != milliseconds) {
      _controller.text = _formatSecondsInput(clampedMilliseconds);
      setState(() {
        _errorText = null;
      });
    }

    Navigator.of(context).pop(clampedMilliseconds);
  }
}

class _DownloadSettingsSnapshot {
  const _DownloadSettingsSnapshot({
    required this.autoResumeEnabled,
    required this.pageIntervalMs,
  });

  final bool autoResumeEnabled;
  final int pageIntervalMs;
}

String _formatIntervalSeconds(int milliseconds) {
  return '${(milliseconds / 1000).toStringAsFixed(1)} s';
}

String _formatSecondsInput(int milliseconds) {
  return (milliseconds / 1000).toStringAsFixed(1);
}

String _formatPresetSeconds(double seconds) {
  return seconds.toStringAsFixed(seconds.truncateToDouble() == seconds ? 0 : 1);
}

int _secondsToMilliseconds(double seconds) {
  return (seconds * 1000).round();
}

// ---------------------------------------------------------------------------
// iOS-style grouped section (see .codex/phases/P48-settings-ios-card-redesign.md)
// ---------------------------------------------------------------------------

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(children: _withDividers(children)),
          ),
        ],
      ),
    );
  }

  List<Widget> _withDividers(List<Widget> items) {
    return <Widget>[
      for (int i = 0; i < items.length; i++) ...<Widget>[
        if (i > 0) const Divider(height: 1, indent: 16),
        items[i],
      ],
    ];
  }
}
