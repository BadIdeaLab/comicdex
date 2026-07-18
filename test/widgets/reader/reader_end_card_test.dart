import 'package:concept_nhv/widgets/reader/reader_end_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReaderEndCard', () {
    testWidgets('shows "The End" text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ReaderEndCard(visible: true)),
      );

      expect(find.text('The End'), findsOneWidget);
    });

    testWidgets('is fully opaque when visible is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ReaderEndCard(visible: true)),
      );

      final opacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(opacity.opacity, 1.0);
    });

    testWidgets('is fully transparent when visible is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ReaderEndCard(visible: false)),
      );

      final opacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(opacity.opacity, 0.0);
    });
  });
}
