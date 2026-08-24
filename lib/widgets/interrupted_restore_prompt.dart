import 'package:concept_nhv/l10n/app_localizations.dart';
import 'package:concept_nhv/services/backup/restore_progress_flag.dart';
import 'package:flutter/material.dart';

/// Warns about a restore that never finished, before the app moves on.
///
/// The flag is set while a restore is deleting and re-fetching files, and only
/// cleared once the new database is staged. If the app is killed in between, it
/// boots the *old* database while parts of the library it lists are already
/// gone — the Downloads tab fills with entries that will not open, which reads
/// as a broken app rather than an unfinished job.
///
/// **Awaited from the bootstrap sequence, on purpose.** This used to be a
/// widget wrapped around the router, which raced with `BootstrapScreen`'s
/// `context.go('/index')`: `go()` replaces the whole route stack, and a dialog
/// route on that navigator went with it. The flag read (a local file) always
/// won that race against the home feed (a network call), so the warning
/// appeared and was wiped a moment later — visible, but impossible to act on,
/// and the flag stayed set because nothing was ever acknowledged. Making the
/// caller await this before navigating removes the race rather than retiming
/// it.
///
/// [readInterrupted] and [onAcknowledged] are plain callbacks rather than the
/// flag itself so widget tests never touch the filesystem — real `dart:io`
/// inside `testWidgets`' fake-async zone makes `pumpAndSettle` wait forever,
/// which this project has been bitten by before.
Future<void> showInterruptedRestorePrompt(
  BuildContext context, {
  required Future<InterruptedRestore?> Function() readInterrupted,
  required Future<void> Function() onAcknowledged,
}) async {
  final interrupted = await readInterrupted();
  if (interrupted == null || !context.mounted) {
    return;
  }

  final l10n = AppLocalizations.of(context)!;
  final acknowledged = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        icon: const Icon(Icons.warning_amber_outlined),
        title: Text(l10n.restoreInterruptedTitle),
        content: Text(l10n.restoreInterruptedBody(interrupted.sourceDeviceId)),
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

  // Only clearing on the explicit acknowledgement: dismissing keeps the warning
  // for the next launch, because the inconsistency itself has not gone away
  // just because the dialog was closed.
  if (acknowledged == true) {
    await onAcknowledged();
  }
}

/// Convenience wrapper for the app, which reads the flag from a provider.
Future<void> showInterruptedRestorePromptFromFlag(
  BuildContext context, {
  required RestoreProgressFlag flag,
}) {
  return showInterruptedRestorePrompt(
    context,
    readInterrupted: flag.read,
    onAcknowledged: flag.clear,
  );
}
