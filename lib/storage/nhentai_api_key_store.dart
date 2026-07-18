import 'package:concept_nhv/models/nhentai_api_credential.dart';
import 'package:concept_nhv/storage/secure_key_value_store.dart';

class NhentaiApiKeyStore {
  const NhentaiApiKeyStore({required this.secureStore});

  static const String _apiKeyKey = 'nhentai-api-key';
  static const String _usernameKey = 'nhentai-api-username';
  static const String _lastValidatedAtKey = 'nhentai-api-last-validated-at';

  final SecureKeyValueStore secureStore;

  Future<NhentaiApiCredential> load() async {
    final apiKey = await secureStore.read(_apiKeyKey) ?? '';
    if (apiKey.trim().isEmpty) {
      return NhentaiApiCredential.empty;
    }

    final username = await secureStore.read(_usernameKey);
    final lastValidatedAtRaw = await secureStore.read(_lastValidatedAtKey);
    return NhentaiApiCredential(
      apiKey: apiKey,
      username: username,
      lastValidatedAt: lastValidatedAtRaw == null
          ? null
          : DateTime.tryParse(lastValidatedAtRaw),
    );
  }

  Future<void> save(NhentaiApiCredential credential) async {
    await secureStore.write(_apiKeyKey, credential.apiKey);
    if ((credential.username ?? '').trim().isEmpty) {
      await secureStore.delete(_usernameKey);
    } else {
      await secureStore.write(_usernameKey, credential.username!);
    }

    if (credential.lastValidatedAt == null) {
      await secureStore.delete(_lastValidatedAtKey);
    } else {
      await secureStore.write(
        _lastValidatedAtKey,
        credential.lastValidatedAt!.toIso8601String(),
      );
    }
  }

  Future<void> clear() async {
    await secureStore.delete(_apiKeyKey);
    await secureStore.delete(_usernameKey);
    await secureStore.delete(_lastValidatedAtKey);
  }
}
