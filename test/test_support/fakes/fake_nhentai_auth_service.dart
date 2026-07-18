import 'package:concept_nhv/models/nhentai_api_credential.dart';
import 'package:concept_nhv/services/nhentai_auth_service.dart';
import 'package:concept_nhv/storage/nhentai_api_key_store.dart';

class FakeNhentaiAuthService extends NhentaiAuthService {
  FakeNhentaiAuthService(NhentaiApiKeyStore apiKeyStore)
    : _apiKeyStore = apiKeyStore,
      super(apiKeyStore: apiKeyStore);

  final NhentaiApiKeyStore _apiKeyStore;
  bool isValid = false;
  String username = 'tester';
  int clearCount = 0;

  @override
  Future<bool> validateStoredApiKey() async {
    return isValid;
  }

  @override
  Future<void> clearApiKey() async {
    clearCount += 1;
    isValid = false;
    await _apiKeyStore.clear();
  }

  @override
  Future<NhentaiApiCredential> saveAndValidateApiKey(String apiKey) async {
    if (apiKey.trim().isEmpty) {
      throw const NhentaiAuthException('API key cannot be empty.');
    }

    final credential = NhentaiApiCredential(
      apiKey: apiKey.trim(),
      username: username,
      lastValidatedAt: DateTime.now(),
    );
    isValid = true;
    await _apiKeyStore.save(credential);
    return credential;
  }
}
