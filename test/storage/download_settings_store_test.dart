import 'package:concept_nhv/application/downloads/download_settings_repository.dart';
import 'package:concept_nhv/storage/download_settings_store.dart';
import 'package:concept_nhv/storage/options_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_support/storage/sqlite_test_harness.dart';

void main() {
  group('DownloadSettingsStore', () {
    late SqliteTestHarness harness;
    late DownloadSettingsStore store;

    setUp(() async {
      harness = SqliteTestHarness();
      await harness.initialize();
      store = DownloadSettingsStore(
        optionsStore: OptionsStore(localDatabase: harness.localDatabase),
      );
    });

    tearDown(() async {
      await harness.dispose();
    });

    test('returns defaults when no settings are stored', () async {
      expect(
        await store.loadAutoResumeEnabled(),
        DownloadSettingsRepository.defaultAutoResumeEnabled,
      );
      expect(
        await store.loadPageIntervalMs(),
        DownloadSettingsRepository.defaultPageIntervalMs,
      );
    });

    test('persists and clamps the page interval setting', () async {
      await store.saveAutoResumeEnabled(false);
      await store.savePageIntervalMs(99999);

      expect(await store.loadAutoResumeEnabled(), isFalse);
      expect(
        await store.loadPageIntervalMs(),
        DownloadSettingsRepository.maxPageIntervalMs,
      );
    });
  });
}
