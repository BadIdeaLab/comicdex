enum DownloadPageStatus {
  pending('pending'),
  downloading('downloading'),
  completed('completed'),
  failed('failed');

  const DownloadPageStatus(this.storageValue);

  final String storageValue;

  static DownloadPageStatus fromStorage(String value) {
    return DownloadPageStatus.values.firstWhere(
      (status) => status.storageValue == value,
      orElse: () => DownloadPageStatus.pending,
    );
  }
}
