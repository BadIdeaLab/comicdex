import 'package:concept_nhv/application/tags/find_similar_comics_use_case.dart';
import 'package:concept_nhv/l10n/app_localizations.dart';
import 'package:concept_nhv/models/comic_card_data.dart';
import 'package:concept_nhv/services/local_tag_catalog_service.dart';
import 'package:concept_nhv/services/tag_display_service.dart';
import 'package:concept_nhv/widgets/fallback_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The page past the last one, listing comics in the user's own library that
/// resemble the one just finished. See
/// .codex/phases/P92-similar-comics-end-page.md.
///
/// A page rather than an overlay: the end-of-comic card floats over the
/// artwork and fades itself out after a couple of seconds, so anything
/// interactive on it would cover the page being read and then vanish before
/// the reader decided. This costs nothing to anyone who does not swipe.
class SimilarComicsPage extends StatelessWidget {
  const SimilarComicsPage({
    super.key,
    required this.similar,
    required this.onOpen,
  });

  final List<SimilarComic> similar;
  final void Function(String comicId) onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return ColoredBox(
      color: Colors.black,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.readerEnd,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                // Named for what it is. Everything here is already in the
                // library, so calling it a recommendation would read as a
                // broken one.
                l10n.readerSimilarInLibrary,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Three across on a phone, more on a tablet. The count of
                    // comics is fixed by how many are actually similar, not
                    // by how much room there is.
                    final columns = (constraints.maxWidth / 150).floor().clamp(
                      2,
                      6,
                    );
                    return GridView.count(
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: columns,
                      childAspectRatio: 0.52,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      children: <Widget>[
                        for (final entry in similar)
                          _SimilarTile(
                            entry: entry,
                            onTap: () => onOpen(entry.comic.id),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SimilarTile extends StatelessWidget {
  const _SimilarTile({required this.entry, required this.onTap});

  final SimilarComic entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = ComicCardData.fromStoredComic(entry.comic);

    // Its own Material rather than relying on an ancestor: this page is
    // handed to a PageView, and an InkWell with no Material above it throws.
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(6)),
                child: SizedBox.expand(
                  child: FallbackCachedNetworkImage(
                    url: card.thumbnailUrl,
                    width: card.thumbnailWidth,
                    height: card.thumbnailHeight,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              card.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white),
            ),
            // The reason, which is what separates this from a random fill. The
            // answer is already computed, so leaving it out would be a choice.
            Text(
              _reason(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _reason(BuildContext context) {
    final catalog = context.read<LocalTagCatalogService>();
    final display = context.read<TagDisplayService>();
    final names = <String>[
      for (final tagId in entry.sharedTagIds)
        if (catalog.entryById(tagId) case final tag?)
          display.displayName(tag.slug, tag.name),
    ];
    if (names.isEmpty) return '';
    return AppLocalizations.of(context)!.readerSharedTags(names.join('、'));
  }
}
