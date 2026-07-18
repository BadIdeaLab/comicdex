import 'package:concept_nhv/models/nhentai_api_credential.dart';
import 'package:concept_nhv/storage/nhentai_api_key_store.dart';
import 'package:dio/dio.dart';

class NhentaiAuthException implements Exception {
  const NhentaiAuthException(this.message);

  final String message;

  @override
  String toString() => 'NhentaiAuthException($message)';
}

class NhentaiAuthService {
  NhentaiAuthService({required this.apiKeyStore, Dio? dio})
    : _dio = dio ?? Dio();

  final NhentaiApiKeyStore apiKeyStore;
  final Dio _dio;

  Future<NhentaiApiCredential> loadCredential() {
    return apiKeyStore.load();
  }

  Future<bool> hasStoredApiKey() async {
    final credential = await apiKeyStore.load();
    return !credential.isEmpty;
  }

  Future<NhentaiApiCredential> saveAndValidateApiKey(String apiKey) async {
    final trimmedApiKey = apiKey.trim();
    if (trimmedApiKey.isEmpty) {
      throw const NhentaiAuthException('API key cannot be empty.');
    }

    final username = await _loadUsername(trimmedApiKey);
    final credential = NhentaiApiCredential(
      apiKey: trimmedApiKey,
      username: username,
      lastValidatedAt: DateTime.now(),
    );
    await apiKeyStore.save(credential);
    return credential;
  }

  Future<bool> validateStoredApiKey() async {
    final credential = await apiKeyStore.load();
    if (credential.isEmpty) {
      return false;
    }

    try {
      final username = await _loadUsername(credential.apiKey);
      await apiKeyStore.save(
        credential.copyWith(
          username: username,
          lastValidatedAt: DateTime.now(),
        ),
      );
      return true;
    } on NhentaiAuthException {
      return false;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        return false;
      }
      return false;
    }
  }

  Future<void> clearApiKey() {
    return apiKeyStore.clear();
  }

  Future<String> _loadUsername(String apiKey) async {
    try {
      final response = await _dio.getUri<Map<String, dynamic>>(
        Uri.https('nhentai.net', '/api/v2/user'),
        options: Options(headers: <String, String>{
          'Authorization': 'Key $apiKey',
        }),
      );
      final username = response.data?['username'] as String?;
      if (username == null || username.trim().isEmpty) {
        throw const NhentaiAuthException('API key validation returned no user.');
      }
      return username;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        throw const NhentaiAuthException('Invalid API key.');
      }
      throw const NhentaiAuthException('Failed to validate API key.');
    }
  }
}
