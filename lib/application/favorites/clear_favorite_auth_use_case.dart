import 'package:concept_nhv/services/nhentai_auth_service.dart';

class ClearFavoriteAuthUseCase {
  const ClearFavoriteAuthUseCase({required this.authService});

  final NhentaiAuthService authService;

  Future<void> execute() {
    return authService.clearApiKey();
  }
}
