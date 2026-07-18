import 'package:concept_nhv/storage/local_database.dart';
import 'package:drift/drift.dart' as drift;

class OptionsStore {
  const OptionsStore({required this.localDatabase});

  final LocalDatabase localDatabase;

  Future<void> saveOption(String name, String value) async {
    await localDatabase.into(localDatabase.appOptions).insert(
      AppOptionsCompanion.insert(
        id: drift.Value.absent(),
        name: name,
        value: value,
      ),
      mode: drift.InsertMode.insertOrReplace,
    );
  }

  Future<String> loadOption(String name) async {
    final query =
        localDatabase.select(localDatabase.appOptions)
          ..where((table) => table.name.equals(name))
          ..limit(1);
    final option = await query.getSingleOrNull();
    if (option == null) {
      return '';
    }
    return option.value;
  }

  Future<int> deleteOptions(Iterable<String> names) async {
    final nameList = names.toList(growable: false);
    if (nameList.isEmpty) {
      return 0;
    }

    final statement = localDatabase.delete(localDatabase.appOptions)
      ..where((table) => table.name.isIn(nameList));
    return statement.go();
  }
}
