import 'package:concept_nhv/application/library/remove_comic_from_collection_use_case.dart';
import 'package:concept_nhv/application/library/save_comic_to_collection_use_case.dart';
import 'package:concept_nhv/models/collection_type.dart';
import 'package:concept_nhv/models/comic_card_data.dart';
import 'package:concept_nhv/storage/collection_repository.dart';
import 'package:concept_nhv/storage/comic_repository.dart';
import 'package:concept_nhv/storage/local_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late LocalDatabase localDatabase;
  late ComicRepository comicRepository;
  late CollectionRepository collectionRepository;
  late SaveComicToCollectionUseCase saveComicToCollectionUseCase;
  late RemoveComicFromCollectionUseCase removeComicFromCollectionUseCase;

  setUp(() async {
    localDatabase = LocalDatabase(
      executor: DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    await localDatabase.initialize();
    comicRepository = ComicRepository(localDatabase: localDatabase);
    collectionRepository = CollectionRepository(localDatabase: localDatabase);
    saveComicToCollectionUseCase = SaveComicToCollectionUseCase(
      comicRepository: comicRepository,
      collectionRepository: collectionRepository,
    );
    removeComicFromCollectionUseCase = RemoveComicFromCollectionUseCase(
      collectionRepository: collectionRepository,
    );
  });

  tearDown(() async {
    await localDatabase.resetForTesting();
  });

  test('saveComicToCollectionUseCase stores comic and membership', () async {
    final comic = ComicCardData(
      id: '55',
      mediaId: '9',
      title: 'Stored Comic',
      pages: 2,
      serializedImages: 'jj',
      thumbnailUrl: 'https://example.com/thumb.jpg',
      thumbnailWidth: 10,
      thumbnailHeight: 20,
    );

    await saveComicToCollectionUseCase.execute(
      comic: comic,
      targetCollection: CollectionType.next,
    );

    final ids = await collectionRepository.loadCollectedComicIds(
      CollectionType.next,
    );
    expect(ids, <String>{'55'});
  });

  test('removeComicFromCollectionUseCase removes membership', () async {
    final comic = ComicCardData(
      id: '55',
      mediaId: '9',
      title: 'Stored Comic',
      pages: 2,
      serializedImages: 'jj',
      thumbnailUrl: 'https://example.com/thumb.jpg',
      thumbnailWidth: 10,
      thumbnailHeight: 20,
    );
    await saveComicToCollectionUseCase.execute(
      comic: comic,
      targetCollection: CollectionType.next,
    );

    await removeComicFromCollectionUseCase.execute(
      collectionType: CollectionType.next,
      comicId: '55',
    );

    final ids = await collectionRepository.loadCollectedComicIds(
      CollectionType.next,
    );
    expect(ids, isEmpty);
  });
}
