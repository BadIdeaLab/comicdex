import 'package:concept_nhv/application/tracking/check_tracked_artists_use_case.dart';
import 'package:concept_nhv/application/tracking/foreground_ticker.dart';
import 'package:concept_nhv/models/local_tag_catalog_entry.dart';
import 'package:concept_nhv/services/local_tag_catalog_service.dart';
import 'package:concept_nhv/storage/local_database.dart' show TrackedArtist;
import 'package:concept_nhv/storage/tracked_artist_repository.dart';
import 'package:flutter/foundation.dart';

/// A tracked artist, with the catalog entry needed to show and search it.
class TrackedArtistEntry {
  const TrackedArtistEntry({required this.artist, required this.catalogEntry});

  final TrackedArtist artist;

  /// Null when the catalog cannot name this id — a tag that was renamed or
  /// removed site-side. Shown as untitled rather than hidden, so the row can
  /// still be un-tracked.
  final LocalTagCatalogEntry? catalogEntry;

  int get tagId => artist.tagId;
  int get newCount => artist.newCount;
  bool get hasNewWork => artist.newCount > 0;
}

/// The tracked artists, and whatever the last check found.
///
/// Holds no rules of its own. When a check may run is [TrackingCooldown]'s
/// answer, what counts as new is [countNewerThan]'s, and how many to ask
/// about per run is the repository's — this only calls them and publishes the
/// result.
class TrackingModel extends ChangeNotifier {
  TrackingModel({
    required this.trackedArtistRepository,
    required this.checkTrackedArtistsUseCase,
    required this.localTagCatalogService,
    this.now = DateTime.now,
    ForegroundTicker? ticker,
  }) {
    _ticker = ticker ?? ForegroundTicker(onTick: () => check());
  }

  final TrackedArtistRepository trackedArtistRepository;
  final CheckTrackedArtistsUseCase checkTrackedArtistsUseCase;
  final LocalTagCatalogService localTagCatalogService;
  final DateTime Function() now;

  late final ForegroundTicker _ticker;

  List<TrackedArtistEntry> _artists = const <TrackedArtistEntry>[];
  bool _isChecking = false;

  /// New work first, then the rest; each half by tag id so the order is
  /// stable between rebuilds.
  List<TrackedArtistEntry> get artists => _artists;

  /// How many tracked artists have something unseen. This is the number on
  /// the bell, and zero is what hides it.
  int get artistsWithNewWork =>
      _artists.where((entry) => entry.hasNewWork).length;

  bool get isChecking => _isChecking;

  /// Loads the list and starts the foreground ticker.
  Future<void> initialize() async {
    await refresh();
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  Future<void> refresh() async {
    final rows = await trackedArtistRepository.loadAll();
    final entries =
        <TrackedArtistEntry>[
          for (final row in rows)
            TrackedArtistEntry(
              artist: row,
              catalogEntry: localTagCatalogService.entryById(row.tagId),
            ),
        ]..sort((a, b) {
          if (a.hasNewWork != b.hasNewWork) return a.hasNewWork ? -1 : 1;
          return a.tagId.compareTo(b.tagId);
        });
    _artists = List<TrackedArtistEntry>.unmodifiable(entries);
    notifyListeners();
  }

  /// Runs a check if the cooldown allows one. [manual] is a pull to refresh.
  Future<void> check({bool manual = false}) async {
    if (_isChecking) return;
    _isChecking = true;
    notifyListeners();
    try {
      await checkTrackedArtistsUseCase.execute(manual: manual);
      await refresh();
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  Future<void> track(int tagId) async {
    // No watermark: the first check establishes where "new" begins, so that
    // pressing track is not a request that can fail.
    await trackedArtistRepository.track(tagId);
    await refresh();
  }

  Future<void> untrack(int tagId) async {
    await trackedArtistRepository.untrack(tagId);
    await refresh();
  }

  bool isTracked(int tagId) => _artists.any((entry) => entry.tagId == tagId);

  /// Called when the user opens an artist's work: from here on, everything
  /// published before now has been shown to them.
  Future<void> markSeen(int tagId) async {
    await trackedArtistRepository.markSeen(tagId: tagId, seenAt: now());
    await refresh();
  }
}
