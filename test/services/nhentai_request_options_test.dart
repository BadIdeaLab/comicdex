import 'dart:io';

import 'package:concept_nhv/services/nhentai_request_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('request timeouts', () {
    test('the shared options set all three', () {
      // Dio's own default is none of them, so anything built without these
      // waits for the operating system to give up.
      expect(nhentaiRequestOptions.connectTimeout, isNotNull);
      expect(nhentaiRequestOptions.receiveTimeout, isNotNull);
      expect(nhentaiRequestOptions.sendTimeout, isNotNull);
    });

    test('nothing under lib/ builds a Dio without them', () {
      // Read from source rather than from the objects, because the
      // alternative is a `debugDio` getter on six production classes that
      // exists only so this test can look at them.
      //
      // Four services each had a bare `Dio()` and therefore no timeout at
      // all. The one behind the CDN config is awaited at the top of every
      // search, which is how an unreachable site turned into an app that
      // would not finish starting.
      // Not preceded by an identifier character, so `_buildDio()` — which
      // returns a Dio with timeouts of its own — is not a match.
      final bareDio = RegExp(r'(?<![A-Za-z0-9_])Dio\(\)');
      final offenders = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        for (final line in entity.readAsLinesSync()) {
          final code = line.split('//').first;
          if (bareDio.hasMatch(code)) {
            offenders.add(entity.path);
            break;
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'a bare Dio() has no timeouts; pass nhentaiRequestOptions, or '
            'BaseOptions of its own if this one talks to something else',
      );
    });
  });
}
