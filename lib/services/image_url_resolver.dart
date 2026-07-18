import 'package:concept_nhv/services/nhentai_cdn_config_service.dart';

class ImageUrlResolver {
  const ImageUrlResolver({this.cdnConfigService});

  final NhentaiCdnConfigService? cdnConfigService;

  List<String> buildFallbackImageUrls(String originalUrl) {
    final uri = Uri.tryParse(originalUrl);
    if (uri == null) {
      return <String>[originalUrl];
    }

    final thumbnailHosts =
        cdnConfigService?.thumbnailHosts ??
        const <String>[
          't1.nhentai.net',
          't2.nhentai.net',
          't3.nhentai.net',
          't4.nhentai.net',
        ];
    final imageHosts =
        cdnConfigService?.imageHosts ??
        const <String>[
          'i1.nhentai.net',
          'i2.nhentai.net',
          'i3.nhentai.net',
          'i4.nhentai.net',
        ];

    final hosts = switch (uri.host) {
      't.nhentai.net' ||
      't1.nhentai.net' ||
      't2.nhentai.net' ||
      't3.nhentai.net' ||
      't4.nhentai.net' => thumbnailHosts,
      'i.nhentai.net' ||
      'i1.nhentai.net' ||
      'i2.nhentai.net' ||
      'i3.nhentai.net' ||
      'i4.nhentai.net' => imageHosts,
      _ => <String>[uri.host],
    };

    final pathSegments = uri.pathSegments;
    final lastSegment = pathSegments.isEmpty ? '' : pathSegments.last;
    final currentExt = lastSegment.contains('.')
        ? lastSegment.split('.').last
        : '';
    final extensionCandidates = <String>[
      currentExt,
      'jpg',
      'webp',
      'png',
      'gif',
    ].where((extension) => extension.isNotEmpty).toSet().toList();

    final urls = <String>[originalUrl];
    for (final host in hosts) {
      for (final extension in extensionCandidates) {
        var candidateUri = uri.replace(host: host);
        if (lastSegment.contains('.')) {
          final updatedSegments = <String>[
            ...pathSegments.take(pathSegments.length - 1),
            '${lastSegment.substring(0, lastSegment.lastIndexOf('.'))}.$extension',
          ];
          candidateUri = candidateUri.replace(pathSegments: updatedSegments);
        }
        urls.add(candidateUri.toString());
      }
    }

    return urls.toSet().toList();
  }
}
