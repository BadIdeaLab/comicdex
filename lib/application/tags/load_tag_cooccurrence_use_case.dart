import 'package:concept_nhv/application/search/blocked_tags_repository.dart';
import 'package:concept_nhv/application/tags/load_tag_preferences_use_case.dart';
import 'package:concept_nhv/application/tags/preference_statistics.dart';
import 'package:concept_nhv/models/local_tag_catalog_entry.dart';
import 'package:concept_nhv/models/tag_catalog_type.dart';
import 'package:concept_nhv/models/tag_combination.dart';
import 'package:concept_nhv/services/local_tag_catalog_service.dart';
import 'package:concept_nhv/storage/comic_tag_repository.dart';

/// Finds the tag combinations — two or three tags — that the user keeps
/// together more often than each tag's own frequency predicts. See
/// .codex/phases/P83-taste-themes.md.
class LoadTagCooccurrenceUseCase {
  const LoadTagCooccurrenceUseCase({
    required this.comicTagRepository,
    required this.localTagCatalogService,
    required this.blockedTagsRepository,
    this.limit = 30,
    this.minimumComics = 5,
    this.tripleGainFactor = 1.1,
    this.tripleSeedPairs = 400,
  });

  final ComicTagRepository comicTagRepository;
  final LocalTagCatalogService localTagCatalogService;
  final BlockedTagsRepository blockedTagsRepository;

  /// Combinations to return; the tail is a long list of near-chance ones.
  final int limit;

  /// A combination must appear on at least this many kept comics. Load
  /// bearing, not tuning: without it, hundreds of tags produce thousands of
  /// combinations seen once.
  final int minimumComics;

  /// Triples are grown from at most this many of the strongest pairs.
  /// Measured, not guessed: without a cap the pass took ~1s on a dense
  /// library, which is a visible freeze on a phone (see
  /// test/manual/tag_pair_benchmark.dart).
  final int tripleSeedPairs;

  /// A triple has to beat its best pair by this much to be worth showing.
  /// Otherwise the third tag rides along on the pair's strength and the list
  /// fills with "a strong pair plus whatever else was on those comics".
  final double tripleGainFactor;

  Future<List<TagCombination>> execute() async {
    final assignments = await comicTagRepository.loadKeptTagAssignments();
    if (assignments.isEmpty) return const <TagCombination>[];

    final keptComics = await comicTagRepository.loadKeptComicCount();
    if (keptComics <= 0) return const <TagCombination>[];

    final blocked = (await blockedTagsRepository.loadBlockedTags()).toSet();

    // Candidate tags only: blocked, language and catalog-less ids are the
    // same exclusions the ranking applies, so the two sections cannot
    // disagree about a tag.
    final tags = <int, LocalTagCatalogEntry>{};
    final tagComics = <int, Set<String>>{};
    final comicTags = <String, List<int>>{};
    for (final assignment in assignments) {
      final tag =
          tags[assignment.tagId] ?? _rankableTag(assignment.tagId, blocked);
      if (tag == null) continue;
      tags[assignment.tagId] = tag;
      (tagComics[assignment.tagId] ??= <String>{}).add(assignment.comicId);
      (comicTags[assignment.comicId] ??= <int>[]).add(assignment.tagId);
    }
    if (tags.length < 2) return const <TagCombination>[];

    final pairCounts = _countPairs(comicTags);
    final combinations = <TagCombination>[];
    final pairLifts = <int, double>{};

    for (final entry in pairCounts.entries) {
      if (entry.value < minimumComics) continue;
      final ids = _idsFromPairKey(entry.key);
      final members = <LocalTagCatalogEntry>[tags[ids[0]]!, tags[ids[1]]!];
      if (_isStructural(members)) continue;
      final lift = _lift(entry.value, keptComics, ids, tagComics);
      pairLifts[entry.key] = lift;
      combinations.add(
        TagCombination(members: members, comicCount: entry.value, lift: lift),
      );
    }

    combinations.addAll(
      _buildTriples(
        pairCounts: pairCounts,
        pairLifts: pairLifts,
        comicTags: comicTags,
        tagComics: tagComics,
        tags: tags,
        keptComics: keptComics,
      ),
    );

    combinations.sort((a, b) {
      final byLift = b.lift.compareTo(a.lift);
      return byLift != 0 ? byLift : b.comicCount.compareTo(a.comicCount);
    });
    return combinations.take(limit).toList(growable: false);
  }

