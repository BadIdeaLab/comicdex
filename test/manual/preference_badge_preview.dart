@Tags(<String>['manual'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:concept_nhv/application/tags/tag_preference_vector.dart';
import 'package:concept_nhv/widgets/preference_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders both badge tiers over covers of different brightness and writes a
/// PNG, because "does the holographic sheen read as platinum or as mud" is not
/// a question code review can answer (P84).
///
/// Run with the output path of your choice:
///
/// ```
/// flutter test test/manual/preference_badge_preview.dart \
///   --dart-define=PREVIEW_OUT=build/preference_badge.png
/// ```
void main() {
  setUpAll(() async {
    // Widget tests ship no glyphs: without this every icon renders as the
    // missing-glyph box, which is exactly the thing this preview exists to
    // look at. Point it at the SDK copy:
    // --dart-define=ICON_FONT=<flutter>/bin/cache/artifacts/material_fonts/materialicons-regular.otf
    const fontPath = String.fromEnvironment('ICON_FONT');
    if (fontPath.isEmpty) return;
    await _loadFont('MaterialIcons', fontPath);
    // The row labels come from the same cache directory; without a text font
    // they render as boxes too, leaving the preview unlabelled.
    final textFont = File(fontPath).parent.uri.resolve('roboto-regular.ttf');
    if (File.fromUri(textFont).existsSync()) {
      await _loadFont('Roboto', textFont.toFilePath());
    }
  });

  testWidgets('renders the badge tiers over a range of covers', (tester) async {
    const outPath = String.fromEnvironment(
      'PREVIEW_OUT',
      defaultValue: 'build/preference_badge.png',
    );

    const backgrounds = <(String, Color)>[
      ('white cover', Color(0xFFFFFFFF)),
      ('pale cover', Color(0xFFF3DCE4)),
      ('mid cover', Color(0xFF7C8AA0)),
      ('dark cover', Color(0xFF14161C)),
    ];

    const previewKey = Key('preference-badge-preview');

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Roboto'),
        // Aligned so the boundary shrink-wraps the swatches instead of
        // capturing a screen of empty background around them.
        home: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: previewKey,
            child: ColoredBox(
              color: const Color(0xFF2A2D34),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    for (final tier in <PreferenceTier>[
                      PreferenceTier.platinum,
                      PreferenceTier.gold,
                    ]) ...<Widget>[
                      Text(
                        tier.name,
                        // Named explicitly: a widget test renders any text in
                        // its own placeholder font — solid boxes — unless the
                        // style asks for a family that was loaded.
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          for (final background in backgrounds)
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: SizedBox(
                                width: 64,
                                height: 88,
                                child: Stack(
                                  children: <Widget>[
                                    Positioned.fill(
                                      child: ColoredBox(color: background.$2),
                                    ),
                                    PreferenceBadge(tier: tier),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final boundary =
        tester.renderObject(find.byKey(previewKey)) as RenderRepaintBoundary;
    // Inside runAsync: encoding a picture is genuinely asynchronous work, and
    // the fake async zone a widget test runs in never lets it complete.
    final file = File(outPath);
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 6);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(bytes!.buffer.asUint8List());
    });

    // ignore: avoid_print
    print('wrote ${file.absolute.path}');
  });
}

Future<void> _loadFont(String family, String path) async {
  final loader = FontLoader(family)
    ..addFont(
      File(path).readAsBytes().then((bytes) => bytes.buffer.asByteData()),
    );
  await loader.load();
}
