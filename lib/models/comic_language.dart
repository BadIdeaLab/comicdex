enum ComicLanguage {
  all,
  chinese,
  japanese,
  english;

  String get apiQuery {
    switch (this) {
      case ComicLanguage.all:
        return '';
      case ComicLanguage.chinese:
        return 'language:chinese';
      case ComicLanguage.japanese:
        return 'language:japanese';
      case ComicLanguage.english:
        return 'language:english';
    }
  }

  List<String> get fallbackQueries {
    switch (this) {
      case ComicLanguage.all:
        return const [];
      case ComicLanguage.chinese:
        return const ['-language:english -language:japanese'];
      case ComicLanguage.japanese:
      case ComicLanguage.english:
        return const [];
    }
  }

  String get displayName {
    switch (this) {
      case ComicLanguage.all:
        return 'All';
      case ComicLanguage.chinese:
        return 'Chinese';
      case ComicLanguage.japanese:
        return 'Japanese';
      case ComicLanguage.english:
        return 'English';
    }
  }
}
