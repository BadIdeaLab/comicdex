import 'dart:ui';

/// Provides localized display names for nhentai tag types.
///
/// Tag types returned by the API: tag, artist, parody, character,
/// group, language, category.
class TagTypeL10n {
  const TagTypeL10n._();

  static const Map<String, Map<String, String>> _translations = <String, Map<String, String>>{
    'tag': <String, String>{
      'zh': '標籤',
      'ja': 'タグ',
      'en': 'Tag',
    },
    'artist': <String, String>{
      'zh': '作者',
      'ja': '作者',
      'en': 'Artist',
    },
    'parody': <String, String>{
      'zh': '原作',
      'ja': 'パロディ',
      'en': 'Parody',
    },
    'character': <String, String>{
      'zh': '角色',
      'ja': 'キャラクター',
      'en': 'Character',
    },
    'group': <String, String>{
      'zh': '社團',
      'ja': 'グループ',
      'en': 'Group',
    },
    'language': <String, String>{
      'zh': '語言',
      'ja': '言語',
      'en': 'Language',
    },
    'category': <String, String>{
      'zh': '分類',
      'ja': 'カテゴリー',
      'en': 'Category',
    },
  };

  /// Returns the localized name for a tag type based on the system locale.
  ///
  /// Falls back to English if no translation is found.
  static String localizedName(String type, Locale locale) {
    final translations = _translations[type.toLowerCase()];
    if (translations == null) return _capitalize(type);

    final langCode = locale.languageCode.toLowerCase();
    return translations[langCode] ?? translations['en'] ?? _capitalize(type);
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
