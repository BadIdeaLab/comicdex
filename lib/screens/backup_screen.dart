import 'dart:io';

import 'package:concept_nhv/l10n/app_localizations.dart';
import 'package:concept_nhv/services/backup/backup_connection.dart';
import 'package:concept_nhv/services/backup/backup_client.dart';
import 'package:concept_nhv/services/backup/device_name_service.dart';
import 'package:concept_nhv/services/backup/pairing_memory.dart';
import 'package:concept_nhv/state/backup_control_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _deviceNameController = TextEditingController();
  String? _validationError;
  bool _restartPromptShown = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestedDeviceName();
  }

  /// Blocks until the user relaunches, because carrying on now is misleading:
  /// every change they make will be discarded by the pending database.
  ///
  /// Android can close itself; iOS cannot be terminated programmatically in any
  /// supported way, so there it can only instruct. Both end up in the same
  /// place — the swap happens on the next launch either way.
  Future<void> _showRestartRequired() async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            icon: const Icon(Icons.restart_alt),
            title: Text(l10n.restoreDoneTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(l10n.restoreDoneBody),
                const SizedBox(height: 12),
                Text(
                  l10n.restoreDoneManualHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            actions: <Widget>[
              if (!Platform.isIOS)
                FilledButton.icon(
                  onPressed: () => SystemNavigator.pop(),
                  icon: const Icon(Icons.close),
                  label: Text(l10n.restoreDoneCloseApp),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Prefills from the last successful pairing, falling back to the device's
  /// own model name. The PIN is never restored — see [PairingMemory].
  Future<void> _loadSuggestedDeviceName() async {
    final remembered = await context.read<PairingMemory>().read();
    if (mounted && remembered != null) {
      if (_addressController.text.trim().isEmpty) {
        _addressController.text = remembered.address;
      }
      if (_deviceNameController.text.trim().isEmpty &&
          remembered.deviceName.isNotEmpty) {
        _deviceNameController.text = remembered.deviceName;
      }
    }
    if (!mounted || _deviceNameController.text.trim().isNotEmpty) {
      return;
    }
    final service = context.read<DeviceNameService>();
    final name = await service.suggestedName();
    if (mounted && _deviceNameController.text.trim().isEmpty) {
      _deviceNameController.text = name;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _pinController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final model = context.watch<BackupControlModel>();
    // A finished restore has staged a database that only takes effect on the
    // next launch; until then the screen is showing the old library over the
    // new files, so this must interrupt rather than sit in a status line.
    if (model.restoreAwaitingRestart && !_restartPromptShown) {
      _restartPromptShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showRestartRequired();
        }
      });
    }
    final fieldsEnabled =
        !model.isConnected && model.state != BackupControlState.connecting;
    // Leaving mid-restore is not merely untidy: the restore is deleting and
    // re-fetching files while the *old* database is still the one on screen, so
    // the library the user would walk back into lists comics whose files are
    // in flux. Local-first opening (P66) makes them likelier to hit exactly
    // those files. Backups are read-only on this device and stay escapable.
    final restoreInProgress = model.isRestoreInProgress;
    // No explanation on refusal: the screen itself is showing the restore
    // running, so a message would only repeat what is already on it.
    return PopScope(
      canPop: !restoreInProgress,
      child: _buildScaffold(
        context,
        l10n,
        model,
        fieldsEnabled,
        restoreInProgress,
      ),
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    AppLocalizations l10n,
    BackupControlModel model,
    bool fieldsEnabled,
    bool restoreInProgress,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.backupScreenTitle),
        // A back button that silently does nothing is worse than no back
        // button; PopScope already refuses the pop, so remove the affordance.
        automaticallyImplyLeading: !restoreInProgress,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          TextField(
            controller: _addressController,
            enabled: fieldsEnabled,
            decoration: InputDecoration(
              labelText: l10n.backupAddressLabel,
              hintText: l10n.backupAddressHint,
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
            autocorrect: false,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pinController,
            enabled: fieldsEnabled,
            decoration: InputDecoration(
              labelText: l10n.backupPinLabel,
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _deviceNameController,
            enabled: fieldsEnabled,
            decoration: InputDecoration(
              labelText: l10n.backupDeviceNameLabel,
              helperText: l10n.backupDeviceNameHelp,
              helperMaxLines: 3,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          if (model.isConnected)
            OutlinedButton.icon(
              onPressed:
                  model.state == BackupControlState.running ||
                      model.state == BackupControlState.pausing
                  ? null
                  : model.disconnect,
              icon: const Icon(Icons.link_off),
              label: Text(l10n.backupDisconnectButton),
            )
          else
            FilledButton.icon(
              onPressed: model.state == BackupControlState.connecting
                  ? null
                  : _connect,
              icon: const Icon(Icons.link),
              label: Text(l10n.backupConnectButton),
            ),
          const SizedBox(height: 16),
          _StatusCard(model: model),
          if (_validationError != null) ...<Widget>[
            const SizedBox(height: 12),
            _ErrorBanner(message: _validationError!),
          ],
          if (model.error != null && _validationError == null) ...<Widget>[
            const SizedBox(height: 12),
            _ErrorBanner(message: l10n.backupErrorGeneric(model.error!)),
          ],
          const SizedBox(height: 16),
          Text(
            l10n.backupDesktopControlsNote,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.backupKeepForegroundNote,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.backupApiKeyNote,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Future<void> _connect() async {
    final l10n = AppLocalizations.of(context)!;
    final pin = _pinController.text.trim();
    final deviceId = _deviceNameController.text.trim();
    final rawAddress = _addressController.text.trim();
    if (pin.isEmpty || deviceId.isEmpty || rawAddress.isEmpty) {
      setState(() => _validationError = l10n.backupErrorMissingFields);
      return;
    }
    final baseUri = BackupConnection.parseAddress(rawAddress);
    if (baseUri == null) {
      setState(() => _validationError = l10n.backupErrorInvalidAddress);
      return;
    }
    setState(() => _validationError = null);
    final pairingMemory = context.read<PairingMemory>();
    try {
      await context.read<BackupControlModel>().connect(
        BackupConnection(baseUri: baseUri, pin: pin, deviceId: deviceId),
      );
      // Saved only on success, so a mistyped address is never what gets offered
      // next time. The PIN is deliberately excluded.
      await pairingMemory.remember(address: rawAddress, deviceName: deviceId);
    } on BackupServerException catch (error) {
      setState(() {
        _validationError = error.isUnauthorized
            ? l10n.backupErrorWrongPin
            : error.isLockedOut
            ? l10n.backupErrorLockedOut
            : l10n.backupErrorGeneric(error.message);
      });
    } on BackupPairingRejectedException {
      setState(() => _validationError = l10n.backupErrorPairingRejected);
    } on Object {
      setState(() => _validationError = l10n.backupErrorUnreachable);
    }
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.model});

  final BackupControlModel model;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final progress = model.progress;
    final fraction = progress?.fraction;
    final restoring = model.lastJobWasRestore;
    final label = switch (model.state) {
      BackupControlState.disconnected => l10n.backupControlDisconnected,
      BackupControlState.connecting => l10n.backupStageConnecting,
      BackupControlState.idle => l10n.backupControlReady,
      // Backup and restore share one state machine, so every label has to look
      // at the job kind — otherwise a restore in progress reports itself as a
      // backup, which is alarming when the user knows files are being deleted.
      BackupControlState.running => restoring
          ? l10n.backupControlRestoreRunning
          : l10n.backupControlRunning,
      BackupControlState.pausing => l10n.backupControlPausing,
      BackupControlState.paused => restoring
          ? l10n.backupControlRestorePaused
          : l10n.backupControlPaused,
      BackupControlState.completed => restoring
          ? l10n.backupControlRestoreDone
          : l10n.backupControlCompleted,
      BackupControlState.error => restoring
          ? l10n.backupControlRestoreError
          : l10n.backupControlError,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(model.isConnected ? Icons.link : Icons.link_off, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(label)),
              ],
            ),
            if (model.state == BackupControlState.running ||
                model.state == BackupControlState.pausing) ...<Widget>[
              const SizedBox(height: 10),
              LinearProgressIndicator(value: fraction),
              if (progress?.currentPath != null) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  progress!.currentPath!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.error_outline, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
