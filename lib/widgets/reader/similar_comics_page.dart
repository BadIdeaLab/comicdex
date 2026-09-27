import 'package:concept_nhv/application/tags/find_similar_comics_online_use_case.dart';
import 'package:concept_nhv/application/tags/find_similar_comics_use_case.dart';
import 'package:concept_nhv/l10n/app_localizations.dart';
import 'package:concept_nhv/models/comic.dart';
import 'package:concept_nhv/models/comic_card_data.dart';
import 'package:concept_nhv/models/comic_language.dart';
import 'package:concept_nhv/services/local_tag_catalog_service.dart';
import 'package:concept_nhv/services/tag_display_service.dart';
import 'package:concept_nhv/state/favorite_sync_model.dart';
import 'package:concept_nhv/widgets/comic_language_badge.dart';
import 'package:concept_nhv/widgets/fallback_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The page past the last one, listing comics that resemble the one just
/// finished. See .codex/phases/P92-similar-comics-end-page.md and
/// .codex/phases/P93-similar-comics-online.md.
///
/// A page rather than an overlay: the end-of-comic card floats over the
/// artwork and fades itself out after a couple of seconds, so anything
/// interactive on it would cover the page being read and then vanish before
/// the reader decided. This costs nothing to anyone who does not swipe.
class SimilarComicsPage extends StatefulWidget {
  const SimilarComicsPage({
    super.key,
    required this.similar,
    required this.onOpen,
    required this.onFindOnline,
  });

  final List<SimilarComic> similar;
  final void Function(String comicId) onOpen;

  /// Called at most once per visit, and only when the reader asks: one
  /// request, on purpose, rather than a lookup after every comic.
  final Future<OnlineSimilarResult> Function() onFindOnline;

  @override
  State<SimilarComicsPage> createState() => _SimilarComicsPageState();
}

class _SimilarComicsPageState extends State<SimilarComicsPage> {
  OnlineSimilarResult? _online;
  bool _isSearching = false;

  Future<void> _findOnline() async {
    setState(() => _isSearching = true);
    final result = await widget.onFindOnline();
    if (!mounted) return;
    setState(() {
      _online = result;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return ColoredBox(
      color: Colors.black,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
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
            if (widget.similar.isNotEmpty) ...<Widget>[
              _SectionTitle(
                // Named for what it is. Everything here is already in the
                // library, so calling it a recommendation would read as a
                // broken one.
                title: l10n.readerSimilarInLibrary,
              ),
              const SizedBox(height: 12),
              _SimilarGrid(
                tiles: <Widget>[
                  for (final entry in widget.similar)
                    _SimilarTile(
                      title: entry.comic.title,
                      card: ComicCardData.fromStoredComic(entry.comic),
                      tagIds: entry.tagIds,
                      sharedTagIds: entry.sharedTagIds,
                      onTap: () => widget.onOpen(entry.comic.id),
                    ),
                ],
              ),
              const SizedBox(height: 20),
            ],
            _buildOnlineSection(context, l10n, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildOnlineSection(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    if (_isSearching) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final online = _online;
    if (online == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: FilledButton.tonalIcon(
          onPressed: _findOnline,
          icon: const Icon(Icons.travel_explore),
          label: Text(l10n.readerFindMoreOnline),
        ),
      );
    }

    if (online.failed) {
      return Text(
        l10n.readerOnlineLookupFailed,
        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
      );
    }

    final searchedTag = online.searchedTag;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SectionTitle(title: l10n.readerSimilarOnline),
        if (searchedTag != null)
          Text(
            // Says where this list came from. Without it the results look
            // like they appeared from nowhere.
            l10n.readerSearchedTag(
              context.read<TagDisplayService>().displayName(
                searchedTag.slug,
                searchedTag.name,
              ),
            ),
            style: theme.textTheme.labelSmall?.copyWith(color: Colors.white54),
          ),
        const SizedBox(height: 12),
        if (online.comics.isEmpty)
          Text(
            l10n.readerNothingNewOnline,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          )
        else
          _SimilarGrid(
            tiles: <Widget>[
              for (final entry in online.comics)
                _SimilarTile(
                  title:
                      entry.comic.title.english ??
                      entry.comic.title.pretty ??
                      entry.comic.id,
                  card: ComicCardData.fromComic(entry.comic),
                  tagIds: entry.comic.effectiveTagIds,
                  sharedTagIds: entry.sharedTagIds,
                  onTap: () => widget.onOpen(entry.comic.id),
                ),
            ],
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(color: Colors.white70),
    );
  }
}

class _SimilarGrid extends StatelessWidget {
  const _SimilarGrid({required this.tiles});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Three across on a phone, more on a tablet. How many comics there
        // are is decided by how many are actually similar, never by how much
        // room is left to fill.
        //
        // The minimum of three is load bearing: at two columns six covers
        // become three rows, which pushes the "find more" button off a
        // phone screen entirely.
        final columns = (constraints.maxWidth / 130).floor().clamp(3, 6);
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          childAspectRatio: 0.52,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: tiles,
        );
      },
    );
  }
}

class _SimilarTile extends StatelessWidget {
  const _SimilarTile({
    required this.title,
    required this.card,
    required this.tagIds,
    required this.sharedTagIds,
    required this.onTap,
  });

  final String title;
  final ComicCardData card;
  final List<int> tagIds;
  final List<int> sharedTagIds;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    FallbackCachedNetworkImage(
                      url: card.thumbnailUrl,
                      width: card.thumbnailWidth,
                      height: card.thumbnailHeight,
                    ),
                    // Same badge as the feed cards (P70). Without it there is
                    // no way to tell a Chinese release from a Japanese one
                    // before opening it.
                    if (primaryLanguageCode(tags: card.tags, tagIds: tagIds)
                        case final code?)
                      ComicLanguageBadge(label: code),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: _FavoriteButton(card: card),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white),
            ),
            // The reason, which is what separates this from a random fill.
            // The answer is already computed, so leaving it out is a choice.
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
      for (final tagId in sharedTagIds)
        if (catalog.entryById(tagId) case final tag?)
          display.displayName(tag.slug, tag.name),
    ];
    if (names.isEmpty) return '';
    return AppLocalizations.of(context)!.readerSharedTags(names.join('、'));
  }
}

/// Favouriting straight from the tile.
///
/// Without it, keeping something meant opening it, backing out, and finding
/// it again — and the reader has just been replaced by the comic they tapped,
/// so "back" does not return here.
class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.card});

  final ComicCardData card;

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoriteSyncModel>(
      builder: (context, favorites, _) {
        final isFavorite = favorites.isFavorite(card.id);
        final isMutating = favorites.isMutating(card.id);
        return IconButton(
          iconSize: 18,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_outline,
            color: Colors.white,
            shadows: const <Shadow>[
              Shadow(blurRadius: 4, color: Colors.black87),
            ],
          ),
          onPressed: isMutating ? null : () => favorites.toggleFavorite(card),
        );
      },
    );
  }
}