  /// Triples are grown only from pairs that already clear the support floor:
  /// a triple can never appear on more comics than any pair inside it, so a
  /// pair below the floor rules out every triple containing it. That is what
  /// keeps this from enumerating every three-tag combination.
  List<TagCombination> _buildTriples({
    required Map<int, int> pairCounts,
    required Map<int, double> pairLifts,
    required Map<String, List<int>> comicTags,
    required Map<int, Set<String>> tagComics,
    required Map<int, LocalTagCatalogEntry> tags,
    required int keptComics,
  }) {
    // Strongest pairs first: a triple's support can never exceed its pairs',
    // so the weakest pairs cannot seed anything worth showing anyway.
    final seeds =
        pairCounts.entries.where((e) => e.value >= minimumComics).toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    final tripleCounts = <int, int>{};
    for (final entry in seeds.take(tripleSeedPairs)) {
      final ids = _idsFromPairKey(entry.key);
      final shared = tagComics[ids[0]]!.intersection(tagComics[ids[1]]!);
      for (final comicId in shared) {
        for (final third in comicTags[comicId]!) {
          if (third <= ids[1]) continue; // keeps each triple to one ordering
          tripleCounts.update(
            _tripleKey(ids[0], ids[1], third),
            (count) => count + 1,
            ifAbsent: () => 1,
          );
        }
      }
    }

    final triples = <TagCombination>[];
    for (final entry in tripleCounts.entries) {
      if (entry.value < minimumComics) continue;
      final ids = _idsFromTripleKey(entry.key);
      final members = <LocalTagCatalogEntry>[for (final id in ids) tags[id]!];
      if (_isStructural(members)) continue;

      final lift = _lift(entry.value, keptComics, ids, tagComics);
      final bestPairLift = <double>[
        pairLifts[_pairKey(ids[0], ids[1])] ?? 0,
        pairLifts[_pairKey(ids[0], ids[2])] ?? 0,
        pairLifts[_pairKey(ids[1], ids[2])] ?? 0,
      ].reduce((a, b) => a > b ? a : b);
      if (lift < bestPairLift * tripleGainFactor) continue;

      triples.add(
        TagCombination(members: members, comicCount: entry.value, lift: lift),
      );
    }
    return triples;
  }

  Map<int, int> _countPairs(Map<String, List<int>> comicTags) {
    final counts = <int, int>{};
    for (final tagIds in comicTags.values) {
      final sorted = tagIds.toList()..sort();
      for (var i = 0; i < sorted.length; i++) {
        for (var j = i + 1; j < sorted.length; j++) {
          counts.update(
            _pairKey(sorted[i], sorted[j]),
            (count) => count + 1,
            ifAbsent: () => 1,
          );
        }
      }
    }
    return counts;
  }

  double _lift(
    int comicCount,
    int keptComics,
    List<int> ids,
    Map<int, Set<String>> tagComics,
  ) {
    var expected = 1.0;
    for (final id in ids) {
      expected *= tagComics[id]!.length / keptComics;
    }
    if (expected <= 0) return 0;
    return wilsonLowerBound(comicCount, keptComics) / expected;
  }

  /// Combinations that say something about how the site is organised rather
  /// than about taste, and would otherwise dominate the list:
  ///
  /// * the same name twice — an artist and the group or parody they share a
  ///   name with, which combines a tag with itself in all but id;
  /// * a parody with one of its own characters, an artist with the parody
  ///   they work on: a character belongs to its series by definition, so the
  ///   two travel together no matter what the user likes.
  ///
  /// Requiring one content tag keeps "content + who/what" combinations,
  /// which is where preference actually shows.
  bool _isStructural(List<LocalTagCatalogEntry> members) {
    for (var i = 0; i < members.length; i++) {
      for (var j = i + 1; j < members.length; j++) {
        final a = members[i].slug.toLowerCase();
        final b = members[j].slug.toLowerCase();
        if (a.contains(b) || b.contains(a)) return true;
      }
    }
    return !members.any((member) => member.type == TagCatalogType.tag);
  }

  LocalTagCatalogEntry? _rankableTag(int tagId, Set<String> blocked) {
    final tag = localTagCatalogService.entryById(tagId);
    if (tag == null) return null;
    if (!LoadTagPreferencesUseCase.rankedTypes.contains(tag.type)) return null;
    if (blocked.contains(tag.query)) return null;
    return tag;
  }

  // Packed int keys rather than joined strings: this runs over roughly a
  // hundred thousand pairs, where building and re-parsing strings dominated
  // the measurement.
  static const int _idSpace = 1 << 21; // nhentai tag ids fit comfortably

  int _pairKey(int a, int b) => a * _idSpace + b;

  int _tripleKey(int a, int b, int c) => (a * _idSpace + b) * _idSpace + c;

  List<int> _idsFromPairKey(int key) => <int>[key ~/ _idSpace, key % _idSpace];

  List<int> _idsFromTripleKey(int key) {
    final c = key % _idSpace;
    final rest = key ~/ _idSpace;
    return <int>[rest ~/ _idSpace, rest % _idSpace, c];
  }
}
