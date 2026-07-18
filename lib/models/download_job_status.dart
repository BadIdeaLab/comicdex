enum DownloadJobStatus {
  queued('queued'),
  downloading('downloading'),
  paused('paused'),
  completed('completed'),
  failed('failed');

  const DownloadJobStatus(this.storageValue);

  final String storageValue;

  static DownloadJobStatus fromStorage(String value) {
    return DownloadJobStatus.values.firstWhere(
      (status) => status.storageValue == value,
      orElse: () => DownloadJobStatus.queued,
    );
  }
}
