import 'package:concept_nhv/l10n/app_localizations.dart';
import 'package:concept_nhv/services/backup/restore_progress_flag.dart';
import 'package:flutter/material.dart';

/// Surfaces an unfinished restore the moment the app opens.
///
/// The flag is set while a restore is deleting and re-fetching files, and only
/// cleared once the new database is staged. If the app is killed in between, it
/// boots the *old* database while parts of the library it lists are already
/// gone — the Downloads tab fills with entries that will not open, which reads
/// as a broken app rather than an unfinished job.
///
/// Deliberately shown here rather than on the Backup screen: someone who does
/// not know a restore was interrupted has no reason to go looking there, and
/// that is exactly the person who needs telling.
class InterruptedRestoreGate extends StatefulWidget {
  const InterruptedRestoreGate({
    super.key,
    required this.readInterrupted,
    required this.onAcknowledged,
    required this.child,
    this.dialogContext,
  });

  /// Where to show the dialog, when this widget sits above the Navigator.
  ///
  /// `MaterialApp.router`'s `builder` wraps the navigator, so this widget's own
  /// context has no Navigator ancestor and `showDialog` would throw — inside an
  /// async callback, where the failure is swallowed and the warning simply never
  /// appears. Supplying the router's navigator key avoids that.
  final BuildContext? Function()? dialogContext;

  /// Built from a [RestoreProgressFlag] in the app; supplied directly in tests.
  ///
  /// Kept as plain callbacks rather than the flag itself so widget tests never
  /// touch the filesystem — real `dart:io` inside `testWidgets`' fake-async zone
  /// makes `pumpAndSettle` wait forever, which this project has been bitten by
  /// before.
  final Future<InterruptedRestore?> Function() readInterrupted;
  final Future<void> Function() onAcknowledged;
  final Widget child;

  /// Wires the gate to the on-disk flag.
  factory InterruptedRestoreGate.fromFlag({
    Key? key,
    required RestoreProgressFlag flag,
    required Widget child,
    BuildContext? Function()? dialogContext,
  }) {
    return InterruptedRestoreGate(
      key: key,
      readInterrupted: flag.read,
      onAcknowledged: flag.clear,
      dialogContext: dialogContext,
      child: child,
    );
  }

  @override
  State<InterruptedRestoreGate> createState() => _InterruptedRestoreGateState();
}

class _InterruptedRestoreGateState extends State<InterruptedRestoreGate> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    if (_checked) {
      return;
    }
    _checked = true;
    final interrupted = await widget.readInterrupted();
    if (interrupted == null || !mounted) {
      return;
    }
    await _showPrompt(interrupted);
  }

  Future<void> _showPrompt(InterruptedRestore interrupted) async {
    final host = widget.dialogContext?.call() ?? context;
    final l10n = AppLocalizations.of(host)!;
    final dismissed = await showDialog<bool>(
      context: host,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.warning_amber_outlined),
          title: Text(l10n.restoreInterruptedTitle),
          content: Text(
            l10n.restoreInterruptedBody(interrupted.sourceDeviceId),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.restoreInterruptedDismiss),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.restoreInterruptedAcknowledge),
            ),
          ],
        );
      },
    );

    // Only clearing on the explicit acknowledgement: dismissing keeps the
    // warning for the next launch, because the inconsistency itself has not
    // gone away just because the dialog was closed.
    if (dismissed == true) {
      await widget.onAcknowledged();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
