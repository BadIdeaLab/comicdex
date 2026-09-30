import 'package:concept_nhv/application/tracking/tracking_cooldown.dart';
import 'package:concept_nhv/storage/options_store.dart';

/// Persists the one value the update checker's cooldown is made of.
///
/// Persisted rather than held in memory because the thing it mainly defends
/// against is the app being opened again: a cooldown that forgets on restart
/// would let every cold start fire a run.
class TrackingStateStore {
  const TrackingStateStore({required this.optionsStore});

  final OptionsStore optionsStore;

  static const String _nextRunAtKey = 'tracking_next_run_at';
  static const String _imposedByServerKey = 'tracking_cooldown_from_server';

  Future<TrackingCooldown> load() async {
    final raw = await optionsStore.loadOption(_nextRunAtKey);
    final nextRunAt = DateTime.tryParse(raw);
    if (nextRunAt == null) {
      return const TrackingCooldown.none();
    }
    final imposed = await optionsStore.loadOption(_imposedByServerKey);
    return TrackingCooldown(
      nextRunAt: nextRunAt,
      imposedByServer: imposed.toLowerCase() == 'true',
    );
  }

  Future<void> save(TrackingCooldown cooldown) async {
    final nextRunAt = cooldown.nextRunAt;
    if (nextRunAt == null) {
      await optionsStore.deleteOptions(<String>[
        _nextRunAtKey,
        _imposedByServerKey,
      ]);
      return;
    }
    // Stored as UTC: the device's zone can change between runs, and a naive
    // local timestamp would then name a different moment than it did when it
    // was written.
    await optionsStore.saveOption(
      _nextRunAtKey,
      nextRunAt.toUtc().toIso8601String(),
    );
    await optionsStore.saveOption(
      _imposedByServerKey,
      cooldown.imposedByServer.toString(),
    );
  }
}
