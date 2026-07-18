import 'package:concept_nhv/models/comic_card_data.dart';
import 'package:concept_nhv/models/stored_comic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ComicCardData', () {
    test('uses legacy serialized image fallback when stored payload is invalid', () {
      final card = ComicCardData.fromStoredComic(
        StoredComic(
          id: '1',
          mediaId: '9',
          title: 'Legacy',
          serializedImages: 'jjjj',
          pages: 4,
        ),
      );

      expect(card.thumbnailUrl, contains('thumb.jpg'));
      expect(card.thumbnailWidth, 9);
      expect(card.thumbnailHeight, 16);
    });
  });
}
