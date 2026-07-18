import 'package:concept_nhv/widgets/reader/reader_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatFavorites', () {
    test('formats small counts as-is', () {
      expect(formatFavorites(345), '345');
    });

    test('formats thousands with one decimal and k suffix', () {
      expect(formatFavorites(12345), '12.3k');
    });

    test('formats millions with one decimal and M suffix', () {
      expect(formatFavorites(1234567), '1.2M');
    });

    test('formats null or zero as 0', () {
      expect(formatFavorites(null), '0');
      expect(formatFavorites(0), '0');
    });
  });

  group('ReaderTopBar', () {
    testWidgets('shows current / total page indicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReaderTopBar(visible: true, currentPage: 3, totalPages: 10),
        ),
      );

      expect(find.text('3 / 10'), findsOneWidget);
    });

    testWidgets('shows formatted favorites count when provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReaderTopBar(
            visible: true,
            currentPage: 1,
            totalPages: 1,
            numFavorites: 12345,
          ),
        ),
      );

      expect(find.text('12.3k'), findsOneWidget);
    });

    testWidgets('hides favorites row when numFavorites is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReaderTopBar(visible: true, currentPage: 1, totalPages: 1),
        ),
      );

      expect(find.byIcon(Icons.favorite), findsNothing);
    });

    testWidgets('fades out when visible is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReaderTopBar(visible: false, currentPage: 1, totalPages: 1),
        ),
      );

      final opacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(opacity.opacity, 0.0);
    });

    testWidgets('fades in when visible is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReaderTopBar(visible: true, currentPage: 1, totalPages: 1),
        ),
      );

      final opacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(opacity.opacity, 1.0);
    });
  });
}
