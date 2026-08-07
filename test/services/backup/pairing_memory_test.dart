import 'dart:convert';
import 'dart:io';

import 'package:concept_nhv/services/backup/pairing_memory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('PairingMemory', () {
    late Directory support;
    late PairingMemory memory;

    setUp(() async {
      support = await Directory.systemTemp.createTemp('nhv-pairing-test');
      memory = PairingMemory(supportDirectory: () async => support);
    });

    tearDown(() async {
      if (support.existsSync()) {
        await support.delete(recursive: true);
      }
    });

    File file() => File(p.join(support.path, PairingMemory.fileName));

    test('returns nothing before anything has been paired', () async {
      expect(await memory.read(), isNull);
    });

    test('round-trips the address and device name', () async {
      await memory.remember(
        address: '192.168.1.20:8787',
        deviceName: 'Pixel-8',
      );

      final remembered = await memory.read();
      expect(remembered!.address, '192.168.1.20:8787');
      expect(remembered.deviceName, 'Pixel-8');
    });

    test(
      'never writes the PIN — it changes on every desktop restart, and storing '
      'it would turn pairing into permanent access for anything on this Wi-Fi',
      () async {
        await memory.remember(address: '10.0.0.5:8787', deviceName: 'Pixel-8');

        final raw = jsonDecode(await file().readAsString()) as Map<String, Object?>;
        expect(raw.keys, unorderedEquals(<String>['address', 'deviceName']));
        expect(raw.toString(), isNot(contains('pin')));
      },
    );

    test('overwrites the previous pairing rather than accumulating', () async {
      await memory.remember(address: 'first:1', deviceName: 'A');
      await memory.remember(address: 'second:2', deviceName: 'B');

      final remembered = await memory.read();
      expect(remembered!.address, 'second:2');
      expect(remembered.deviceName, 'B');
    });

    test('survives a corrupt file instead of blocking the screen', () async {
      await file().writeAsString('{ not json');

      expect(await memory.read(), isNull);
    });

    test('ignores an entry with no usable address', () async {
      await file().writeAsString(
        jsonEncode(<String, Object?>{'address': '', 'deviceName': 'A'}),
      );

      expect(await memory.read(), isNull);
    });
  });
}
