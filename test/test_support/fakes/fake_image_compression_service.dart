import 'dart:typed_data';

import 'package:concept_nhv/services/image_compression_service.dart';

class FakeImageCompressionService implements ImageCompressionService {
  FakeImageCompressionService({
    this.result,
    this.error,
  });

  final Uint8List? result;
  final Object? error;
  int callCount = 0;

  @override
  Future<Uint8List> compressToWebp(Uint8List bytes, {int quality = 80}) async {
    callCount += 1;
    if (error != null) {
      throw error!;
    }
    return result ?? Uint8List.fromList(<int>[...bytes, 87]);
  }
}
