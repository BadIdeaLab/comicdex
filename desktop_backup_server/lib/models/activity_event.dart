/// Something worth showing in the activity log.
///
/// Deliberately structured rather than a pre-formatted string: the server has no
/// business knowing the UI language, and storing English text would make the log
/// the one part of the window that never translates.
sealed class ActivityEvent {
  ActivityEvent() : at = DateTime.now();

  final DateTime at;
}

class FileReceivedEvent extends ActivityEvent {
  FileReceivedEvent({required this.deviceId, required this.path});

  final String deviceId;
  final String path;
}

class FileSentEvent extends ActivityEvent {
  FileSentEvent({required this.deviceId, required this.path});

  final String deviceId;
  final String path;
}

class DatabaseStoredEvent extends ActivityEvent {
  DatabaseStoredEvent({required this.deviceId});

  final String deviceId;
}

class DatabaseSentEvent extends ActivityEvent {
  DatabaseSentEvent({required this.deviceId});

  final String deviceId;
}

class PinBlockedEvent extends ActivityEvent {
  PinBlockedEvent({required this.address});

  final String address;
}

class PruneRequestedEvent extends ActivityEvent {
  PruneRequestedEvent({required this.deviceId, required this.count});

  final String deviceId;
  final int count;
}

class StaleFilesDeletedEvent extends ActivityEvent {
  StaleFilesDeletedEvent({required this.deviceId, required this.count});

  final String deviceId;
  final int count;
}

class BackupFolderChangedEvent extends ActivityEvent {
  BackupFolderChangedEvent({required this.path});

  final String path;
}

class PinRegeneratedEvent extends ActivityEvent {}

class PartFilesCleanedEvent extends ActivityEvent {
  PartFilesCleanedEvent({required this.count});

  final int count;
}
