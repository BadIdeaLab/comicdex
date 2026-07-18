import 'package:concept_nhv/services/image_url_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'buildFallbackImageUrls keeps original url and adds host/ext variants',
    () {
      const resolver = ImageUrlResolver();

      final urls = resolver.buildFallbackImageUrls(
        'https://i.nhentai.net/galleries/9/1.webp',
      );

      expect(urls.first, 'https://i.nhentai.net/galleries/9/1.webp');
      expect(urls, contains('https://i1.nhentai.net/galleries/9/1.jpg'));
      expect(urls, contains('https://i4.nhentai.net/galleries/9/1.gif'));
      expect(urls.toSet().length, urls.length);
    },
  );
}
