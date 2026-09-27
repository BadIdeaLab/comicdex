import 'package:concept_nhv/application/tags/tag_preference_vector.dart';
import 'package:concept_nhv/models/download_job_status.dart';
import 'package:concept_nhv/models/download_list_item_snapshot.dart';
import 'package:concept_nhv/models/downloads_sort_mode.dart';

/// Puts the Downloads list in order: active jobs first, then the library.
///
/// Built fresh for each sort rather than held by the model, so the preference
/// vector it scores with is whatever has been pushed in by now — that vector
/// arrives in the background, well after the first sort.
class DownloadListSorter {
  const DownloadListSorter({
    required this.mode,
    required this.direction,
    this.preferences = const TagPreferenceVector.empty(),
  });

  final DownloadsSortMode mode;
  final DownloadsSortDirection direction;

  /// Plain data rather than a dependency, so the list still sorts — by
  /// everything except preference — with no preference data loaded at all.
  final TagPreferenceVector preferences;

  /// Active jobs, then completed ones.
  ///
  /// Only the completed half follows [mode]: an active job has no title the
  /// user chose to sort by, and burying a running download under an
  /// alphabetical list would hide the thing that is actually happening.
  List<DownloadListItemSnapshot> sort(List<DownloadListItemSnapshot> items) {
    final activeItems =
        items
            .where((item) => item.status != DownloadJobStatus.completed)
            .toList(growable: false)
          ..sort(compareActive);
    final completedItems =
        items
            .where((item) => item.status == DownloadJobStatus.completed)
            .toList(growable: false)
          ..sort(compareCompleted);
    return List<DownloadListItemSnapshot>.unmodifiable(
      <DownloadListItemSnapshot>[...activeItems, ...completedItems],
    );
  }

  int compareActive(DownloadListItemSnapshot a, DownloadListItemSnapshot b) {
    final statusComparison = _statusPriority(
      a.status,
    ).compareTo(_statusPriority(b.status));
    if (statusComparison != 0) {
      return statusComparison;
    }
    return b.requestedAt.compareTo(a.requestedAt);
  }

  int compareCompleted(DownloadListItemSnapshot a, DownloadListItemSnapshot b) {
    return switch (mode) {
      DownloadsSortMode.latestDownloaded => _byDirection(
        a.downloadedAt ?? a.updatedAt,
        b.downloadedAt ?? b.updatedAt,
      ),
      DownloadsSortMode.lastRead => _compareLastRead(a, b),
      DownloadsSortMode.mostFavorited => _compareMostFavorited(a, b),
      DownloadsSortMode.title => _byDirection(
        a.title.toLowerCase(),
        b.title.toLowerCase(),
      ),
      DownloadsSortMode.author => _compareAuthor(a, b),
      DownloadsSortMode.preference => _comparePreference(a, b),
    };
  }

  int _comparePreference(
    DownloadListItemSnapshot a,
    DownloadListItemSnapshot b,
  ) {
    final comparison = _byDirection(_preferenceScore(a), _preferenceScore(b));
    if (comparison != 0) return comparison;
    // Everything unscored — a library with no preference data, or comics
    // downloaded before tag ids were stored — would otherwise come back in
    // whatever order the rows arrived in.
    return (b.downloadedAt ?? b.updatedAt).compareTo(
      a.downloadedAt ?? a.updatedAt,
    );
  }

  double _preferenceScore(DownloadListItemSnapshot item) {
    return preferences.scoreComic(<int>[
      for (final tag in item.tags)
        if (tag.id != null) tag.id!,
    ]);
  }

  int _compareAuthor(DownloadListItemSnapshot a, DownloadListItemSnapshot b) {
    final aAuthor = authorName(a);
    final bAuthor = authorName(b);
    if (aAuthor == null && bAuthor == null) {
      return _byDirection(a.title.toLowerCase(), b.title.toLowerCase());
    }
    if (aAuthor == null) return 1;
    if (bAuthor == null) return -1;
    return _byDirection(aAuthor.toLowerCase(), bAuthor.toLowerCase());
  }

  /// First `artist` tag name, falling back to the first `group` tag —
  /// this project has no dedicated author field; artist/group tags are how
  /// doujin authorship is represented (same convention used to group tags
  /// in comic_tag_bottom_sheet.dart).
  static String? authorName(DownloadListItemSnapshot item) {
    for (final tag in item.tags) {
      if (tag.type == 'artist' && (tag.name?.isNotEmpty ?? false)) {
        return tag.name;
      }
    }
    for (final tag in item.tags) {
      if (tag.type == 'group' && (tag.name?.isNotEmpty ?? false)) {
        return tag.name;
      }
    }
    return null;
  }

  int _compareLastRead(DownloadListItemSnapshot a, DownloadListItemSnapshot b) {
    final aTimestamp = a.lastReadAt ?? a.downloadedAt ?? a.updatedAt;
    final bTimestamp = b.lastReadAt ?? b.downloadedAt ?? b.updatedAt;
    return _byDirection(aTimestamp, bTimestamp);
  }

  int _compareMostFavorited(
    DownloadListItemSnapshot a,
    DownloadListItemSnapshot b,
  ) {
    final aFavorites = a.numFavorites;
    final bFavorites = b.numFavorites;
    if (aFavorites == null && bFavorites == null) {
      return (b.downloadedAt ?? b.updatedAt).compareTo(
        a.downloadedAt ?? a.updatedAt,
      );
    }
    if (aFavorites == null) {
      return 1;
    }
    if (bFavorites == null) {
      return -1;
    }
    return _byDirection(aFavorites, bFavorites);
  }

  int _byDirection<T extends Comparable<T>>(T a, T b) {
    return switch (direction) {
      DownloadsSortDirection.descending => b.compareTo(a),
      DownloadsSortDirection.ascending => a.compareTo(b),
    };
  }

  static int _statusPriority(DownloadJobStatus status) {
    return switch (status) {
      DownloadJobStatus.downloading => 0,
      DownloadJobStatus.queued => 1,
      DownloadJobStatus.failed => 2,
      DownloadJobStatus.paused => 3,
      DownloadJobStatus.completed => 4,
    };
  }
}
