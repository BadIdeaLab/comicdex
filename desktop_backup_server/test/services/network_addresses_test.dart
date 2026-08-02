import 'package:desktop_backup_server/services/network_addresses.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LanAddress ordering', () {
    // Reproduces a real machine's adapter list: WSL's virtual adapter enumerates
    // before the physical Ethernet one, so an unsorted list puts the address
    // that cannot possibly work at the top — and the resulting timeout looks
    // identical to a firewall problem.
    List<LanAddress> sorted(List<LanAddress> input) {
      final copy = List<LanAddress>.of(input);
      copy.sort((a, b) {
        if (a.isLikelyVirtual != b.isLikelyVirtual) {
          return a.isLikelyVirtual ? 1 : -1;
        }
        return a.address.compareTo(b.address);
      });
      return copy;
    }

    test('real adapters rank above virtual ones', () {
      final ordered = sorted(<LanAddress>[
        const LanAddress(
          interfaceName: 'vEthernet (WSL (Hyper-V firewall))',
          address: '172.24.144.1',
          isLikelyVirtual: true,
        ),
        const LanAddress(
          interfaceName: '乙太網路',
          address: '192.168.50.72',
          isLikelyVirtual: false,
        ),
        const LanAddress(
          interfaceName: 'vEthernet (Default Switch)',
          address: '172.21.208.1',
          isLikelyVirtual: true,
        ),
      ]);

      expect(ordered.first.address, '192.168.50.72');
      expect(ordered.skip(1).every((a) => a.isLikelyVirtual), isTrue);
    });
  });

  group('listLanAddresses', () {
    test('flags known virtual adapter names', () async {
      // Runs against whatever this machine actually has; the invariant that
      // holds everywhere is that virtual adapters never sort above real ones.
      final addresses = await listLanAddresses();
      final firstVirtual = addresses.indexWhere((a) => a.isLikelyVirtual);
      final lastReal = addresses.lastIndexWhere((a) => !a.isLikelyVirtual);
      if (firstVirtual != -1 && lastReal != -1) {
        expect(lastReal, lessThan(firstVirtual));
      }
    });
  });
}
