import 'dart:convert';
import 'package:flutter/services.dart';

class TagDisplayService {
  TagDisplayService._(this._zhMap);

  TagDisplayService.fromMap(Map<String, String> map) : _zhMap = Map.unmodifiable(map);

  final Map<String, String> _zhMap;

  static Future<TagDisplayService> load() async {
    final byteData = await rootBundle.load('assets/tag_zh.bin');
    final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
    const key = 0x42;
    final decoded = Uint8List.fromList(bytes.map((b) => b ^ key).toList());
    final jsonStr = utf8.decode(decoded);
    final raw = jsonDecode(jsonStr) as Map<String, dynamic>;
    return TagDisplayService._(raw.map((k, v) => MapEntry(k, v as String)));
  }

  String displayName(String slug, String fallback) {
    return _zhMap[slug] ?? fallback;
  }
}
