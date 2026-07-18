class NhentaiApiCredential {
  const NhentaiApiCredential({
    required this.apiKey,
    this.username,
    this.lastValidatedAt,
  });

  final String apiKey;
  final String? username;
  final DateTime? lastValidatedAt;

  bool get isEmpty => apiKey.trim().isEmpty;

  NhentaiApiCredential copyWith({
    String? apiKey,
    String? username,
    DateTime? lastValidatedAt,
  }) {
    return NhentaiApiCredential(
      apiKey: apiKey ?? this.apiKey,
      username: username ?? this.username,
      lastValidatedAt: lastValidatedAt ?? this.lastValidatedAt,
    );
  }

  static const NhentaiApiCredential empty = NhentaiApiCredential(apiKey: '');
}
