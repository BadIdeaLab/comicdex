import 'package:concept_nhv/state/download_manager_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Runs a download action and tells the user what happened.
///
/// [noOpMessage] covers the case the user cannot see: an action that
/// succeeded and changed nothing — a repair of a comic that turned out to be
/// intact — where the success message would claim work that never happened.
/// "Changed" is judged by the list identity, since the model replaces it
/// whenever anything is actually written.
Future<void> runDownloadAction(
  BuildContext context, {
  required String successMessage,
  String? noOpMessage,
  required Future<void> Function() action,
}) async {
  final beforeItems = context.read<DownloadManagerModel>().downloadItems;
  try {
    await action();
    if (!context.mounted) return;
    final afterItems = context.read<DownloadManagerModel>().downloadItems;
    final changed = afterItems != beforeItems;
    final message = (!changed && noOpMessage != null)
        ? noOpMessage
        : successMessage;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$error')));
  }
}
