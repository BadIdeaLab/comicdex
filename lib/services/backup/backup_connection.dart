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

    final host = text.contains(':')
        ? text.substring(0, text.lastIndexOf(':'))
        : text;
    final portText = text.contains(':')
        ? text.substring(text.lastIndexOf(':') + 1)
        : '$defaultPort';
    if (!_isValidHost(host)) {
      return null;
    }
    final port = int.tryParse(portText);
    if (port == null || port < 1 || port > 65535) {
      return null;
    }
    return Uri(scheme: 'http', host: host, port: port);
  }

  static final RegExp _hostCharacters = RegExp(r'^[A-Za-z0-9.-]+$');
  static final RegExp _numericHost = RegExp(r'^[0-9.]+$');

  /// Rejects hosts that cannot possibly be the desktop server.
  ///
  /// Worth being strict here: an address the user fat-fingered (`192.168.137,1`
  /// instead of `192.168.137.1` — the keys are adjacent on a numeric keypad)
  /// otherwise sails through, gets attempted as a hostname, and comes back as a
  /// generic connect failure. The user is then told to check their Wi-Fi and
  /// firewall for what is really a typo. Catching it here turns that into the
  /// "enter it exactly as shown on the computer" message instead.
  static bool _isValidHost(String host) {
    if (host.isEmpty || !_hostCharacters.hasMatch(host)) {
      return false;
    }
    if (!_numericHost.hasMatch(host)) {
      // A real hostname; the OS resolver can judge it.
      return true;
    }
    // Digits and dots only means an IPv4 literal was intended, so hold it to
    // that — `192.168.1` or `192.168.137.1.5` are typos, not hostnames.
    final octets = host.split('.');
    if (octets.length != 4) {
      return false;
    }
    return octets.every((octet) {
      if (octet.isEmpty || octet.length > 3) {
        return false;
      }
      final value = int.tryParse(octet);
      return value != null && value >= 0 && value <= 255;
    });
  }
}
