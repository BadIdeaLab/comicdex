abstract class ReaderProgressRepository {
  Future<void> saveLastSeenOffset(String comicId, double offset);

  Future<double?> loadLastSeenOffset(String comicId);
}
