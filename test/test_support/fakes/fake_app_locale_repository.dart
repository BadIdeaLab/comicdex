import 'package:concept_nhv/application/settings/app_locale_repository.dart';

class FakeAppLocaleRepository implements AppLocaleRepository {
  FakeAppLocaleRepository({String? initialOption})
    : _option = initialOption ?? AppLocaleRepository.systemOption;

  String _option;

  @override
  Future<String> loadLocaleOption() async => _option;

  @override
  Future<void> saveLocaleOption(String option) async {
    _option = option;
  }
}
