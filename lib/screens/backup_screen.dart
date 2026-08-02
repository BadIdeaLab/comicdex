import 'package:concept_nhv/l10n/app_localizations.dart';
import 'package:concept_nhv/services/backup/backup_client.dart';
import 'package:concept_nhv/services/backup/backup_connection.dart';
import 'package:concept_nhv/services/backup/backup_models.dart';
import 'package:concept_nhv/services/backup/backup_sync_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _deviceNameController = TextEditingController();

  BackupSyncProgress? _progress;
  BackupSyncResult? _result;
  String? _error;
  bool _isRunning = false;

  @override
  void dispose() {
    _addressController.dispose();
    _pinController.dispose();
    _deviceNameController.dispose();
    // Belt and braces: if the screen is torn down mid-run the lock must not
    // outlive it and hold the display on.
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.backupScreenTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          TextField(
            controller: _addressController,
            enabled: !_isRunning,
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
            enabled: !_isRunning,
            decoration: InputDecoration(
              labelText: l10n.backupPinLabel,
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _deviceNameController,
            enabled: !_isRunning,
            decoration: InputDecoration(
              labelText: l10n.backupDeviceNameLabel,
              helperText: l10n.backupDeviceNameHelp,
              helperMaxLines: 3,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _isRunning ? null : _startBackup,
            icon: const Icon(Icons.backup),
            label: Text(l10n.backupStartButton),
          ),
          const SizedBox(height: 16),
          if (_isRunning) _buildProgress(context, l10n),
          if (_error != null) _buildBanner(context, _error!, isError: true),
          if (_result != null) _buildSummary(context, l10n, _result!),
          const SizedBox(height: 16),
          Text(
            l10n.backupApiKeyNote,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.backupKeepForegroundNote,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildProgress(BuildContext context, AppLocalizations l10n) {
    final progress = _progress;
    final label = switch (progress?.stage) {
      BackupSyncStage.snapshottingDatabase => l10n.backupStageSnapshot,
      BackupSyncStage.comparing => l10n.backupStageComparing,
      BackupSyncStage.uploading || BackupSyncStage.done => l10n
          .backupStageUploading(
            progress!.uploadedFiles,
            progress.totalFiles,
          ),
      _ => l10n.backupStageConnecting,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // A real fraction, not an indeterminate spinner: the work list is known
        // before any file is sent.
        LinearProgressIndicator(value: progress?.fraction),
        const SizedBox(height: 8),
        Text(label),
        if (progress?.currentPath != null) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            progress!.currentPath!,
            style: Theme.of(context).textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildSummary(
    BuildContext context,
    AppLocalizations l10n,
    BackupSyncResult result,
  ) {
    final lines = <String>[
      l10n.backupSummaryUploaded(result.uploadedCount),
      if (result.skippedCount > 0)
        l10n.backupSummarySkipped(result.skippedCount),
      if (result.skippedInFlightCount > 0)
        l10n.backupSummaryInFlight(result.skippedInFlightCount),
      if (result.failedCount > 0) l10n.backupSummaryFailed(result.failedCount),
    ];
    return _buildBanner(
      context,
      lines.join('\n'),
      isError: result.hasFailures,
    );
  }

  Widget _buildBanner(
    BuildContext context,
    String message, {
    required bool isError,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final color = isError ? scheme.error : scheme.primary;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }

  Future<void> _startBackup() async {
    final l10n = AppLocalizations.of(context)!;
    final pin = _pinController.text.trim();
    final deviceId = _deviceNameController.text.trim();
    if (pin.isEmpty || deviceId.isEmpty || _addressController.text.trim().isEmpty) {
      setState(() {
        _error = l10n.backupErrorMissingFields;
        _result = null;
      });
      return;
    }
    final baseUri = BackupConnection.parseAddress(_addressController.text);
    if (baseUri == null) {
      setState(() {
        _error = l10n.backupErrorInvalidAddress;
        _result = null;
      });
      return;
    }

    // Resolved before the first await so the context is not used across a gap.
    final service = context.read<BackupSyncService>();

    setState(() {
      _isRunning = true;
      _error = null;
      _result = null;
      _progress = const BackupSyncProgress(stage: BackupSyncStage.connecting);
    });
    // Transfers can run for many minutes; without this the screen locks, the
    // OS suspends the app, and the transfer dies partway through.
    await WakelockPlus.enable();

    try {
      final result = await service.run(
        connection: BackupConnection(
          baseUri: baseUri,
          pin: pin,
          deviceId: deviceId,
        ),
        onProgress: (progress) {
          if (mounted) {
            setState(() => _progress = progress);
          }
        },
      );
      if (mounted) {
        setState(() => _result = result);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = _describeError(l10n, error));
      }
    } finally {
      await WakelockPlus.disable();
      if (mounted) {
        setState(() => _isRunning = false);
      }
    }
  }

  /// Turns failures into advice. A wrong PIN and an unreachable machine both
  /// present as "it didn't work", but need completely different next steps.
  String _describeError(AppLocalizations l10n, Object error) {
    if (error is BackupServerException) {
      if (error.isUnauthorized) {
        return l10n.backupErrorWrongPin;
      }
      if (error.isLockedOut) {
        return l10n.backupErrorLockedOut;
      }
      return l10n.backupErrorGeneric(error.message);
    }
    return l10n.backupErrorUnreachable;
  }
}
