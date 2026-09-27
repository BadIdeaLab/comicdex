import 'package:concept_nhv/models/comic_card_data.dart';
import 'package:concept_nhv/state/favorite_sync_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The heart in the reader's top bar.
///
/// Takes the card rather than a comic id: favouriting stores the row, and
/// which row that is follows a rule of its own (see `readerFavoriteCard`).
class ReaderFavoriteToggle extends StatelessWidget {
  const ReaderFavoriteToggle({super.key, required this.card});

  final ComicCardData card;

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoriteSyncModel>(
      builder: (context, favorites, _) {
        final isFavorite = favorites.isFavorite(card.id);
        final isMutating = favorites.isMutating(card.id);
        return IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_outline,
            color: Colors.white,
          ),
          onPressed: isMutating ? null : () => favorites.toggleFavorite(card),
        );
      },
    );
  }
}
