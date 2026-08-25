import 'dart:io';

import 'package:concept_nhv/services/backup/backup_client.dart';
import 'package:concept_nhv/services/backup/pairing_connect_attempt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('orderedConnectionCandidates', () {
    test('puts the visible address first', () {
      // Whatever the user can see in the field is what they expect to be used;
      // a scanned code must not silently override an edit.
      expect(
        orderedConnectionCandidates(
          typed: '10.0.0.9:6890',
          fromPairingCode: <String>['192.168.50.72:6890', '192.168.137.1:6890'],
        ),
        <String>['10.0.0.9:6890', '192.168.50.72:6890', '192.168.137.1:6890'],
      );
    });

    test('does not try the same address twice', () {
      expect(
        orderedConnectionCandidates(
          typed: '192.168.50.72:6890',
          fromPairingCode: <String>['192.168.50.72:6890', '192.168.137.1:6890'],
        ),
        <String>['192.168.50.72:6890', '192.168.137.1:6890'],
      );
    });

    test('a typed address with no pairing code is a list of one', () {
      // Manual entry runs the same code path as scanning, so there is only one
      // connect flow to reason about.
      expect(
        orderedConnectionCandidates(
          typed: '10.0.0.9:6890',
          fromPairingCode: const <String>[],
        ),
        <String>['10.0.0.9:6890'],
      );
    });
  });

  group('connectToFirstReachable', () {
    test('stops at the first address that answers', () async {
      final tried = <String>[];

      final used = await connectToFirstReachable(
        candidates: <String>['a', 'b', 'c'],
        attempt: (address) async {
          tried.add(address);
          if (address != 'b') throw const SocketException('no route');
        },
      );

      expect(used, 'b');
      expect(tried, <String>['a', 'b'], reason: 'c never needed trying');
    });

    test('moves on when an address is simply unreachable', () async {
      final tried = <String>[];

      await connectToFirstReachable(
        candidates: <String>['vpn', 'hyperv', 'lan'],
        attempt: (address) async {
          tried.add(address);
          if (address != 'lan') throw const SocketException('no route');
        },
      );

      expect(tried, <String>['vpn', 'hyperv', 'lan']);
    });

    test('gives up immediately when the server answers and refuses', () async {
      // The desktop is there. Trying the rest would reproduce the same refusal
      // more slowly and then report a misleading "cannot reach" at the end.
      final tried = <String>[];

      await expectLater(
        connectToFirstReachable(
          candidates: <String>['lan', 'hotspot'],
          attempt: (address) async {
            tried.add(address);
            throw const BackupServerException(
              HttpStatus.unauthorized,
              'Invalid PIN',
            );
          },
        ),
        throwsA(isA<BackupServerException>()),
      );

      expect(
        tried,
        <String>['lan'],
        reason: 'a wrong PIN is not a reason to try another address',
      );
    });

    test('a rejected device name also stops the search', () async {
      final tried = <String>[];

      await expectLater(
        connectToFirstReachable(
          candidates: <String>['lan', 'hotspot'],
          attempt: (address) async {
            tried.add(address);
            throw const BackupPairingRejectedException('bad device name');
          },
        ),
        throwsA(isA<BackupPairingRejectedException>()),
      );

      expect(tried, <String>['lan']);
    });

    test('reports each attempt so a long search does not look like a hang', () async {
      // The slow path is several TCP timeouts in a row. Without this the app
      // just appears frozen, and the user cannot tell searching from crashed.
      final reported = <String>[];

      await connectToFirstReachable(
        candidates: <String>['vpn', 'hyperv', 'lan'],
        onAttempt: (address, attempt, total) =>
            reported.add('$address $attempt/$total'),
        attempt: (address) async {
          if (address != 'lan') throw const SocketException('no route');
        },
      );

      expect(reported, <String>[
        'vpn 1/3',
        'hyperv 2/3',
        'lan 3/3',
      ]);
    });

    test('rethrows the last failure when nothing was reachable', () async {
      // The caller still needs something specific to show.
      await expectLater(
        connectToFirstReachable(
          candidates: <String>['a', 'b'],
          attempt: (_) async => throw const SocketException('no route'),
        ),
        throwsA(isA<SocketException>()),
      );
    });
  });
}
