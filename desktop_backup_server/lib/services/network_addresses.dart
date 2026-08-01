import 'dart:io';

/// One address the phone could potentially be pointed at.
class LanAddress {
  const LanAddress({required this.interfaceName, required this.address});

  final String interfaceName;
  final String address;
}

/// Every non-loopback IPv4 address on this machine.
///
/// Deliberately returns *all* of them with their interface names rather than
/// guessing a single "right" one: a typical dev machine also has WSL, Hyper-V
/// or VirtualBox adapters, and picking wrong would silently hand the user an
/// address their phone can never reach. Showing the interface name lets them
/// recognise their actual Wi-Fi/Ethernet adapter.
Future<List<LanAddress>> listLanAddresses() async {
  try {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
      includeLinkLocal: false,
    );
    return <LanAddress>[
      for (final interface in interfaces)
        for (final address in interface.addresses)
          LanAddress(interfaceName: interface.name, address: address.address),
    ];
  } on SocketException {
    return const <LanAddress>[];
  }
}
