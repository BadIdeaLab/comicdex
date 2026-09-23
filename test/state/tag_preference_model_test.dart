import 'package:concept_nhv/application/tags/load_tag_cooccurrence_use_case.dart';
import 'package:concept_nhv/application/tags/load_tag_coverage_use_case.dart';
import 'package:concept_nhv/application/tags/load_tag_preferences_use_case.dart';
import 'package:concept_nhv/models/collection_type.dart';
import 'package:concept_nhv/models/local_tag_catalog_entry.dart';
import 'package:concept_nhv/models/tag_catalog_type.dart';
import 'package:concept_nhv/models/tag_preference_entry.dart';
import 'package:concept_nhv/services/local_tag_catalog_service.dart';
import 'package:concept_nhv/state/tag_preference_model.dart';
import 'package:concept_nhv/storage/options_store.dart';
import 'package:concept_nhv/storage/tag_preference_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_support/fakes/fake_blocked_tags_repository.dart';
import '../test_support/storage/sqlite_test_harness.dart';

void main() {
  group('TagPreferenceModel', () {
    late SqliteTestHarness harness;
    late TagPreferenceStore store;

    TagPreferenceModel buildModel() => TagPreferenceModel(
      loadTagPreferencesUseCase: LoadTagPreferencesUseCase(
        comicTagRepository: harness.comicTagRepository,
        localTagCatalogService:
            LocalTagCatalogService.fromEntries(const <LocalTagCatalogEntry>[
              LocalTagCatalogEntry(
                id: 10,
                type: TagCatalogType.tag,
                name: 'kept',
                slug: 'kept',
                count: 100,
              ),
            ]),
        blockedTagsRepository: FakeBlockedTagsRepository(),
      ),
      loadTagCooccurrenceUseCase: LoadTagCooccurrenceUseCase(
        comicTagRepository: harness.comicTagRepository,
        localTagCatalogService: LocalTagCatalogService.fromEntries(
          const <LocalTagCatalogEntry>[],
        ),
        blockedTagsRepository: FakeBlockedTagsRepository(),
      ),
      loadTagCoverageUseCase: LoadTagCoverageUseCase(
        comicTagRepository: harness.comicTagRepository,
      ),
      tagPreferenceStore: store,
    );

    setUp(() async {
      harness = SqliteTestHarness();
      await harness.initialize();
      store = TagPreferenceStore(
        optionsStore: OptionsStore(localDatabase: harness.localDatabase),
      );
      for (final id in <String>['1', '2', '3']) {
        await harness.comicTagRepository.replaceTagIds(id, <int>[10]);
        await harness.collectionRepository.addComicToCollection(
          collectionType: CollectionType.favorite,
          comicId: id,
        );
      }
    });

    tearDown(() async {
      await harness.dispose();
    });

    test('loads rankings and reports the loaded state', () async {
      final model = buildModel();
      expect(model.hasLoaded, isFalse);

      await model.load();

      expect(model.hasLoaded, isTrue);
      expect(model.isLoading, isFalse);
      expect(model.preferences[TagCatalogType.tag]!.single.comicCount, 3);
      model.dispose();
    });

    test('the combinations sort is independent and remembered', () async {
      final model = buildModel();
      await model.loadAnalysis();
      expect(model.sort, TagPreferenceSort.count);
      expect(model.combinationSort, TagPreferenceSort.affinity);

      // Changing one must not move the other: "my biggest tags" and "my most
      // unusual combinations" are different questions.
      await model.setCombinationSort(TagPreferenceSort.count);
      expect(model.sort, TagPreferenceSort.count);
      await model.setSort(TagPreferenceSort.affinity);
      expect(model.combinationSort, TagPreferenceSort.count);
      model.dispose();

      final rebuilt = buildModel();
      await rebuilt.loadAnalysis();
      expect(rebuilt.sort, TagPreferenceSort.affinity);
      expect(rebuilt.combinationSort, TagPreferenceSort.count);
      rebuilt.dispose();
    });

    test('remembers the sort across model instances', () async {
      final model = buildModel();
      await model.load();

      await model.setSort(TagPreferenceSort.affinity);
      model.dispose();

      final rebuilt = buildModel();
      await rebuilt.load();
      expect(rebuilt.sort, TagPreferenceSort.affinity);
      rebuilt.dispose();
    });
  });
}
