import 'package:concept_nhv/l10n/app_localizations.dart';
import 'package:concept_nhv/services/backup/backup_connection.dart';
import 'package:concept_nhv/services/backup/backup_client.dart';
import 'package:concept_nhv/services/backup/device_name_service.dart';
import 'package:concept_nhv/state/backup_control_model.dart';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _loadSuggestedDeviceName();
  }

  Future<void> _loadSuggestedDeviceName() async {
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
    final fieldsEnabled =
        !model.isConnected && model.state != BackupControlState.connecting;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.backupScreenTitle)),
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
    try {
      await context.read<BackupControlModel>().connect(
        BackupConnection(baseUri: baseUri, pin: pin, deviceId: deviceId),
      );
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
    final label = switch (model.state) {
      BackupControlState.disconnected => l10n.backupControlDisconnected,
      BackupControlState.connecting => l10n.backupStageConnecting,
      BackupControlState.idle => l10n.backupControlReady,
      BackupControlState.running => l10n.backupControlRunning,
      BackupControlState.pausing => l10n.backupControlPausing,
      BackupControlState.paused => l10n.backupControlPaused,
      BackupControlState.completed => l10n.backupControlCompleted,
      BackupControlState.error => l10n.backupControlError,
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
