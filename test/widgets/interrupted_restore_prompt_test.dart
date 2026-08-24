import 'package:concept_nhv/l10n/app_localizations.dart';
import 'package:concept_nhv/services/backup/restore_progress_flag.dart';
import 'package:concept_nhv/widgets/interrupted_restore_prompt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('showInterruptedRestorePrompt', () {
    late InterruptedRestore? interrupted;
    late int acknowledgements;

    setUp(() {
      interrupted = null;
      acknowledgements = 0;
    });

    void markInterrupted() {
      interrupted = InterruptedRestore(
        sourceDeviceId: 'Old-Phone',
        startedAt: DateTime(2026, 8, 6),
      );
    }

    /// Mirrors what BootstrapScreen does: await the prompt, then `go` to the
    /// next location.
    ///
    /// The routing is not decoration. The bug this replaced was invisible to a
    /// test that pumped the prompt over a static child, because the thing that
    /// destroyed the dialog was `context.go` replacing the route stack. A test
    /// without a router proves the dialog can be built, not that the user can
    /// ever answer it.
    Future<void> pumpBootstrapFlow(
      WidgetTester tester, {
      required bool awaitPromptBeforeGo,
    }) async {
      final router = GoRouter(
        routes: <RouteBase>[
          GoRoute(
            path: '/',
            builder: (context, state) => _FakeBootstrapScreen(
              readInterrupted: () async => interrupted,
              onAcknowledged: () async => acknowledgements++,
              awaitPromptBeforeGo: awaitPromptBeforeGo,
            ),
          ),
          GoRoute(
            path: '/index',
            builder: (context, state) => const Scaffold(body: Text('library')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('stays out of the way when no restore was interrupted', (
      tester,
    ) async {
      await pumpBootstrapFlow(tester, awaitPromptBeforeGo: true);

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('library'), findsOneWidget);
    });

    testWidgets('survives the navigation that follows bootstrap', (
      tester,
    ) async {
      // The regression: the warning appeared and was wiped a frame later by
      // `context.go`, so it could never be answered.
      markInterrupted();

      await pumpBootstrapFlow(tester, awaitPromptBeforeGo: true);

      expect(
        find.byType(AlertDialog),
        findsOneWidget,
        reason: 'the warning must still be on screen once bootstrap finishes',
      );
      expect(
        find.text('library'),
        findsNothing,
        reason: 'navigation must wait for an answer',
      );
    });

    testWidgets('fails to survive if bootstrap navigates without waiting', (
      tester,
    ) async {
      // The inverse, kept deliberately: if this ever stops reproducing, the
      // test above proves nothing, because it would pass either way.
      markInterrupted();

      await pumpBootstrapFlow(tester, awaitPromptBeforeGo: false);

      expect(
        find.byType(AlertDialog),
        findsNothing,
        reason: 'go() replaces the stack and takes the dialog route with it',
      );
      expect(find.text('library'), findsOneWidget);
    });

    testWidgets('clears the flag and moves on once acknowledged', (
      tester,
    ) async {
      markInterrupted();
      await pumpBootstrapFlow(tester, awaitPromptBeforeGo: true);

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(acknowledgements, 1);
      expect(find.text('library'), findsOneWidget);
    });

    testWidgets('keeps the flag when dismissed, and still moves on', (
      tester,
    ) async {
      // Dismissing does not make the library consistent again, so the warning
      // has to come back next launch.
      markInterrupted();
      await pumpBootstrapFlow(tester, awaitPromptBeforeGo: true);

      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();

      expect(acknowledgements, 0);
      expect(find.text('library'), findsOneWidget);
    });

    testWidgets('cannot be dismissed by tapping outside', (tester) async {
      markInterrupted();
      await pumpBootstrapFlow(tester, awaitPromptBeforeGo: true);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });
}

/// Stands in for BootstrapScreen: prompt, then navigate.
class _FakeBootstrapScreen extends StatefulWidget {
  const _FakeBootstrapScreen({
    required this.readInterrupted,
    required this.onAcknowledged,
    required this.awaitPromptBeforeGo,
  });

  final Future<InterruptedRestore?> Function() readInterrupted;
  final Future<void> Function() onAcknowledged;

  /// False reproduces the old ordering, where navigation did not wait.
  final bool awaitPromptBeforeGo;

  @override
  State<_FakeBootstrapScreen> createState() => _FakeBootstrapScreenState();
}

class _FakeBootstrapScreenState extends State<_FakeBootstrapScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    final prompt = showInterruptedRestorePrompt(
      context,
      readInterrupted: widget.readInterrupted,
      onAcknowledged: widget.onAcknowledged,
    );
    if (widget.awaitPromptBeforeGo) {
      await prompt;
    }
    if (!mounted) return;
    GoRouter.of(context).go('/index');
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Text('Loading index...'));
}
