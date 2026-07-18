import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:concept_nhv/models/local_tag_catalog_entry.dart';
import 'package:concept_nhv/models/tag_catalog_type.dart';
import 'package:concept_nhv/services/local_tag_catalog_service.dart';
import 'package:flutter_test/flutter_test.dart';

const int _xorKey = 0x42;

Uint8List _encodeCatalog(String version, List<Map<String, Object?>> entries) {
  final json = jsonEncode(<String, Object?>{'version': version, 'entries': entries});
  final bytes = utf8.encode(json);
  return Uint8List.fromList(bytes.map((b) => b ^ _xorKey).toList());
}

void main() {
  group('search', () {
    late LocalTagCatalogService service;

    setUp(() {
      service = LocalTagCatalogService.fromEntries(const <LocalTagCatalogEntry>[
        LocalTagCatalogEntry(
          type: TagCatalogType.tag,
          name: 'full color',
          slug: 'full-color',
          count: 10,
        ),
        LocalTagCatalogEntry(
          type: TagCatalogType.tag,
          name: 'big breasts',
          slug: 'big-breasts',
          count: 20,
        ),
        LocalTagCatalogEntry(
          type: TagCatalogType.tag,
          name: 'colorful',
          slug: 'colorful',
          count: 5,
        ),
        LocalTagCatalogEntry(
          type: TagCatalogType.language,
          name: 'chinese',
          slug: 'chinese',
          count: 50,
        ),
      ]);
    });

    test('empty query returns entries for the requested type sorted by count desc', () {
      final results = service.search('', type: TagCatalogType.tag);

      expect(results.map((e) => e.slug), <String>['big-breasts', 'full-color', 'colorful']);
    });

    test('ranks prefix matches above contains matches', () {
      final results = service.search('color', type: TagCatalogType.tag);

      // 'full color' contains "color" but doesn't start with it; 'colorful'
      // starts with it and should be ranked first.
      expect(results.map((e) => e.slug), <String>['colorful', 'full-color']);
    });

    test('excludes non-matching entries', () {
      final results = service.search('nomatch', type: TagCatalogType.tag);

      expect(results, isEmpty);
    });

    test('is scoped to the requested type', () {
      final results = service.search('', type: TagCatalogType.language);

      expect(results.map((e) => e.slug), <String>['chinese']);
    });

    test('matches against a supplied display name resolver', () {
      final results = service.search(
        '彩色',
        type: TagCatalogType.tag,
        displayNameResolver: (slug, name) => slug == 'full-color' ? '彩色' : name,
      );

      expect(results.single.slug, 'full-color');
    });
  });

  group('applyOverrideBytes', () {
    late Directory tempDirectory;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp('tag_catalog_service_test');
    });

    tearDown(() async {
      await tempDirectory.delete(recursive: true);
    });

    test('does not apply a candidate with the same or older version', () async {
      final service = LocalTagCatalogService.fromEntries(
        const <LocalTagCatalogEntry>[],
        version: '2026-06-01',
        overrideDirectoryResolver: () async => tempDirectory,
      );

      final sameVersion = _encodeCatalog('2026-06-01', <Map<String, Object?>>[
        <String, Object?>{'t': 'tag', 'n': 'newer', 's': 'newer', 'c': 1},
      ]);
      final resultVersion = await service.applyOverrideBytes(sameVersion);

      expect(resultVersion, '2026-06-01');
      expect(service.isUsingOverride, isFalse);
      expect(service.search('', type: TagCatalogType.tag), isEmpty);
    });

    test('applies and persists a candidate with a newer version', () async {
      final service = LocalTagCatalogService.fromEntries(
        const <LocalTagCatalogEntry>[],
        version: '2026-06-01',
        overrideDirectoryResolver: () async => tempDirectory,
      );

      final newer = _encodeCatalog('2026-07-01', <Map<String, Object?>>[
        <String, Object?>{'t': 'tag', 'n': 'newer', 's': 'newer', 'c': 1},
      ]);
      final resultVersion = await service.applyOverrideBytes(newer);

      expect(resultVersion, '2026-07-01');
      expect(service.isUsingOverride, isTrue);
      expect(service.search('', type: TagCatalogType.tag).single.slug, 'newer');

      final overrideFile = File('${tempDirectory.path}/tag_catalog_override.bin');
      expect(await overrideFile.exists(), isTrue);
    });
  });
}
