import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../models/backup_models.dart';
import '../state/server_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.model});

  final ServerModel model;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PruneCandidates? _shownPrune;

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_onModelChanged);
  }

  @override
  void dispose() {
    widget.model.removeListener(_onModelChanged);
    super.dispose();
  }

  void _onModelChanged() {
    final pending = widget.model.pendingPrune;
    if (pending != null && pending != _shownPrune) {
      _shownPrune = pending;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _confirmPrune(pending);
        }
      });
    } else if (pending == null) {
      _shownPrune = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comicdex Backup Server'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Refresh devices',
            onPressed: widget.model.refreshDevices,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.model,
        builder: (context, _) {
          final model = widget.model;
          if (model.isStarting) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              _ConnectionCard(model: model),
              const SizedBox(height: 12),
              _BackupFolderCard(
                model: model,
                onChangeFolder: _pickFolder,
              ),
              const SizedBox(height: 12),
              _DevicesCard(model: model),
              const SizedBox(height: 12),
              _ActivityCard(model: model),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickFolder() async {
    final selected = await getDirectoryPath(
      confirmButtonText: 'Use this folder',
    );
    if (selected == null || !mounted) {
      return;
    }
    await widget.model.changeRootDirectory(selected);
  }

  Future<void> _confirmPrune(PruneCandidates candidates) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete files the phone no longer has?'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${candidates.deviceId} asked to clean up '
                  '${candidates.entries.length} file(s), freeing '
                  '${_formatBytes(candidates.totalBytes)}.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'These exist in the backup but not on the phone. Deleting is '
                  'permanent — if they were removed from the phone by mistake, '
                  'keeping them here is the only remaining copy.',
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: Scrollbar(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: candidates.entries.length,
                      itemBuilder: (context, index) {
                        return Text(
                          candidates.entries[index].path,
                          style: Theme.of(context).textTheme.bodySmall,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Keep everything'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }
    if (confirmed == true) {
      final deleted = await widget.model.confirmPrune();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted $deleted file(s)')),
        );
      }
    } else {
      widget.model.dismissPrune();
    }
  }
}

// ---------------------------------------------------------------------------

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({required this.model});

  final ServerModel model;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Connect from your phone', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            if (!model.isRunning)
              Text(
                'Server is not running.',
                style: TextStyle(color: theme.colorScheme.error),
              )
            else ...<Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Address', style: theme.textTheme.labelMedium),
                        const SizedBox(height: 4),
                        if (model.addresses.isEmpty)
                          const Text('No network connection found')
                        else
                          // Every adapter is listed rather than guessed: dev
                          // machines usually also have WSL/VirtualBox adapters
                          // the phone cannot reach.
                          ...model.addresses.map(
                            (address) => Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: SelectableText(
                                '${address.address}:${model.port}'
                                '   (${address.interfaceName})',
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text('Pairing PIN', style: theme.textTheme.labelMedium),
                      const SizedBox(height: 4),
                      SelectableText(
                        model.pin,
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                          letterSpacing: 4,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: model.regeneratePin,
                        icon: const Icon(Icons.autorenew, size: 16),
                        label: const Text('New PIN'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'The PIN changes every time this app restarts.',
                style: theme.textTheme.bodySmall,
              ),
              if (!model.hasServedAnyone) ...<Widget>[
                const SizedBox(height: 12),
                _InfoBanner(
                  icon: Icons.shield_outlined,
                  color: theme.colorScheme.tertiary,
                  message:
                      'No device has connected yet. If your phone cannot reach '
                      'this machine, check that Windows Firewall is allowing '
                      'this app on private networks — that prompt is the most '
                      'common cause, and it looks the same as a wrong address.',
                ),
              ],
              if (model.lockedOutAddresses.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _InfoBanner(
                  icon: Icons.lock_outline,
                  color: theme.colorScheme.error,
                  message:
                      'Temporarily blocked after repeated wrong PINs: '
                      '${model.lockedOutAddresses.join(', ')}',
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _BackupFolderCard extends StatelessWidget {
  const _BackupFolderCard({required this.model, required this.onChangeFolder});

  final ServerModel model;
  final Future<void> Function() onChangeFolder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final missing = !model.rootExists;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Backup folder', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      SelectableText(
                        model.rootPath.isEmpty ? '(not set)' : model.rootPath,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => onChangeFolder(),
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Change'),
                ),
              ],
            ),
            if (missing) ...<Widget>[
              const SizedBox(height: 12),
              _InfoBanner(
                icon: Icons.error_outline,
                color: theme.colorScheme.error,
                message:
                    'This folder is not available right now (an external drive '
                    'may be disconnected). Backups are refused until it is back '
                    'so the phone never mistakes an empty mirror for "nothing '
                    'backed up yet" and re-uploads everything.',
              ),
            ],
            if (model.startupError != null) ...<Widget>[
              const SizedBox(height: 12),
              _InfoBanner(
                icon: Icons.warning_amber_outlined,
                color: theme.colorScheme.error,
                message: model.startupError!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DevicesCard extends StatelessWidget {
  const _DevicesCard({required this.model});

  final ServerModel model;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Backed up devices', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (model.devices.isEmpty)
              const Text('Nothing backed up yet.')
            else
              ...model.devices.map(
                (device) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.smartphone),
                  title: Text(device.deviceId),
                  subtitle: Text(
                    '${device.fileCount} files · '
                    '${_formatBytes(device.totalBytes)} · '
                    '${device.dbSnapshotCount} database snapshot(s)'
                    '${device.lastSyncAt == null ? '' : ' · last sync '
                        '${_formatTimestamp(device.lastSyncAt!)}'}',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.model});

  final ServerModel model;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Activity', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (model.activity.isEmpty)
              const Text('Waiting for a device to connect…')
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: Scrollbar(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: model.activity.length,
                    itemBuilder: (context, index) {
                      return Text(
                        model.activity[index],
                        style: theme.textTheme.bodySmall,
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.color,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

String _formatBytes(int bytes) {
  const units = <String>['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return '${value.toStringAsFixed(unit == 0 ? 0 : 1)} ${units[unit]}';
}

String _formatTimestamp(DateTime value) {
  final local = value.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}
