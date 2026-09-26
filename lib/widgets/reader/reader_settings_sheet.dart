import 'package:concept_nhv/l10n/app_localizations.dart';
import 'package:concept_nhv/application/reader/reader_settings_repository.dart';
import 'package:concept_nhv/state/reader_settings_model.dart';
import 'package:flutter/material.dart';

/// Bottom sheet content for adjusting reader preferences: reading
/// direction, tap zone width, and pre-fetch page count.
class ReaderSettingsSheet extends StatefulWidget {
  const ReaderSettingsSheet({super.key, required this.model});

  final ReaderSettingsModel model;

  @override
  State<ReaderSettingsSheet> createState() => _ReaderSettingsSheetState();
}

class _ReaderSettingsSheetState extends State<ReaderSettingsSheet> {
  late int _prefetchCount;
  late ReadingDirection _readingDirection;
  late double _tapZoneRatio;

  @override
  void initState() {
    super.initState();
    _prefetchCount = widget.model.prefetchPageCount;
    _readingDirection = widget.model.readingDirection;
    _tapZoneRatio = widget.model.tapZoneRatio;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.readerSettingsTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Text(l10n.readerReadingDirection),
          const SizedBox(height: 8),
          SegmentedButton<ReadingDirection>(
            segments: <ButtonSegment<ReadingDirection>>[
              ButtonSegment(
                value: ReadingDirection.ltr,
                label: Text(l10n.readerDirectionLtr),
              ),
              ButtonSegment(
                value: ReadingDirection.rtl,
                label: Text(l10n.readerDirectionRtl),
              ),
            ],
            selected: <ReadingDirection>{_readingDirection},
            onSelectionChanged: (selected) {
              final dir = selected.first;
              setState(() => _readingDirection = dir);
              widget.model.saveReadingDirection(dir);
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Text(l10n.readerTapZoneWidth)),
              Text('${(_tapZoneRatio * 100).round()}%'),
            ],
          ),
          Slider(
            value: _tapZoneRatio,
            min: ReaderSettingsRepository.minTapZoneRatio,
            max: ReaderSettingsRepository.maxTapZoneRatio,
            divisions:
                ((ReaderSettingsRepository.maxTapZoneRatio -
                            ReaderSettingsRepository.minTapZoneRatio) /
                        0.05)
                    .round(),
            label: '${(_tapZoneRatio * 100).round()}%',
            onChanged: (value) {
              setState(() => _tapZoneRatio = value);
            },
            onChangeEnd: (value) {
              widget.model.saveTapZoneRatio(value);
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Text(l10n.readerPrefetchPages)),
              Text('$_prefetchCount'),
            ],
          ),
          Slider(
            value: _prefetchCount.toDouble(),
            min: ReaderSettingsRepository.minPrefetchPageCount.toDouble(),
            max: ReaderSettingsRepository.maxPrefetchPageCount.toDouble(),
            divisions:
                ReaderSettingsRepository.maxPrefetchPageCount -
                ReaderSettingsRepository.minPrefetchPageCount,
            label: '$_prefetchCount',
            onChanged: (value) {
              setState(() => _prefetchCount = value.round());
            },
            onChangeEnd: (value) {
              widget.model.savePrefetchPageCount(value.round());
            },
          ),
          const SizedBox(height: 8),
          Text(
            l10n.readerPrefetchExplanation(_prefetchCount),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
