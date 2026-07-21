import 'package:concept_nhv/application/settings/app_locale_repository.dart';
import 'package:concept_nhv/storage/options_store.dart';

class AppLocaleStore implements AppLocaleRepository {
  const AppLocaleStore({required this.optionsStore});

  final OptionsStore optionsStore;

  static const String _localeKey = 'app_locale_option';

  @override
  Future<String> loadLocaleOption() async {
    final raw = await optionsStore.loadOption(_localeKey);
    if (raw.isEmpty) {
      return AppLocaleRepository.systemOption;
    }
    return raw;
  }

  @override
  Future<void> saveLocaleOption(String option) {
    return optionsStore.saveOption(_localeKey, option);
  }
}
