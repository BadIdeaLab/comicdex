import 'package:concept_nhv/application/home/home_shell_controller.dart';
import 'package:concept_nhv/application/tags/load_comic_meta_use_case.dart';
import 'package:concept_nhv/l10n/app_localizations.dart';
import 'package:concept_nhv/models/download_list_item_snapshot.dart';
import 'package:concept_nhv/state/download_manager_model.dart';
import 'package:concept_nhv/widgets/comic_tag_bottom_sheet.dart';
import 'package:concept_nhv/widgets/downloads/download_action_runner.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// The tag sheet for a completed download, with delete/reload/repair.
///
/// Shared by the list card and the grid cell, which are two presentations of
/// the same comic and must offer the same actions.
Future<void> showCompletedSheetFor(
  BuildContext context,
  DownloadListItemSnapshot item,
  bool isMutating,
) async {
  final homeShellController = context.read<HomeShellController>();
  final loadComicMetaUseCase = context.read<LoadComicMetaUseCase>();

  await ComicTagBottomSheet.show(
    context: context,
    title: item.title,
    tags: item.tags,
    comicId: item.comicId,
    comicNumFavorites: item.numFavorites,
    loadMeta: () => loadComicMetaUseCase.execute(item.comicId),
    onSearchSelected: (queries) async {
      await homeShellController.submitTagSearch(queries);
      if (context.mounted) {
        context.goNamed('index');
      }
    },
    actionSlot: _buildCompletedActionSlotFor(context, item, isMutating),
  );
}

Widget _buildCompletedActionSlotFor(
  BuildContext context,
  DownloadListItemSnapshot item,
  bool isMutating,
) {
  final l10n = AppLocalizations.of(context)!;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
          side: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
        icon: const Icon(Icons.delete_outline),
        label: Text(l10n.downloadsDeleteAction),
        onPressed: isMutating
            ? null
            : () {
                Navigator.of(context, rootNavigator: true).pop();
                _confirmAndDeleteCompleted(context, item);
              },
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        icon: const Icon(Icons.refresh),
        label: Text(l10n.downloadsReloadAction),
        onPressed: isMutating
            ? null
            : () {
                Navigator.of(context, rootNavigator: true).pop();
                _confirmAndReloadCompleted(context, item);
              },
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        icon: const Icon(Icons.build_outlined),
        label: Text(l10n.downloadsRepairAction),
        onPressed: isMutating
            ? null
            : () {
                Navigator.of(context, rootNavigator: true).pop();
                _runRepairCompleted(context, item);
              },
      ),
    ],
  );
}

Future<void> _confirmAndDeleteCompleted(
  BuildContext context,
  DownloadListItemSnapshot item,
) async {
  final l10n = AppLocalizations.of(context)!;
  final shouldDelete = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.downloadsDeleteTitle),
        content: Text(l10n.downloadsDeleteBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.confirmButton),
          ),
        ],
      );
    },
  );

  if (shouldDelete != true || !context.mounted) {
    return;
  }

  await runDownloadAction(
    context,
    successMessage: l10n.downloadsDeletedMessage,
    action: () => context.read<DownloadManagerModel>().deleteJob(item.comicId),
  );
}

Future<void> _confirmAndReloadCompleted(
  BuildContext context,
  DownloadListItemSnapshot item,
) async {
  final l10n = AppLocalizations.of(context)!;
  final shouldReload = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.downloadsReloadTitle),
        content: Text(l10n.downloadsReloadBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.downloadsReloadAction),
          ),
        ],
      );
    },
  );

  if (shouldReload != true || !context.mounted) {
    return;
  }

  await runDownloadAction(
    context,
    successMessage: l10n.downloadsReloadQueued,
    action: () =>
        context.read<DownloadManagerModel>().reloadCompleted(item.comicId),
  );
}

Future<void> _runRepairCompleted(
  BuildContext context,
  DownloadListItemSnapshot item,
) async {
  final l10n = AppLocalizations.of(context)!;
  await runDownloadAction(
    context,
    successMessage: l10n.downloadsRepairQueued,
    noOpMessage: l10n.downloadsNothingToRepair,
    action: () async {
      await context.read<DownloadManagerModel>().repairCompleted(item.comicId);
    },
  );
}
