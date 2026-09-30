import 'dart:async';

import 'package:flutter/widgets.dart';

/// How often the foreground asks whether an update check may run.
///
/// Short on purpose. It is not a second pacing mechanism — [TrackingCooldown]
/// decides whether anything is actually sent, and refuses most of these — so
/// this only needs to be often enough that a long session does not sit idle
/// through a cooldown that has already lifted.
const Duration kTrackingTickInterval = Duration(minutes: 15);

/// Calls [onTick] periodically while the app is in the foreground.
///
/// Separated from the model it drives because timers and lifecycle callbacks
/// are the hardest thing here to test, and the state they drive is the
/// easiest: together, both become hard.
///
/// **Stops in the background, on purpose.** A timer left running there is
/// background polling, which this phase deliberately does not do — and which
/// the platform would kill on its own schedule anyway, making the behaviour
/// impossible to reason about.
class ForegroundTicker with WidgetsBindingObserver {
  ForegroundTicker({
    required this.onTick,
    this.interval = kTrackingTickInterval,
  });

  final Future<void> Function() onTick;
  final Duration interval;

  Timer? _timer;
  bool _started = false;

  /// Begins ticking, and starts watching for the app going away.
  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _schedule();
  }

  void dispose() {
    _cancel();
    if (_started) {
      WidgetsBinding.instance.removeObserver(this);
      _started = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_started) return;
    if (state == AppLifecycleState.resumed) {
      _schedule();
    } else {
      _cancel();
    }
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => onTick());
  }

  void _cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Whether a tick is currently scheduled. For tests: whether the timer is
  /// running is the whole behaviour, and it is otherwise invisible.
  @visibleForTesting
  bool get isTicking => _timer != null;
}
