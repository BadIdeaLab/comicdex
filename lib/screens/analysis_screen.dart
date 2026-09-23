import 'package:concept_nhv/application/home/home_shell_controller.dart';
import 'package:concept_nhv/application/tags/load_tag_coverage_use_case.dart';
import 'package:concept_nhv/models/tag_combination.dart';
import 'package:concept_nhv/models/tag_preference_entry.dart';
import 'package:concept_nhv/services/tag_display_service.dart';
import 'package:concept_nhv/state/home_ui_model.dart';
import 'package:concept_nhv/state/tag_preference_model.dart';
import 'package:concept_nhv/widgets/glass_container.dart';
import 'package:concept_nhv/widgets/tag_actions_sheet.dart';
import 'package:concept_nhv/widgets/tag_preference_sliver.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// The full tag analysis: coverage, the complete ranking, and the tag pairs
/// kept together more often than chance. See
/// .codex/phases/P81-analysis-page-and-cooccurrence.md.
class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TagPreferenceModel>().loadAnalysis();
    });
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<TagPreferenceModel>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: <Widget>[
          SliverAppBar(
            backgroundColor: Colors.transparent,
            flexibleSpace: GlassContainer.bar(child: const SizedBox.expand()),
            floating: true,
            snap: true,
            title: const Text('Tag Analysis'),
          ),
          if (!model.hasLoadedAnalysis)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else ...<Widget>[
            SliverToBoxAdapter(child: _buildCoverage(context, model.coverage)),
            _buildCombinations(
              context,
              model.combinations,
              model.combinationSort,
              model.setCombinationSort,
            ),
            TagPreferenceSliver(
              preferences: model.preferences,
              sort: model.sort,
              onSortChanged: model.setSort,
              // No cap here: this page exists to show the whole list.
              collapsedCount: null,
              onTagTap: (tag, displayName) =>
                  _searchOnHome(context, <String>[tag.query]),
              onTagLongPress: (tag, displayName) =>
                  showTagActionsSheet(context, tag, displayName),
            ),
          ],
        ],
      ),
    );
  }

  /// Submits the search *and* returns to the shell's home route. This page
  /// lives inside the app shell, so submitting alone only switches the tab
  /// underneath while the analysis page stays on screen — which reads as
  /// "the tap did nothing".
  Future<void> _searchOnHome(BuildContext context, List<String> queries) async {
    await context.read<HomeShellController>().submitTagSearch(queries);
    if (context.mounted) context.goNamed('index');
  }

  /// Sends the whole combination to the Downloads tab as tag chips (P82) —
  /// the local counterpart of tapping, which searches the site.
  void _filterDownloads(BuildContext context, List<int> tagIds) {
    if (tagIds.isEmpty) return;
    context.read<HomeUiModel>().filterDownloadsByTags(tagIds);
    context.goNamed('index');
  }

  Widget _buildCoverage(BuildContext context, TagCoverage? coverage) {
    final theme = Theme.of(context);
    if (coverage == null || coverage.keptComics == 0) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Text(
          'Nothing kept yet. Favorite or download some comics and this page '
          'fills in.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final percent = (coverage.ratio * 100).round();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: GlassContainer.card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${coverage.keptComics} comics kept',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                '${coverage.taggedComics} of them carry tags ($percent%)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (percent < 90) ...<Widget>[
                const SizedBox(height: 8),
                // Said plainly, because everything below is computed from the
                // tagged subset only: a low number means the ranking speaks
                // for part of the library, not all of it.
                Text(
                  'Everything below is based on the tagged ones. Sync '
                  'favorites from Settings to fill in the rest.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCombinations(
    BuildContext context,
    List<TagCombination> combinations,
    TagPreferenceSort sort,
    ValueChanged<TagPreferenceSort> onSortChanged,
  ) {
    final theme = Theme.of(context);
    if (combinations.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    final maxLift = combinations.first.lift;

    return SliverList.list(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 12, 2),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Taste Combinations',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              SegmentedButton<TagPreferenceSort>(
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                segments: const <ButtonSegment<TagPreferenceSort>>[
                  ButtonSegment<TagPreferenceSort>(
                    value: TagPreferenceSort.count,
                    label: Text('Most kept'),
                  ),
                  ButtonSegment<TagPreferenceSort>(
                    value: TagPreferenceSort.affinity,
                    label: Text('Most distinctive'),
                  ),
                ],
                selected: <TagPreferenceSort>{sort},
                onSelectionChanged: (selection) =>
                    onSortChanged(selection.first),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            'Two or three tags that show up together more often than each '
            'tag on its own would suggest. Tap to search them; long-press to '
            'filter Downloads by them.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        for (final combination in combinations)
          _CombinationRow(
            combination: combination,
            fraction: maxLift <= 0 ? 0 : combination.lift / maxLift,
            onTap: () => _searchOnHome(context, combination.searchQueries),
            onLongPress: () => _filterDownloads(context, combination.tagIds),
          ),
      ],
    );
  }
}

class _CombinationRow extends StatelessWidget {
  const _CombinationRow({
    required this.combination,
    required this.fraction,
    required this.onTap,
    required this.onLongPress,
  });

  final TagCombination combination;
  final double fraction;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final display = context.read<TagDisplayService>();
    final label = combination.members
        .map((member) => display.displayName(member.slug, member.name))
        .join(' + ');
    const radius = BorderRadius.all(Radius.circular(10));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Material(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: fraction.clamp(0.02, 1.0),
                  child: ColoredBox(
                    color: theme.colorScheme.primary.withValues(alpha: 0.28),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${combination.comicCount} · '
                      '${combination.lift.toStringAsFixed(1)}×',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
