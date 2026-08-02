enum MobileJobState { idle, running, pausing, paused, completed, error }

class ConnectedMobileDevice {
  const ConnectedMobileDevice({
    required this.deviceId,
    required this.state,
    required this.connectedAt,
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

  bool get canStart =>
      state != MobileJobState.running && state != MobileJobState.pausing;
  bool get canPause => state == MobileJobState.running;

  ConnectedMobileDevice copyWith({
    MobileJobState? state,
    String? commandId,
    String? currentPath,
    int? uploadedFiles,
    int? totalFiles,
    String? message,
  }) {
    return ConnectedMobileDevice(
      deviceId: deviceId,
      state: state ?? this.state,
      connectedAt: connectedAt,
      commandId: commandId ?? this.commandId,
      currentPath: currentPath,
      uploadedFiles: uploadedFiles ?? this.uploadedFiles,
      totalFiles: totalFiles ?? this.totalFiles,
      message: message,
    );
  }
}

enum MobileControlAction { startBackup, pause }
