import 'package:concept_nhv/application/downloads/download_settings_repository.dart';
import 'package:concept_nhv/application/reader/reader_settings_repository.dart';
import 'package:concept_nhv/models/comic_language.dart';
import 'package:concept_nhv/services/library_import_service.dart';
import 'package:concept_nhv/services/nhentai_auth_service.dart';
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
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: GlassContainer.bar(child: const SizedBox.expand()),
            title: const Text('Settings'),
          ),
          SliverList.list(
            children: <Widget>[
              _SettingsSection(
                title: 'nhentai API',
                children: <Widget>[
                  _buildSessionStatusTile(context),
                  _buildLoginTile(context),
                  _buildSyncFavoritesTile(context),
                  _buildLogoutTile(context),
                ],
              ),
              _SettingsSection(
                title: 'Reader',
                children: <Widget>[
                  _buildPrefetchCountTile(context),
                  _buildClearCacheTile(context),
                ],
              ),
              _SettingsSection(
                title: 'Downloads',
                children: <Widget>[
                  _buildAutoResumeDownloadsTile(context),
                  _buildPageDownloadIntervalTile(context),
                ],
              ),
              _SettingsSection(
                title: 'Blocked Tags',
                children: <Widget>[_buildBlockedTagsSection(context)],
              ),
              _SettingsSection(
                title: 'General',
                children: <Widget>[
                  _buildLanguageTile(context),
                  _buildDiagnoseTile(),
                ],
              ),
              _SettingsSection(
                title: 'About',
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
    return FutureBuilder<_DownloadSettingsSnapshot>(
      future: _downloadSettingsFuture,
      builder: (context, snapshot) {
        final enabled =
            snapshot.data?.autoResumeEnabled ??
            DownloadSettingsRepository.defaultAutoResumeEnabled;
        return SwitchListTile(
          title: const Text('Auto Resume Downloads'),
          subtitle: const Text(
            'Resume interrupted downloads when the app returns to foreground or restarts',
          ),
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
    return FutureBuilder<_DownloadSettingsSnapshot>(
      future: _downloadSettingsFuture,
      builder: (context, snapshot) {
        final pageIntervalMs =
            snapshot.data?.pageIntervalMs ??
            DownloadSettingsRepository.defaultPageIntervalMs;
        return ListTile(
          title: const Text('Page Download Interval'),
          subtitle: Text(
            '${_formatIntervalSeconds(pageIntervalMs)}\nApplies to new downloads or after resume',
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
    final favoriteModel = context.watch<FavoriteSyncModel>();
    final status = favoriteModel.isAuthenticated
        ? 'Authenticated'
        : 'Not configured';
    final syncError = favoriteModel.syncError;

    String subtitle;
    if (favoriteModel.isSyncing) {
      final page = favoriteModel.syncPage;
      final total = favoriteModel.syncTotalPages;
      final retryDeadline = favoriteModel.syncRetryDeadline;
      final progressPart = (page != null && total != null)
          ? 'Syncing... page $page / $total'
          : 'Syncing...';
      if (retryDeadline != null) {
        final secondsLeft = retryDeadline
            .difference(DateTime.now())
            .inSeconds
            .clamp(0, 9999);
        subtitle = '$status\n$progressPart\nRate limited, retrying in ${secondsLeft}s...';
      } else {
        subtitle = '$status\n$progressPart';
      }
    } else if (syncError != null) {
      subtitle = '$status\n$syncError';
    } else {
      final lastSync = favoriteModel.lastSyncAt?.toLocal().toString() ?? 'Never';
      subtitle = '$status\nLast sync: $lastSync';
    }

    return ListTile(
      title: const Text('Status'),
      subtitle: Text(subtitle),
    );
  }

  Widget _buildLoginTile(BuildContext context) {
    return ListTile(
      title: const Text('Set / Update API Key'),
      subtitle: const Text(
        'Paste your personal nhentai API key from account settings',
      ),
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
            const SnackBar(content: Text('API key saved and validated')),
          );
        } on NhentaiAuthException catch (error) {
          messenger.showSnackBar(SnackBar(content: Text(error.message)));
        }
        feedModel.refreshCollections();
      },
    );
  }

  Widget _buildSyncFavoritesTile(BuildContext context) {
    return ListTile(
      title: const Text('Sync Favorites Now'),
      subtitle: const Text('Refresh the local favorite cache from the official API'),
      onTap: () async {
        final favoriteModel = context.read<FavoriteSyncModel>();
        final feedModel = context.read<ComicFeedModel>();
        final ok = await favoriteModel.syncFavorites();
        if (!context.mounted) return;

        feedModel.refreshCollections();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok ? 'Favorites synced from API' : favoriteModel.syncError ?? 'Sync failed',
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogoutTile(BuildContext context) {
    return ListTile(
      title: const Text('Clear API Key'),
      subtitle: const Text('Remove the saved API key from secure storage'),
      onTap: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Clear API key?'),
              content: const Text(
                'This removes the saved API key from secure storage. You will '
                'need to enter it again to sync favorites.',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Clear'),
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
          const SnackBar(content: Text('API key cleared')),
        );
      },
    );
  }

  Future<String?> _promptApiKey(BuildContext context, bool isEditing) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isEditing ? 'Update API Key' : 'Set API Key'),
          content: TextField(
            controller: controller,
            autofocus: true,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'API Key',
              hintText: 'Paste your nhentai API key',
            ),
            onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: const Text('Save'),
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
    final readerModel = context.watch<ComicReaderModel>();
    final count = readerModel.prefetchPageCount;
    return ListTile(
      title: const Text('Pre-fetch Pages'),
      subtitle: Text(
        'Cache $count page(s) before and after the current page (default: '
        '${ReaderSettingsRepository.defaultPrefetchPageCount})',
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
    return ListTile(
      title: const Text('Clear Image Cache'),
      subtitle: const Text('Delete all cached comic images from disk'),
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
          const SnackBar(content: Text('Image cache cleared')),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Blocked Tags tiles
  // ---------------------------------------------------------------------------

  Widget _buildBlockedTagsSection(BuildContext context) {
    final blockedTagsModel = context.watch<BlockedTagsModel>();
    final tags = blockedTagsModel.blockedTags;

    if (tags.isEmpty) {
      return const ListTile(
        dense: true,
        subtitle: Text('No blocked tags. Long-press a tag on a comic to block it.'),
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
            tooltip: 'Remove',
            onPressed: () => blockedTagsModel.removeTag(query),
          ),
        );
      }).toList(growable: false),
    );
  }

  // ---------------------------------------------------------------------------
  // General tiles
  // ---------------------------------------------------------------------------

  Widget _buildLanguageTile(BuildContext context) {
    final feedModel = context.watch<ComicFeedModel>();
    return ListTile(
      title: const Text('Language'),
      subtitle: Text(feedModel.currentLanguage.displayName),
      onTap: () async {
        final messenger = ScaffoldMessenger.of(context);
        final selected = await showDialog<ComicLanguage>(
          context: context,
          builder: (context) {
            return SimpleDialog(
              title: const Text('Language'),
              children: ComicLanguage.values.map((language) {
                return SimpleDialogOption(
                  onPressed: () => Navigator.of(context).pop(language),
                  child: Text(language.displayName),
                );
              }).toList(),
            );
          },
        );

        if (selected == null || !context.mounted) return;

        feedModel.setLanguage(selected);
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(content: Text('Language set to `${selected.displayName}`')),
        );
      },
    );
  }

  Widget _buildDiagnoseTile() {
    return const ListTile(
      title: Text('Diagnose'),
      subtitle: Text('Reserved for future diagnostics'),
    );
  }

  // ---------------------------------------------------------------------------
  // About tiles
  // ---------------------------------------------------------------------------

  Widget _buildImportTile(BuildContext context) {
    return ListTile(
      title: const Text('Load json (network)'),
      onTap: () async {
        final feedModel = context.read<ComicFeedModel>();
        final url = await showDialog<String>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Enter URL'),
              content: TextField(
                autofocus: true,
                decoration: const InputDecoration(labelText: 'URL'),
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
    return ListTile(
      title: const Text('Open Source Licenses'),
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
    return AlertDialog(
      title: const Text('Pre-fetch Pages'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Pre-cache $_count page(s) before and after the current page.',
          ),
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
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            widget.model.savePrefetchPageCount(_count);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
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
    return AlertDialog(
      title: const Text('Page Download Interval'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Seconds',
              hintText: '0.5',
              suffixText: 's',
              errorText: _errorText,
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presetSeconds.map((seconds) {
              return ActionChip(
                label: Text('${_formatPresetSeconds(seconds)} s'),
                onPressed: () => _savePreset(seconds),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 12),
          Text(
            'Applies to new downloads or after resume',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Apply'),
        ),
      ],
    );
  }

  void _savePreset(double seconds) {
    final milliseconds = _secondsToMilliseconds(seconds);
    Navigator.of(context).pop(milliseconds);
  }

  void _submit() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) {
      setState(() {
        _errorText = 'Enter a number in seconds';
      });
      return;
    }

    final seconds = double.tryParse(raw);
    if (seconds == null) {
      setState(() {
        _errorText = 'Only plain numeric seconds are supported';
      });
      return;
    }
    if (seconds < 0) {
      setState(() {
        _errorText = 'Value must be 0 seconds or more';
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
