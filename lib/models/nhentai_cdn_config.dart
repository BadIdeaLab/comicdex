class NhentaiCdnConfig {
  const NhentaiCdnConfig({
    required this.imageServers,
    required this.thumbnailServers,
  });

  final List<String> imageServers;
  final List<String> thumbnailServers;

  factory NhentaiCdnConfig.fromJson(Map<String, dynamic> json) {
    return NhentaiCdnConfig(
      imageServers: List<String>.from(
        (json['image_servers'] as List<dynamic>? ?? const <dynamic>[]),
      ),
      thumbnailServers: List<String>.from(
        (json['thumb_servers'] as List<dynamic>? ?? const <dynamic>[]),
      ),
    );
  }
}
