import 'dart:convert';
import 'dart:io';

import 'package:concept_nhv/models/local_tag_catalog_entry.dart';
import 'package:concept_nhv/models/tag_catalog_type.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

typedef TagCatalogOverrideDirectoryResolver = Future<Directory> Function();

const int _xorKey = 0x42;
const String _overrideFileName = 'tag_catalog_override.bin';

/// Loads the bundled local tag catalog (assets/tag_catalog.bin) and provides
/// instant, offline substring search across it, ranked by prefix match then
/// by popularity ([LocalTagCatalogEntry.count]).
///
/// A newer dataset can later be applied via [applyOverrideBytes] (see
/// .codex/phases/P58-local-tag-catalog-and-cross-category-selection.md) and
/// is compared by [version] so a stale override never shadows a newer
/// bundled default.
class LocalTagCatalogService extends ChangeNotifier {
  LocalTagCatalogService._({
    required String version,
    required List<LocalTagCatalogEntry> entries,
    required bool isUsingOverride,
    required TagCatalogOverrideDirectoryResolver overrideDirectoryResolver,
  }) : _version = version,
       _entries = entries,
       _isUsingOverride = isUsingOverride,
       _overrideDirectoryResolver = overrideDirectoryResolver;

  String _version;
  List<LocalTagCatalogEntry> _entries;
  bool _isUsingOverride;
  final TagCatalogOverrideDirectoryResolver _overrideDirectoryResolver;

  String get version => _version;
  int get entryCount => _entries.length;
  bool get isUsingOverride => _isUsingOverride;

  static Future<LocalTagCatalogService> load({
    TagCatalogOverrideDirectoryResolver? overrideDirectoryResolver,
  }) async {
    final resolver = overrideDirectoryResolver ?? _defaultOverrideDirectory;
    final bundled = await _loadBundled();

    _DecodedCatalog active = bundled;
    var isUsingOverride = false;
    try {
      final overrideFile = File(p.join((await resolver()).path, _overrideFileName));
      if (await overrideFile.exists()) {
        final overrideCatalog = _decode(await overrideFile.readAsBytes());
        if (_isNewerVersion(overrideCatalog.version, active.version)) {
          active = overrideCatalog;
          isUsingOverride = true;
        }
      }
    } catch (_) {
      // Corrupt or unreadable override file: fall back to the bundled catalog.
    }

    return LocalTagCatalogService._(
      version: active.version,
      entries: active.entries,
      isUsingOverride: isUsingOverride,
      overrideDirectoryResolver: resolver,
    );
  }

  /// Test-only convenience constructor that bypasses asset loading.
  @visibleForTesting
  static LocalTagCatalogService fromEntries(
    List<LocalTagCatalogEntry> entries, {
    String version = '1970-01-01',
    TagCatalogOverrideDirectoryResolver? overrideDirectoryResolver,
  }) {
    return LocalTagCatalogService._(
      version: version,
      entries: entries,
      isUsingOverride: false,
      overrideDirectoryResolver: overrideDirectoryResolver ?? _defaultOverrideDirectory,
    );
  }

  List<LocalTagCatalogEntry> search(
    String query, {
    required TagCatalogType type,
    String Function(String slug, String name)? displayNameResolver,
    int limit = 150,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final candidates = _entries.where((entry) => entry.type == type);

    if (normalizedQuery.isEmpty) {
      final sorted = candidates.toList()..sort((a, b) => b.count.compareTo(a.count));
      return sorted.take(limit).toList(growable: false);
    }

    final ranked = <_RankedEntry>[];
    for (final entry in candidates) {
      final rank = _matchRank(entry, normalizedQuery, displayNameResolver);
      if (rank != null) {
        ranked.add(_RankedEntry(entry, rank));
      }
    }
    ranked.sort((a, b) {
      final rankCompare = a.rank.compareTo(b.rank);
      if (rankCompare != 0) return rankCompare;
      return b.entry.count.compareTo(a.entry.count);
    });
    return ranked.take(limit).map((r) => r.entry).toList(growable: false);
  }

  /// Applies a newly downloaded, XOR-encoded catalog if (and only if) its
  /// embedded version is newer than [version]. Returns the resulting
  /// version string; the returned version equals the pre-existing [version]
  /// when the candidate was not newer (a no-op "already up to date" result).
  Future<String> applyOverrideBytes(Uint8List xorEncodedBytes) async {
    final candidate = _decode(xorEncodedBytes);
    if (!_isNewerVersion(candidate.version, _version)) {
      return _version;
    }

    final directory = await _overrideDirectoryResolver();
    await directory.create(recursive: true);
    final overrideFile = File(p.join(directory.path, _overrideFileName));
    await overrideFile.writeAsBytes(xorEncodedBytes, flush: true);

    _version = candidate.version;
    _entries = candidate.entries;
    _isUsingOverride = true;
    notifyListeners();
    return _version;
  }

  static Future<_DecodedCatalog> _loadBundled() async {
    final byteData = await rootBundle.load('assets/tag_catalog.bin');
    final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
    return _decode(bytes);
  }

  static _DecodedCatalog _decode(Uint8List xorEncodedBytes) {
    final decoded = Uint8List.fromList(xorEncodedBytes.map((b) => b ^ _xorKey).toList());
    final jsonStr = utf8.decode(decoded);
    final raw = jsonDecode(jsonStr) as Map<String, dynamic>;
    final version = raw['version'] as String;
    final rawEntries = raw['entries'] as List<dynamic>;
    final entries = rawEntries.map((e) {
      final map = e as Map<String, dynamic>;
      return LocalTagCatalogEntry(
        type: _typeFromApiValue(map['t'] as String),
        name: map['n'] as String,
        slug: map['s'] as String,
        count: map['c'] as int,
      );
    }).toList(growable: false);
    if (version.isEmpty || entries.isEmpty) {
      throw const FormatException('Empty tag catalog payload');
    }
    return _DecodedCatalog(version: version, entries: entries);
  }

  static TagCatalogType _typeFromApiValue(String apiValue) {
    return TagCatalogType.values.firstWhere((t) => t.apiValue == apiValue);
  }

  /// ISO-date version strings compare correctly with plain string comparison.
  static bool _isNewerVersion(String candidate, String current) {
    return candidate.compareTo(current) > 0;
  }

  static Future<Directory> _defaultOverrideDirectory() async {
    final supportDirectory = await getApplicationSupportDirectory();
    return Directory(p.join(supportDirectory.path, 'tag_catalog'));
  }

  int? _matchRank(
    LocalTagCatalogEntry entry,
    String normalizedQuery,
    String Function(String slug, String name)? displayNameResolver,
  ) {
    final candidates = <String>[
      entry.name.toLowerCase(),
      entry.slug.toLowerCase(),
      if (displayNameResolver != null) displayNameResolver(entry.slug, entry.name).toLowerCase(),
    ];
    var bestRank = 2;
    for (final candidate in candidates) {
      if (candidate.startsWith(normalizedQuery)) {
        return 0;
      }
      if (candidate.contains(normalizedQuery)) {
        bestRank = 1;
      }
    }
    return bestRank == 1 ? 1 : null;
  }
}

class _DecodedCatalog {
  const _DecodedCatalog({required this.version, required this.entries});

  final String version;
  final List<LocalTagCatalogEntry> entries;
}

class _RankedEntry {
  const _RankedEntry(this.entry, this.rank);

  final LocalTagCatalogEntry entry;
  final int rank;
}
