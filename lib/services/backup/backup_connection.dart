/// Where to reach the desktop backup server, and who we claim to be.
///
/// The desktop shows `IP:port` and a PIN; the device name is chosen once on the
/// phone and identifies this device's partition on the server. Backups made
/// under one device name can still be restored onto any other device — the name
/// only decides which folder they live in.
class BackupConnection {
  const BackupConnection({
    required this.baseUri,
    required this.pin,
    required this.deviceId,
  });

  final Uri baseUri;
  final String pin;
  final String deviceId;

  /// Parses the `192.168.1.20:8787` string shown by the desktop app.
  ///
  /// Accepts a bare host (defaulting to the server's usual port) and tolerates a
  /// pasted `http://` prefix, because both are easy to type by accident.
  static Uri? parseAddress(String input, {int defaultPort = 8787}) {
    var text = input.trim();
    if (text.isEmpty) {
      return null;
    }
    if (text.startsWith('http://')) {
      text = text.substring('http://'.length);
    } else if (text.startsWith('https://')) {
      // The server is plain HTTP on the LAN; treating this as https would fail
      // in a way that looks like the machine is unreachable.
      return null;
    }
    text = text.split('/').first;

    final host = text.contains(':') ? text.substring(0, text.lastIndexOf(':')) : text;
    final portText = text.contains(':')
        ? text.substring(text.lastIndexOf(':') + 1)
        : '$defaultPort';
    if (host.isEmpty) {
      return null;
    }
    final port = int.tryParse(portText);
    if (port == null || port < 1 || port > 65535) {
      return null;
    }
    return Uri(scheme: 'http', host: host, port: port);
  }
}
