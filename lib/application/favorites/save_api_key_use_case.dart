import 'package:concept_nhv/services/nhentai_auth_service.dart';

class SaveApiKeyUseCase {
  const SaveApiKeyUseCase({required this.authService});

  final NhentaiAuthService authService;

  Future<void> execute(String apiKey) async {
    await authService.saveAndValidateApiKey(apiKey);
  }
}
