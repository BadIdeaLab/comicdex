import 'package:concept_nhv/models/downloads_sort_mode.dart';
import 'package:concept_nhv/state/download_manager_model.dart';
import 'package:concept_nhv/widgets/glass_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DownloadsSortBottomSheet extends StatefulWidget {
  const DownloadsSortBottomSheet({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showGlassModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<DownloadManagerModel>(),
        child: const DownloadsSortBottomSheet(),
      ),
    );
    return result ?? false;
  }

  @override
  State<DownloadsSortBottomSheet> createState() =>
      _DownloadsSortBottomSheetState();
}

class _DownloadsSortBottomSheetState extends State<DownloadsSortBottomSheet> {
  late DownloadsSortMode _selectedMode;
  late DownloadsSortDirection _selectedDirection;

  @override
  void initState() {
    super.initState();
    final model = context.read<DownloadManagerModel>();
    _selectedMode = model.downloadsSortMode;
    _selectedDirection = model.downloadsSortDirection;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Sort Downloads',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: DownloadsSortMode.values.map((mode) {
                    return FilterChip(
                      label: Text(mode.label),
                      selected: _selectedMode == mode,
                      onSelected: (_) => _handleModeSelected(mode),
                      showCheckmark: true,
                    );
                  }).toList(growable: false),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: DownloadsSortDirection.values.map((direction) {
                    return FilterChip(
                      label: Text(direction.label),
                      selected: _selectedDirection == direction,
                      onSelected: (_) => _handleDirectionSelected(direction),
                      showCheckmark: true,
                    );
                  }).toList(growable: false),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _handleReset,
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _handleApply,
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleReset() {
    _handleModeSelected(DownloadsSortMode.latestDownloaded);
    _handleDirectionSelected(DownloadsSortDirection.descending);
  }

  void _handleApply() {
    context.read<DownloadManagerModel>().setDownloadsSortMode(_selectedMode);
    context
        .read<DownloadManagerModel>()
        .setDownloadsSortDirection(_selectedDirection);
    Navigator.of(context).pop(true);
  }

  void _handleModeSelected(DownloadsSortMode mode) {
    setState(() {
      _selectedMode = mode;
    });
    context.read<DownloadManagerModel>().setDownloadsSortMode(mode);
  }

  void _handleDirectionSelected(DownloadsSortDirection direction) {
    setState(() {
      _selectedDirection = direction;
    });
    context.read<DownloadManagerModel>().setDownloadsSortDirection(direction);
  }
}
