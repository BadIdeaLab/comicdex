import 'dart:convert';
import 'dart:typed_data';

const int tagCatalogXorKey = 0x42;

/// Builds an XOR-encoded tag catalog payload matching the format
/// `LocalTagCatalogService` decodes, for use in tests that need to fake a
/// bundled asset or a downloaded override/update payload.
Uint8List encodeTagCatalog(String version, List<Map<String, Object?>> entries) {
  final json = jsonEncode(<String, Object?>{'version': version, 'entries': entries});
  final bytes = utf8.encode(json);
  return Uint8List.fromList(bytes.map((b) => b ^ tagCatalogXorKey).toList());
}
