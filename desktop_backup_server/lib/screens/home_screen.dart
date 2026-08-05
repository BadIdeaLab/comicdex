import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../models/activity_event.dart';
import '../models/backup_models.dart';
import '../models/mobile_control.dart';
import '../state/app_locale_model.dart';
import '../state/server_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.model, required this.localeModel});

  final ServerModel model;
  final AppLocaleModel localeModel;

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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: <Widget>[
          _LanguageMenu(localeModel: widget.localeModel),
          IconButton(
            tooltip: l10n.refreshDevices,
            onPressed: widget.model.refreshAll,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
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
              _BackupFolderCard(model: model, onChangeFolder: _pickFolder),
              const SizedBox(height: 12),
              _ConnectedDevicesCard(model: model),
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
    final l10n = AppLocalizations.of(context)!;
    final selected = await getDirectoryPath(
      confirmButtonText: l10n.folderPickConfirm,
    );
    if (selected == null || !mounted) {
      return;
    }
    await widget.model.changeRootDirectory(selected);
  }

  Future<void> _confirmPrune(PruneCandidates candidates) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.pruneTitle),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.pruneSummary(
                    candidates.deviceId,
                    candidates.entries.length,
                    formatBytes(candidates.totalBytes),
                  ),
                ),
                const SizedBox(height: 12),
                Text(l10n.pruneExplanation),
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
              child: Text(l10n.pruneKeep),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.pruneDelete),
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
          SnackBar(content: Text(l10n.pruneDeletedToast(deleted))),
        );
      }
    } else {
      widget.model.dismissPrune();
    }
  }
}

// ---------------------------------------------------------------------------

class _LanguageMenu extends StatelessWidget {
  const _LanguageMenu({required this.localeModel});

