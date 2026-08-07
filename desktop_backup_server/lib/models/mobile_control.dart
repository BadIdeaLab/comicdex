enum MobileJobState { idle, running, pausing, paused, completed, error }

class ConnectedMobileDevice {
  const ConnectedMobileDevice({
    required this.deviceId,
    required this.state,
    required this.connectedAt,
    this.jobKind = 'backup',
    this.commandId,
    this.currentPath,
    this.uploadedFiles = 0,
    this.totalFiles = 0,
    this.message,
  });

  final String deviceId;
  final MobileJobState state;
  final DateTime connectedAt;
  final String? commandId;
  final String? currentPath;
  final int uploadedFiles;
  final int totalFiles;
  final String? message;

  /// 'backup' or 'restore' — the states are shared, so this is what lets the UI
  /// avoid calling a finished restore a completed backup.
  final String jobKind;

  bool get isRestoring => jobKind == 'restore';

  bool get canStart =>
      state != MobileJobState.running && state != MobileJobState.pausing;
  bool get canPause => state == MobileJobState.running;

  ConnectedMobileDevice copyWith({
    MobileJobState? state,
    String? jobKind,
    String? commandId,
    String? currentPath,
    int? uploadedFiles,
    int? totalFiles,
    String? message,
  }) {
    return ConnectedMobileDevice(
      deviceId: deviceId,
      state: state ?? this.state,
      jobKind: jobKind ?? this.jobKind,
      connectedAt: connectedAt,
      commandId: commandId ?? this.commandId,
      currentPath: currentPath,
      uploadedFiles: uploadedFiles ?? this.uploadedFiles,
      totalFiles: totalFiles ?? this.totalFiles,
      message: message,
    );
  }
}

enum MobileControlAction { startBackup, startRestore, pause }
