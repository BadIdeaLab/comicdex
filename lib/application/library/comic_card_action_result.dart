class ComicCardActionResult {
  const ComicCardActionResult({
    required this.success,
    this.message,
    this.triggerHaptic = false,
    this.shouldRefreshCollection = false,
  });

  final bool success;
  final String? message;
  final bool triggerHaptic;
  final bool shouldRefreshCollection;
}
