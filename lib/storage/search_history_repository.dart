import 'package:concept_nhv/models/search_history_entry.dart';
import 'package:concept_nhv/storage/local_database.dart';
import 'package:drift/drift.dart' as drift;

class SearchHistoryRepository {
  const SearchHistoryRepository({required this.localDatabase});

  final LocalDatabase localDatabase;

  Future<void> save(String query) async {
    await localDatabase.into(localDatabase.searchHistories).insert(
      SearchHistoriesCompanion.insert(
        id: drift.Value.absent(),
        query: query,
      ),
    );
  }

  Future<List<SearchHistoryEntry>> load() async {
    final query = localDatabase.select(localDatabase.searchHistories)
      ..orderBy([
        (table) => drift.OrderingTerm.desc(table.createdAt),
      ]);
    final rows = await query.get();
    return rows.map((row) {
      return SearchHistoryEntry(
        query: row.query,
        createdAt: DateTime.parse('${row.createdAt}Z').toLocal(),
      );
    }).toList();
  }

  Future<void> remove(String query) async {
    final statement = localDatabase.delete(localDatabase.searchHistories)
      ..where((table) => table.query.equals(query));
    await statement.go();
  }
}