  final AppLocaleModel localeModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: localeModel,
      builder: (context, _) {
        return PopupMenuButton<String>(
          tooltip: l10n.languageLabel,
          icon: const Icon(Icons.translate),
          initialValue: localeModel.option,
          onSelected: localeModel.setOption,
          itemBuilder: (context) {
            return <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: AppLocaleModel.systemOption,
                child: Text(l10n.languageSystem),
              ),
              PopupMenuItem<String>(
                value: 'en',
                child: Text(l10n.languageEnglish),
              ),
              PopupMenuItem<String>(
                value: 'zh_Hant',
                child: Text(l10n.languageTraditionalChinese),
              ),
            ];
          },
        );
      },
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({required this.model});

  final ServerModel model;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(l10n.connectTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            if (!model.isRunning)
              Text(
                l10n.connectServerStopped,
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
                        Text(
                          l10n.connectAddressLabel,
                          style: theme.textTheme.labelMedium,
                        ),
                        const SizedBox(height: 4),
                        if (model.addresses.isEmpty)
                          Text(l10n.connectNoNetwork)
                        else
                          // Sorted so physical adapters come first: a machine
                          // with WSL installed otherwise leads with an address
                          // the phone can never reach, and that timeout is
                          // indistinguishable from a firewall block.
                          ...model.addresses.map(
                            (address) => _AddressRow(
                              address: '${address.address}:${model.port}',
                              interfaceName: address.interfaceName,
                              isLikelyVirtual: address.isLikelyVirtual,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        l10n.connectPinLabel,
                        style: theme.textTheme.labelMedium,
                      ),
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
                        label: Text(l10n.connectNewPin),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l10n.connectPinChangesNote,
                style: theme.textTheme.bodySmall,
              ),
              if (!model.hasServedAnyone) ...<Widget>[
                const SizedBox(height: 12),
                _InfoBanner(
                  icon: Icons.shield_outlined,
                  color: theme.colorScheme.tertiary,
                  message: l10n.firewallHint,
                ),
              ],
              if (model.lockedOutAddresses.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _InfoBanner(
                  icon: Icons.lock_outline,
                  color: theme.colorScheme.error,
                  message: l10n.lockedOutHint(
                    model.lockedOutAddresses.join(', '),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({
    required this.address,
    required this.interfaceName,
    required this.isLikelyVirtual,
  });

  final String address;
  final String interfaceName;
  final bool isLikelyVirtual;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final muted = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: <Widget>[
          SelectableText(
            address,
            style: theme.textTheme.titleMedium?.copyWith(
              color: isLikelyVirtual ? muted : null,
              fontWeight: isLikelyVirtual ? FontWeight.normal : FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              isLikelyVirtual
                  ? '($interfaceName — ${l10n.connectVirtualAdapterTag})'
                  : '($interfaceName)',
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: l10n.connectCopyAddress,
            iconSize: 16,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.copy),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: address));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.connectAddressCopied(address))),
                );
              }
            },
          ),
        ],
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
    final l10n = AppLocalizations.of(context)!;
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
                      Text(
                        l10n.folderTitle,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        model.rootPath.isEmpty
                            ? l10n.folderNotSet
                            : model.rootPath,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => onChangeFolder(),
                  icon: const Icon(Icons.folder_open),
                  label: Text(l10n.folderChange),
                ),
              ],
            ),
            if (missing) ...<Widget>[
              const SizedBox(height: 12),
              _InfoBanner(
                icon: Icons.error_outline,
                color: theme.colorScheme.error,
                message: l10n.folderMissingWarning,
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
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(l10n.devicesTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (model.devices.isEmpty)
              Text(l10n.devicesEmpty)
            else
              ...model.devices.map((device) {
                final summary = l10n.devicesSubtitle(
                  device.fileCount,
                  formatBytes(device.totalBytes),
                  device.dbSnapshotCount,
                );
                final lastSync = device.lastSyncAt;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.smartphone),
                  title: Text(device.deviceId),
                  subtitle: Text(
                    lastSync == null
                        ? summary
                        : '$summary · '
                              '${l10n.devicesLastSync(_formatTimestamp(lastSync))}',
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

/// Asks which backup to restore from, then confirms.
///
/// Two deliberate choices here. The source is picked on the desktop because
/// that is where the list of backed-up devices lives, and because a replacement
/// phone must be able to name a partition that is not its own. And the warning
/// is spelled out rather than summarised: this deletes files on the phone and
/// replaces its database, which is not recoverable by undoing anything.
Future<void> _confirmRestore(
  BuildContext context,
  ServerModel model,
  ConnectedMobileDevice device,
) async {
  final l10n = AppLocalizations.of(context)!;
  final sources = model.devices;
  if (sources.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.restoreDialogNoBackups)));
    return;
  }

  // Defaults to the device's own backup when it has one, since restoring a
  // phone onto itself is the common case.
  var selected = sources
      .firstWhere(
        (candidate) => candidate.deviceId == device.deviceId,
        orElse: () => sources.first,
      )
      .deviceId;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            icon: const Icon(Icons.restore),
            title: Text(l10n.restoreDialogTitle(device.deviceId)),
            content: SizedBox(
              width: 460,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(l10n.restoreDialogChooseSource),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: Scrollbar(
                      child: RadioGroup<String>(
                        groupValue: selected,
                        onChanged: (value) => setState(() => selected = value!),
                        child: ListView(
                        shrinkWrap: true,
                        children: sources.map((source) {
                          return RadioListTile<String>(
                            value: source.deviceId,
                            title: Text(source.deviceId),
                            subtitle: Text(
                              '${source.fileCount} · '
                              '${formatBytes(source.totalBytes)}'
                              '${source.lastSyncAt == null ? '' : ' · '
                                  '${_formatTimestamp(source.lastSyncAt!)}'}',
                            ),
                          );
                        }).toList(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.restoreDialogWarning,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.restoreCancel),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.restoreConfirm),
              ),
            ],
          );
        },
      );
    },
  );

  if (confirmed != true || !context.mounted) {
    return;
  }
  model.startRestore(deviceId: device.deviceId, sourceDeviceId: selected);
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.restoreStarted(device.deviceId))),
    );
  }
}

class _ConnectedDevicesCard extends StatelessWidget {
  const _ConnectedDevicesCard({required this.model});

