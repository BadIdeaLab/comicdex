import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the one localisation mistake that is invisible at runtime.
///
/// A key missing from a locale does not fail the build or the analyzer — the
/// generated class just falls back to the English template, so that one
/// string quietly stays in English. On a screen that is otherwise translated
/// it is easy to miss for a long time.
void main() {
  Set<String> keysOf(String path) {
    final decoded =
        jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
    return decoded.keys.where((key) => !key.startsWith('@')).toSet();
  }

  test('zh_Hant translates every key in the English template', () {
    final template = keysOf('lib/l10n/app_en.arb');
    final traditional = keysOf('lib/l10n/app_zh_Hant.arb');

    expect(
      traditional.difference(template),
      isEmpty,
      reason: 'zh_Hant has keys the template does not define',
    );
    expect(
      template.difference(traditional),
      isEmpty,
      reason: 'these keys would silently render in English under zh_Hant',
    );
  });

  test('zh is deliberately allowed to lag behind', () {
    // Not an oversight to be "fixed": the app's user reads Traditional
    // Chinese, so Simplified is not worth hand-translating twice over
    // (P88). It falls back to English, which is the accepted cost. If
    // Simplified ever matters, translate it and fold it into the test above.
    final template = keysOf('lib/l10n/app_en.arb');
    final simplified = keysOf('lib/l10n/app_zh.arb');

    expect(
      simplified.difference(template),
      isEmpty,
      reason: 'zh has keys the template does not define',
    );
  });
}
