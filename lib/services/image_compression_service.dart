import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

abstract class ImageCompressionService {
  Future<Uint8List> compressToWebp(Uint8List bytes, {int quality = 80});
}

class FlutterImageCompressionService implements ImageCompressionService {
  const FlutterImageCompressionService();

  @override
  Future<Uint8List> compressToWebp(Uint8List bytes, {int quality = 80}) {
    return FlutterImageCompress.compressWithList(
      bytes,
      format: CompressFormat.webp,
      quality: quality,
      keepExif: false,
    );
  }
}
