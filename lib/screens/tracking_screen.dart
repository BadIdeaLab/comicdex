import 'package:concept_nhv/application/home/home_shell_controller.dart';
import 'package:concept_nhv/l10n/app_localizations.dart';
import 'package:concept_nhv/services/tag_display_service.dart';
import 'package:concept_nhv/state/tracking_model.dart';
import 'package:concept_nhv/widgets/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// The tracked artists: who has published, and who is still being watched.
class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final model = context.watch<TrackingModel>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        // A pull overrules our own pacing, but never a cooldown the site
        // imposed — see TrackingCooldown.
        onRefresh: () => model.check(manual: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: <Widget>[
            SliverAppBar(
              backgroundColor: Colors.transparent,
              flexibleSpace: GlassContainer.bar(child: const SizedBox.expand()),
              floating: true,
              snap: true,
              title: Text(l10n.trackingTitle),
            ),
            if (model.artists.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(l10n: l10n),
              )
            else
              SliverList.separated(
                itemCount: model.artists.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) =>
                    _TrackedArtistRow(entry: model.artists[index]),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.notifications_none,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(l10n.trackingEmptyTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          // The only place tracking explains itself: the way in is a
          // long-press on an artist tag, which nothing else advertises.
          Text(
            l10n.trackingEmptyBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackedArtistRow extends StatelessWidget {
  const _TrackedArtistRow({required this.entry});

  final TrackedArtistEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final catalogEntry = entry.catalogEntry;
    final name = catalogEntry == null
        ? l10n.trackingUnknownArtist
        : context.read<TagDisplayService>().displayName(
            catalogEntry.slug,
            catalogEntry.name,
          );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GlassContainer.card(
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          leading: Icon(
            entry.hasNewWork ? Icons.fiber_new : Icons.person_search_outlined,
            color: entry.hasNewWork
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          title: Text(name),
          subtitle: Text(
            entry.hasNewWork
                ? l10n.trackingNewCount(entry.newCount)
                : l10n.trackingNoNewWork,
          ),
          trailing: IconButton(
            tooltip: l10n.trackingUntrackAction,
            icon: const Icon(Icons.notifications_off_outlined),
            onPressed: () => context.read<TrackingModel>().untrack(entry.tagId),
          ),
          // A catalog entry we cannot name has no query to search for, so the
          // row is there only to be un-tracked.
          onTap: catalogEntry == null
              ? null
              : () => _openArtist(context, catalogEntry.query),
        ),
      ),
    );
  }

  Future<void> _openArtist(BuildContext context, String query) async {
    final model = context.read<TrackingModel>();
    final controller = context.read<HomeShellController>();
    final router = GoRouter.of(context);

    // Marked seen on opening, not on seeing the number: a count on a list is
    // not the work, and the search results are.
    await model.markSeen(entry.tagId);
    await controller.submitTagSearch(<String>[query]);
    // This screen is pushed over the shell, so switching the tab underneath
    // is not enough — without this the tap looks like it did nothing (the
    // same trap the analysis page documents).
    router.goNamed('index');
  }
}
