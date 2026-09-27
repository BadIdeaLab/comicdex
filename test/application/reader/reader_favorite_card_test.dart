import 'dart:convert';

import 'package:concept_nhv/application/reader/reader_favorite_card.dart';
import 'package:concept_nhv/models/stored_comic.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_support/fixtures/sample_comic.dart';

void main() {
  group('readerFavoriteCard', () {
    final comic = sampleComic(id: '42', mediaId: '900');

    test('prefers the stored row', () {
      // Reading offline rebuilds the comic from local files, so its manifest
      // holds file paths. Favouriting replaces the stored row outright, and
      // letting that manifest win would leave the Favorites grid with no
      // cover.
      final stored = StoredComic(
        id: '42',
        mediaId: '900',
        title: 'stored title',
        serializedImages: jsonEncode(comic.images.toJson()),
        pages: 2,
      );

      final card = readerFavoriteCard(comic: comic, stored: stored);

      expect(card.title, 'stored title');
    });

    test('falls back to the comic when nothing is stored', () {
      // Nothing to damage in that case, and a card is needed either way.
      final card = readerFavoriteCard(comic: comic);

      expect(card.id, '42');
      expect(card.mediaId, '900');
    });
  });
}
