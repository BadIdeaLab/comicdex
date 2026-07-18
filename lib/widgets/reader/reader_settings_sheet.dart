import 'package:concept_nhv/application/reader/reader_settings_repository.dart';
import 'package:concept_nhv/state/comic_reader_model.dart';
import 'package:flutter/material.dart';

/// Bottom sheet content for adjusting reader preferences: reading
/// direction, tap zone width, and pre-fetch page count.
class ReaderSettingsSheet extends StatefulWidget {
  const ReaderSettingsSheet({super.key, required this.model});

  final ComicReaderModel model;

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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reader Settings',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          const Text('Reading Direction'),
          const SizedBox(height: 8),
          SegmentedButton<ReadingDirection>(
            segments: const <ButtonSegment<ReadingDirection>>[
              ButtonSegment(value: ReadingDirection.ltr, label: Text('LTR')),
              ButtonSegment(value: ReadingDirection.rtl, label: Text('RTL')),
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
              const Expanded(child: Text('Tap zone width')),
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
              const Expanded(child: Text('Pre-fetch pages (before & after)')),
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
            'Currently caching $_prefetchCount page(s) on each side of the'
            ' current page.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
