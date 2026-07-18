import 'package:concept_nhv/application/library/library_item.dart';
import 'package:concept_nhv/application/library/library_section.dart';

abstract class LibraryRepository {
  Future<List<LibrarySection>> loadAvailableSections();

  Future<List<LibraryItem>> loadSectionItems(LibrarySection section);
}
