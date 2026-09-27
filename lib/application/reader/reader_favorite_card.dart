import 'package:concept_nhv/models/comic.dart';
import 'package:concept_nhv/models/comic_card_data.dart';
import 'package:concept_nhv/models/stored_comic.dart';

/// What to hand the favourites model when the reader keeps [comic].
///
/// Not simply the comic on screen: reading offline reconstructs it from local
/// files, so its image manifest holds file paths rather than the site's.
/// Favouriting replaces the stored row outright, and that swap would leave the
/// Favorites grid with no cover — the same trap `insertComicIfAbsent` was
/// written to avoid. So [stored] wins when there is one, and the card is only
/// built from the session's comic when there is nothing stored to damage.
ComicCardData readerFavoriteCard({required Comic comic, StoredComic? stored}) {
  if (stored != null) return ComicCardData.fromStoredComic(stored);
  return ComicCardData.fromComic(comic);
}
