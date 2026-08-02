import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

class DeviceNameService {
  DeviceNameService({DeviceInfoPlugin? plugin})
    : _plugin = plugin ?? DeviceInfoPlugin();

  final DeviceInfoPlugin _plugin;

  Future<String> suggestedName() async {
    try {
      if (Platform.isAndroid) {
        final info = await _plugin.androidInfo;
        return _safeName('${info.manufacturer} ${info.model}');
      }
      if (Platform.isIOS) {
        final info = await _plugin.iosInfo;
        return _safeName('${info.model} ${info.utsname.machine}');
      }
    } on Object {
      // Device information is a convenience. Pairing must remain usable when a
      // vendor ROM omits a field or a platform channel is unavailable.
    }
    return 'Mobile Device';
  }

  static String _safeName(String raw) {
    final cleaned = raw
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '-')
        .replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.isEmpty) {
      return 'Mobile Device';
    }
    return cleaned.length <= 64 ? cleaned : cleaned.substring(0, 64).trimRight();
  }
}
