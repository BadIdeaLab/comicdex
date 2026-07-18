import 'package:concept_nhv/models/comic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Comic fromJson and toJson keep key fields', () {
    final comic = Comic.fromJson(<String, dynamic>{
      'id': 1001,
      'media_id': 9,
      'title': <String, dynamic>{
        'english': 'Sample Comic',
        'japanese': 'サンプル',
        'pretty': 'Sample Comic',
      },
      'images': <String, dynamic>{
        'pages': <Map<String, dynamic>>[
          <String, dynamic>{'t': 'j', 'w': 100, 'h': 200},
        ],
        'cover': <String, dynamic>{'t': 'j', 'w': 100, 'h': 200},
        'thumbnail': <String, dynamic>{'t': 'w', 'w': 50, 'h': 100},
      },
      'scanlator': null,
      'upload_date': 0,
      'tags': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 1,
          'type': 'tag',
          'name': 'sample',
          'url': '/tag/sample',
          'count': 1,
        },
      ],
      'num_pages': 1,
      'num_favorites': 5,
    });

    expect(comic.id, '1001');
    expect(comic.mediaId, '9');
    expect(comic.images.thumbnail?.t, 'w');
    expect(comic.toJson()['num_pages'], 1);
  });
}