  final ServerModel model;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(l10n.controlTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (model.connectedDevices.isEmpty)
              Text(l10n.controlEmpty)
            else
              ...model.connectedDevices.map((device) {
                final progress = device.totalFiles == 0
                    ? null
                    : device.uploadedFiles / device.totalFiles;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.phonelink_ring),
                  title: Text(device.deviceId),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(_controlStateLabel(l10n, device.state)),
                      if (progress != null) ...<Widget>[
                        const SizedBox(height: 4),
                        LinearProgressIndicator(value: progress.clamp(0, 1)),
                      ],
                      if (device.currentPath != null)
                        Text(
                          device.currentPath!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      if (device.message != null)
                        Text(
                          device.message!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: device.state == MobileJobState.error
                                ? theme.colorScheme.error
                                : null,
                          ),
                        ),
                    ],
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: <Widget>[
                      FilledButton.icon(
                        onPressed: device.canStart
                            ? () => model.startBackup(device.deviceId)
                            : null,
                        icon: const Icon(Icons.backup),
                        label: Text(l10n.controlStartBackup),
                      ),
                      OutlinedButton.icon(
                        // Same "not while a job is running" rule as backup: the
                        // two must never overlap, or a backup would push the
                        // half-restored library back over the mirror.
                        onPressed: device.canStart
                            ? () => _confirmRestore(context, model, device)
                            : null,
                        icon: const Icon(Icons.restore),
                        label: Text(l10n.controlRestore),
                      ),
                      OutlinedButton.icon(
                        onPressed: device.canPause
                            ? () => model.pauseBackup(device.deviceId)
                            : null,
                        icon: const Icon(Icons.pause),
                        label: Text(l10n.controlPause),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

String _controlStateLabel(AppLocalizations l10n, MobileJobState state) {
  return switch (state) {
    MobileJobState.idle => l10n.controlStateIdle,
    MobileJobState.running => l10n.controlStateRunning,
    MobileJobState.pausing => l10n.controlStatePausing,
    MobileJobState.paused => l10n.controlStatePaused,
    MobileJobState.completed => l10n.controlStateCompleted,
    MobileJobState.error => l10n.controlStateError,
  };
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.model});

  final ServerModel model;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(l10n.activityTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (model.activity.isEmpty)
              Text(l10n.activityEmpty)
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: Scrollbar(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: model.activity.length,
                    itemBuilder: (context, index) {
                      final event = model.activity[index];
                      return Text(
                        '${_formatClock(event.at)}  '
                        '${describeActivity(l10n, event)}',
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
            child: Text(message, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

/// Renders an [ActivityEvent] in the current language. Kept next to the widget
/// that shows it so adding an event type surfaces here as a compile error.
String describeActivity(AppLocalizations l10n, ActivityEvent event) {
  return switch (event) {
    FileReceivedEvent() => l10n.activityReceivedFile(
      event.path,
      event.deviceId,
    ),
    FileSentEvent() => l10n.activitySentFile(event.path, event.deviceId),
    DatabaseStoredEvent() => l10n.activityStoredDatabase(event.deviceId),
    DatabaseSentEvent() => l10n.activitySentDatabase(event.deviceId),
    PinBlockedEvent() => l10n.activityBlockedPin(event.address),
    PruneRequestedEvent() => l10n.activityPruneRequested(
      event.deviceId,
      event.count,
    ),
    StaleFilesDeletedEvent() => l10n.activityDeletedStaleFiles(
      event.count,
      event.deviceId,
    ),
    BackupFolderChangedEvent() => l10n.activityFolderChanged(event.path),
    PinRegeneratedEvent() => l10n.activityPinRegenerated,
    PartFilesCleanedEvent() => l10n.activityCleanedPartFiles(event.count),
  };
}

String formatBytes(int bytes) {
  const units = <String>['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return '${value.toStringAsFixed(unit == 0 ? 0 : 1)} ${units[unit]}';
}

String _formatClock(DateTime value) {
  final local = value.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
}

String _formatTimestamp(DateTime value) {
  final local = value.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}
