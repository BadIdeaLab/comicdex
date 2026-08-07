import 'package:concept_nhv/l10n/app_localizations.dart';
import 'package:concept_nhv/services/backup/restore_progress_flag.dart';
import 'package:concept_nhv/widgets/interrupted_restore_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InterruptedRestoreGate', () {
    late InterruptedRestore? interrupted;
    late int acknowledgements;

    setUp(() {
      interrupted = null;
      acknowledgements = 0;
    });

    Future<void> pump(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: InterruptedRestoreGate(
            readInterrupted: () async => interrupted,
            onAcknowledged: () async => acknowledgements++,
            child: const Scaffold(body: Text('library')),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    void markInterrupted() {
      interrupted = InterruptedRestore(
        sourceDeviceId: 'Old-Phone',
        startedAt: DateTime(2026, 8, 6),
      );
    }

    testWidgets('stays out of the way when no restore was interrupted', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text('library'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets(
      'warns on launch when a restore never finished, naming the source so the '
      'user knows which backup to re-run',
      (tester) async {
        markInterrupted();

        await pump(tester);

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.textContaining('Old-Phone'), findsOneWidget);
      },
    );

    testWidgets(
      'keeps the flag when only dismissed — closing the dialog does not make '
      'the library consistent again',
      (tester) async {
        markInterrupted();
        await pump(tester);

        await tester.tap(find.text('Remind me again'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        expect(acknowledgements, 0);
      },
    );

    testWidgets('clears the flag once explicitly acknowledged', (tester) async {
      markInterrupted();
      await pump(tester);

      await tester.tap(find.text('I understand'));
      await tester.pumpAndSettle();

      expect(acknowledgements, 1);
    });

    testWidgets(
      'still warns when placed above the navigator, as MaterialApp.builder '
      'does — that context has no Navigator, so showDialog needs the router key',
      (tester) async {
        markInterrupted();
        final navigatorKey = GlobalKey<NavigatorState>();

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            navigatorKey: navigatorKey,
            // Reproduces the real placement. The earlier tests used `home:`,
            // which puts the gate *below* the navigator and hid this failure
            // entirely: in the app the dialog silently never appeared.
            builder: (context, child) {
              return InterruptedRestoreGate(
                readInterrupted: () async => interrupted,
                onAcknowledged: () async => acknowledgements++,
                dialogContext: () => navigatorKey.currentContext,
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const Scaffold(body: Text('library')),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.textContaining('Old-Phone'), findsOneWidget);
      },
    );

    testWidgets('cannot be dismissed by tapping outside', (tester) async {
      markInterrupted();
      await pump(tester);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });
}
