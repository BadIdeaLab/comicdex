import 'package:concept_nhv/application/reader/reader_progress_repository.dart';
import 'package:concept_nhv/storage/options_store.dart';

class ReaderProgressStore implements ReaderProgressRepository {
  const ReaderProgressStore({required this.optionsStore});

  final OptionsStore optionsStore;

  @override
  Future<double?> loadLastSeenOffset(String comicId) async {
    final value = await optionsStore.loadOption('lastSeenOffset-$comicId');
    if (value.isEmpty) {
      return null;
    }
    return double.tryParse(value);
  }

  @override
  Future<void> saveLastSeenOffset(String comicId, double offset) {
    return optionsStore.saveOption('lastSeenOffset-$comicId', offset.toString());
  }
}
