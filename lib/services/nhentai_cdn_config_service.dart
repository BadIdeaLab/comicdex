import 'package:concept_nhv/models/nhentai_cdn_config.dart';
import 'package:dio/dio.dart';

class NhentaiCdnConfigService {
  NhentaiCdnConfigService({Dio? dio}) : _dio = dio ?? Dio();

  static const List<String> _defaultImageHosts = <String>[
    'i1.nhentai.net',
    'i2.nhentai.net',
    'i3.nhentai.net',
    'i4.nhentai.net',
  ];

  static const List<String> _defaultThumbnailHosts = <String>[
    't1.nhentai.net',
    't2.nhentai.net',
    't3.nhentai.net',
    't4.nhentai.net',
  ];

  final Dio _dio;
  NhentaiCdnConfig? _cachedConfig;

  List<String> get imageHosts {
    return _cachedConfig?.imageServers
            .map(Uri.parse)
            .map((uri) => uri.host)
            .where((host) => host.isNotEmpty)
            .toList(growable: false) ??
        _defaultImageHosts;
  }

  List<String> get thumbnailHosts {
    return _cachedConfig?.thumbnailServers
            .map(Uri.parse)
            .map((uri) => uri.host)
            .where((host) => host.isNotEmpty)
            .toList(growable: false) ??
        _defaultThumbnailHosts;
  }

  Future<NhentaiCdnConfig> load() async {
    if (_cachedConfig != null) {
      return _cachedConfig!;
    }

    final response = await _dio.getUri<Map<String, dynamic>>(
      Uri.https('nhentai.net', '/api/v2/config'),
    );
    final config = NhentaiCdnConfig.fromJson(response.data ?? const {});
    _cachedConfig = config;
    return config;
  }

  void refreshInBackground() {
    Future<void>(() async {
      try {
        await load();
      } catch (_) {}
    });
  }
}
