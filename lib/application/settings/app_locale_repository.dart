/// Repository interface for persisting the user's chosen app display
/// language, independent of any comic search language filter.
abstract class AppLocaleRepository {
  /// Stored option value meaning "follow the system language".
  static const String systemOption = 'system';

  /// Returns the persisted option (`'system'`, or a locale code such as
  /// `'en'` / `'zh_Hant'`), or [systemOption] if nothing has been saved yet.
  Future<String> loadLocaleOption();

  /// Persists the chosen option.
  Future<void> saveLocaleOption(String option);
}
