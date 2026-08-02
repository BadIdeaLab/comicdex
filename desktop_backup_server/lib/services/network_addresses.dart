import 'dart:io';

/// One address the phone could potentially be pointed at.
class LanAddress {
  const LanAddress({
    required this.interfaceName,
    required this.address,
    required this.isLikelyVirtual,
  });

  final String interfaceName;
  final String address;

  /// True when this looks like a virtual adapter (WSL, Hyper-V, VirtualBox,
  /// VMware, Docker…). Those get an address on this machine but are unreachable
  /// from a phone on the Wi-Fi, so the UI pushes them down and labels them.
  final bool isLikelyVirtual;
}

/// Interface-name fragments that betray a virtual adapter.
///
/// Matching on the name rather than the IP range on purpose: `172.x` and
/// `192.168.x` are both legitimate private ranges, and Hyper-V happily hands out
/// either, so the range alone cannot tell them apart.
const List<String> _virtualInterfaceMarkers = <String>[
  'vethernet',
  'wsl',
  'hyper-v',
  'virtualbox',
  'vmware',
  'vmnet',
  'docker',
  'default switch',
  'loopback',
  'tailscale',
  'zerotier',
  'tap-',
  'tun',
];

bool _looksVirtual(String interfaceName) {
  final name = interfaceName.toLowerCase();
  return _virtualInterfaceMarkers.any(name.contains);
}

/// Every non-loopback IPv4 address on this machine, most likely to work first.
///
/// All of them are returned rather than picking one: guessing wrong would hand
/// the user an address their phone can never reach, and the resulting timeout
/// looks exactly like a firewall problem. But leaving them completely unordered
/// is just as bad — a machine with WSL installed often lists its virtual adapter
/// first, so the obvious thing to try is the one guaranteed to fail.
Future<List<LanAddress>> listLanAddresses() async {
  try {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
      includeLinkLocal: false,
    );
    final addresses = <LanAddress>[
      for (final interface in interfaces)
        for (final address in interface.addresses)
          LanAddress(
            interfaceName: interface.name,
            address: address.address,
            isLikelyVirtual: _looksVirtual(interface.name),
          ),
    ];
    addresses.sort((a, b) {
      if (a.isLikelyVirtual != b.isLikelyVirtual) {
        return a.isLikelyVirtual ? 1 : -1;
      }
      return a.address.compareTo(b.address);
    });
    return addresses;
  } on SocketException {
    return const <LanAddress>[];
  }
}
