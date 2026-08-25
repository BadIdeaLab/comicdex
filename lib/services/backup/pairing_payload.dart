/// Parses the pairing QR produced by the desktop server.
///
/// The wire format is documented on the building half, in the desktop package's
/// `lib/services/pairing_payload.dart`. The two live in separate packages with
/// no shared dependency; the guard against drift is that both sides' tests
/// assert against the **same literal example**, so changing the format on one
/// side fails the other side's test.
library;

/// The newest format this build understands.
const int kSupportedPairingVersion = 1;

const String _scheme = 'comicdex';
const String _host = 'pair';

/// Why a scanned code could not be used.
///
/// Split by *what the user should do next*, because the four have nothing in
/// common: find a different image, scan the right thing, update the app, or
/// scan again because the code has rotated. Collapsing them into one "invalid
/// code" message would leave the user with no idea which.
enum PairingScanFailure {
  /// The image contained no QR code at all (gallery import).
  noCodeFound,

  /// A QR code, but not one of ours.
  notAPairingCode,

  /// Ours, but from a desktop newer than this app.
  unsupportedVersion,

  /// Ours and readable, but it names no address to connect to.
  noAddresses,
}

class PairingPayload {
  const PairingPayload({required this.pin, required this.addresses});

  final String pin;

  /// `host:port` strings, in the order the phone should try them.
  ///
  /// Several on purpose: the desktop cannot tell which of its interfaces this
  /// phone can reach, so it offers all of them and the phone finds out by
  /// trying rather than by anyone guessing.
  final List<String> addresses;
}

class PairingScanException implements Exception {
  const PairingScanException(this.failure);

  final PairingScanFailure failure;

  @override
  String toString() => 'PairingScanException($failure)';
}

/// Picks the pairing code out of everything that was decoded at once.
///
/// Both entry points need this and must agree: a camera frame can hold several
/// codes just as a screenshot can, and taking the *first code* rather than the
/// first **pairing** code lets an unrelated QR sharing the frame mask ours.
///
/// When nothing is usable, the first specific failure is what escapes —
/// "update the app" and "scan the right thing" send the user to different
/// places, so the reason must not decay into a generic one along the way.
///
/// Throws [PairingScanFailure.noCodeFound] for an empty list.
PairingPayload parseFirstPairingCode(List<String> rawCodes) {
  if (rawCodes.isEmpty) {
    throw const PairingScanException(PairingScanFailure.noCodeFound);
  }

  PairingScanException? firstFailure;
  for (final code in rawCodes) {
    try {
      return parsePairingUri(code);
    } on PairingScanException catch (error) {
      firstFailure ??= error;
    }
  }
  throw firstFailure!;
}

/// Reads [raw] as a pairing code.
///
/// Throws [PairingScanException] rather than returning null so the caller
/// cannot accidentally treat every failure the same way.
PairingPayload parsePairingUri(String raw) {
  final uri = Uri.tryParse(raw.trim());
  if (uri == null || uri.scheme != _scheme || uri.host != _host) {
    throw const PairingScanException(PairingScanFailure.notAPairingCode);
  }

  // A missing or non-numeric version is treated as "not ours" rather than
  // "unsupported": every version of this format has carried one, so something
  // without it was never produced by us.
  final version = int.tryParse(uri.queryParameters['v'] ?? '');
  if (version == null) {
    throw const PairingScanException(PairingScanFailure.notAPairingCode);
  }
  if (version > kSupportedPairingVersion) {
    throw const PairingScanException(PairingScanFailure.unsupportedVersion);
  }

  final pin = uri.queryParameters['pin'];
  if (pin == null || pin.isEmpty) {
    throw const PairingScanException(PairingScanFailure.notAPairingCode);
  }

  final addresses = <String>[
    for (final address in uri.queryParametersAll['a'] ?? const <String>[])
      if (address.trim().isNotEmpty) address.trim(),
  ];
  if (addresses.isEmpty) {
    // Distinct from "not ours": the code is genuine, the desktop just had no
    // usable interface to offer. Telling the user to scan a different code
    // would send them looking for a problem that is not on their phone.
    throw const PairingScanException(PairingScanFailure.noAddresses);
  }

  return PairingPayload(pin: pin, addresses: addresses);
}
