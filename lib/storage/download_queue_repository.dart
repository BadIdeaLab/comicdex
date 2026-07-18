import 'package:concept_nhv/models/comic.dart' as model;
import 'package:concept_nhv/models/download_job_snapshot.dart';
import 'package:concept_nhv/models/download_job_status.dart';
import 'package:concept_nhv/models/download_page_snapshot.dart';
import 'package:concept_nhv/models/download_page_status.dart';
import 'package:concept_nhv/storage/local_database.dart';
import 'package:drift/drift.dart' as drift;

class DownloadQueueRepository {
  const DownloadQueueRepository({required this.localDatabase});

  final LocalDatabase localDatabase;

  Future<void> upsertJobManifest({
    required model.Comic comic,
    required String title,
    DateTime? requestedAt,
  }) async {
    final now = requestedAt ?? DateTime.now();
    await localDatabase.transaction(() async {
      final existingJob = await loadJob(comic.id);
      final existingPages = await loadPages(comic.id);
      final existingPagesByNumber = <int, DownloadPageSnapshot>{
        for (final page in existingPages) page.pageNumber: page,
      };
      final completedPages = existingPages.where(
        (page) => page.status == DownloadPageStatus.completed,
      ).length;
      final nextPageNumber = _nextIncompletePage(existingPages, comic.numPages);

      await localDatabase.into(localDatabase.downloadJobs).insert(
        DownloadJobsCompanion.insert(
          comicId: comic.id,
          mediaId: comic.mediaId,
          title: title,
          thumbnailPath: drift.Value(comic.images.thumbnail?.path),
          status: DownloadJobStatus.queued.storageValue,
          totalPages: comic.numPages,
          completedPages: drift.Value(completedPages),
          nextPageNumber: drift.Value(nextPageNumber),
          requestedAt: existingJob?.requestedAt.toIso8601String() ??
              now.toIso8601String(),
          startedAt: drift.Value(existingJob?.startedAt?.toIso8601String()),
          updatedAt: now.toIso8601String(),
          completedAt: const drift.Value.absent(),
          lastError: const drift.Value.absent(),
          retryCount: drift.Value(existingJob?.retryCount ?? 0),
        ),
        mode: drift.InsertMode.insertOrReplace,
      );

      for (int index = 0; index < comic.images.pages.length; index++) {
        final pageNumber = index + 1;
        final page = comic.images.pages[index];
        final existingPage = existingPagesByNumber[pageNumber];
        final isCompleted = existingPage?.status == DownloadPageStatus.completed;

        await localDatabase.into(localDatabase.downloadJobPages).insert(
          DownloadJobPagesCompanion.insert(
            comicId: comic.id,
            mediaId: comic.mediaId,
            pageNumber: pageNumber,
            remotePath: page.path ?? '',
            sourceServer: drift.Value(existingPage?.sourceServer),
            localPath: drift.Value(existingPage?.localPath),
            storedFormat: drift.Value(existingPage?.storedFormat),
            byteSize: drift.Value(existingPage?.byteSize),
            status: isCompleted
                ? DownloadPageStatus.completed.storageValue
                : DownloadPageStatus.pending.storageValue,
            downloadedAt: drift.Value(existingPage?.downloadedAt?.toIso8601String()),
            lastError: const drift.Value.absent(),
          ),
          mode: drift.InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<List<DownloadJobSnapshot>> loadJobs() async {
    final query = localDatabase.select(localDatabase.downloadJobs)
      ..orderBy([(table) => drift.OrderingTerm.desc(table.updatedAt)]);
    final rows = await query.get();
    return rows.map(_mapJobRow).toList(growable: false);
  }

  Future<DownloadJobSnapshot?> loadJob(String comicId) async {
    final query = localDatabase.select(localDatabase.downloadJobs)
      ..where((table) => table.comicId.equals(comicId))
      ..limit(1);
    final row = await query.getSingleOrNull();
    if (row == null) {
      return null;
    }
    return _mapJobRow(row);
  }

  Future<List<DownloadPageSnapshot>> loadPages(String comicId) async {
    final query = localDatabase.select(localDatabase.downloadJobPages)
      ..where((table) => table.comicId.equals(comicId))
      ..orderBy([(table) => drift.OrderingTerm.asc(table.pageNumber)]);
    final rows = await query.get();
    return rows.map(_mapPageRow).toList(growable: false);
  }

  Future<DownloadJobSnapshot?> loadNextQueuedJob() async {
    final query = localDatabase.select(localDatabase.downloadJobs)
      ..where((table) => table.status.equals(DownloadJobStatus.queued.storageValue))
      ..orderBy([(table) => drift.OrderingTerm.asc(table.requestedAt)])
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row == null ? null : _mapJobRow(row);
  }

  Future<void> markJobDownloading(String comicId) async {
    final current = await loadJob(comicId);
    if (current == null) {
      return;
    }
    final statement = localDatabase.update(localDatabase.downloadJobs)
      ..where((table) => table.comicId.equals(comicId));
    await statement.write(
      DownloadJobsCompanion(
        status: drift.Value(DownloadJobStatus.downloading.storageValue),
        startedAt: drift.Value(
          current.startedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
        ),
        updatedAt: drift.Value(DateTime.now().toIso8601String()),
        lastError: const drift.Value(null),
      ),
    );
  }

  Future<void> markJobPaused(String comicId) async {
    await _writeJobStatus(
      comicId: comicId,
      status: DownloadJobStatus.paused,
      lastError: null,
    );
  }

  Future<void> requeueJob(String comicId) async {
    final pages = await loadPages(comicId);
    final current = await loadJob(comicId);
    if (current == null) {
      return;
    }
    final completedPages = pages.where(
      (page) => page.status == DownloadPageStatus.completed,
    ).length;
    final nextPage = _nextIncompletePage(pages, current.totalPages);
    final statement = localDatabase.update(localDatabase.downloadJobs)
      ..where((table) => table.comicId.equals(comicId));
    await statement.write(
      DownloadJobsCompanion(
        status: drift.Value(DownloadJobStatus.queued.storageValue),
        completedPages: drift.Value(completedPages),
        nextPageNumber: drift.Value(nextPage),
        updatedAt: drift.Value(DateTime.now().toIso8601String()),
        completedAt: const drift.Value(null),
        lastError: const drift.Value(null),
        retryCount: drift.Value(current.retryCount + 1),
      ),
    );

    await localDatabase.batch((batch) {
      for (final page in pages.where(
        (page) => page.status != DownloadPageStatus.completed,
      )) {
        batch.insert(
          localDatabase.downloadJobPages,
          DownloadJobPagesCompanion.insert(
            comicId: page.comicId,
            mediaId: page.mediaId,
            pageNumber: page.pageNumber,
            remotePath: page.remotePath,
            sourceServer: const drift.Value(null),
            localPath: const drift.Value(null),
            storedFormat: const drift.Value(null),
            byteSize: const drift.Value(null),
            status: DownloadPageStatus.pending.storageValue,
            downloadedAt: const drift.Value(null),
            lastError: const drift.Value(null),
          ),
          mode: drift.InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> requeueInterruptedJobs() async {
    final statement = localDatabase.update(localDatabase.downloadJobs)
      ..where((table) =>
          table.status.equals(DownloadJobStatus.downloading.storageValue));
    await statement.write(
      DownloadJobsCompanion(
        status: drift.Value(DownloadJobStatus.queued.storageValue),
        updatedAt: drift.Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  Future<void> pauseInterruptedJobs() async {
    final query = localDatabase.select(localDatabase.downloadJobs)
      ..where((table) =>
          table.status.equals(DownloadJobStatus.downloading.storageValue));
    final rows = await query.get();
    for (final row in rows) {
      await markJobPaused(row.comicId);
    }
  }

  Future<void> markPageDownloading({
    required String comicId,
    required int pageNumber,
  }) async {
    final statement = localDatabase.update(localDatabase.downloadJobPages)
      ..where((table) =>
          table.comicId.equals(comicId) & table.pageNumber.equals(pageNumber));
    await statement.write(
      DownloadJobPagesCompanion(
        status: drift.Value(DownloadPageStatus.downloading.storageValue),
        lastError: const drift.Value(null),
      ),
    );
  }

  Future<void> markPageCompleted({
    required String comicId,
    required int pageNumber,
    required String sourceServer,
    required String localPath,
    required String storedFormat,
    required int byteSize,
    DateTime? downloadedAt,
  }) async {
    final timestamp = downloadedAt ?? DateTime.now();
    await localDatabase.transaction(() async {
      final pageStatement = localDatabase.update(localDatabase.downloadJobPages)
        ..where((table) =>
            table.comicId.equals(comicId) & table.pageNumber.equals(pageNumber));
      await pageStatement.write(
        DownloadJobPagesCompanion(
          sourceServer: drift.Value(sourceServer),
          localPath: drift.Value(localPath),
          storedFormat: drift.Value(storedFormat),
          byteSize: drift.Value(byteSize),
          status: drift.Value(DownloadPageStatus.completed.storageValue),
          downloadedAt: drift.Value(timestamp.toIso8601String()),
          lastError: const drift.Value(null),
        ),
      );

      final pages = await loadPages(comicId);
      final job = await loadJob(comicId);
      if (job == null) {
        return;
      }
      final completedPages = pages.where(
        (page) => page.status == DownloadPageStatus.completed,
      ).length;
      final nextJobStatus = switch (job.status) {
        DownloadJobStatus.paused => DownloadJobStatus.paused,
        DownloadJobStatus.failed => DownloadJobStatus.failed,
        _ => DownloadJobStatus.downloading,
      };
      final jobStatement = localDatabase.update(localDatabase.downloadJobs)
        ..where((table) => table.comicId.equals(comicId));
      await jobStatement.write(
        DownloadJobsCompanion(
          completedPages: drift.Value(completedPages),
          nextPageNumber: drift.Value(
            _nextIncompletePage(pages, job.totalPages),
          ),
          status: drift.Value(nextJobStatus.storageValue),
          completedAt: const drift.Value(null),
          updatedAt: drift.Value(timestamp.toIso8601String()),
          lastError: drift.Value(
            nextJobStatus == DownloadJobStatus.downloading ? null : job.lastError,
          ),
        ),
      );
    });
  }

  Future<void> markJobCompleted(String comicId, {DateTime? completedAt}) async {
    final timestamp = completedAt ?? DateTime.now();
    final job = await loadJob(comicId);
    final pages = await loadPages(comicId);
    if (job == null) {
      return;
    }
    final completedPages = pages.where(
      (page) => page.status == DownloadPageStatus.completed,
    ).length;
    final statement = localDatabase.update(localDatabase.downloadJobs)
      ..where((table) => table.comicId.equals(comicId));
    await statement.write(
      DownloadJobsCompanion(
        status: drift.Value(DownloadJobStatus.completed.storageValue),
        completedPages: drift.Value(completedPages),
        nextPageNumber: drift.Value(job.totalPages + 1),
        completedAt: drift.Value(timestamp.toIso8601String()),
        updatedAt: drift.Value(timestamp.toIso8601String()),
        lastError: const drift.Value(null),
      ),
    );
  }

  Future<void> markPageFailed({
    required String comicId,
    required int pageNumber,
    required String error,
  }) async {
    final statement = localDatabase.update(localDatabase.downloadJobPages)
      ..where((table) =>
          table.comicId.equals(comicId) & table.pageNumber.equals(pageNumber));
    await statement.write(
      DownloadJobPagesCompanion(
        status: drift.Value(DownloadPageStatus.failed.storageValue),
        lastError: drift.Value(error),
      ),
    );
    await _writeJobStatus(
      comicId: comicId,
      status: DownloadJobStatus.failed,
      lastError: error,
    );
  }

  Future<void> deleteJob(String comicId) async {
    await localDatabase.transaction(() async {
      final pageDelete = localDatabase.delete(localDatabase.downloadJobPages)
        ..where((table) => table.comicId.equals(comicId));
      await pageDelete.go();
      final jobDelete = localDatabase.delete(localDatabase.downloadJobs)
        ..where((table) => table.comicId.equals(comicId));
      await jobDelete.go();
    });
  }

  /// Deletes the queue job and its page records without touching assets or
  /// the downloaded-library entry.  Used by Reload so library metadata
  /// (lastReadAt, tags, numFavorites) is preserved across re-downloads.
  Future<void> deleteQueueOnly(String comicId) async {
    await localDatabase.transaction(() async {
      final pageDelete = localDatabase.delete(localDatabase.downloadJobPages)
        ..where((table) => table.comicId.equals(comicId));
      await pageDelete.go();
      final jobDelete = localDatabase.delete(localDatabase.downloadJobs)
        ..where((table) => table.comicId.equals(comicId));
      await jobDelete.go();
    });
  }

  /// Resets [missingPageNumbers] back to pending so the engine will re-download
  /// only those pages.  All other pages keep their completed status.
  Future<void> resetMissingPages(
    String comicId,
    List<int> missingPageNumbers,
  ) async {
    if (missingPageNumbers.isEmpty) {
      return;
    }
    final pageNumbers = missingPageNumbers.toSet();
    await localDatabase.batch((batch) {
      for (final pageNumber in pageNumbers) {
        batch.update(
          localDatabase.downloadJobPages,
          DownloadJobPagesCompanion(
            status: drift.Value(DownloadPageStatus.pending.storageValue),
            sourceServer: const drift.Value(null),
            localPath: const drift.Value(null),
            storedFormat: const drift.Value(null),
            byteSize: const drift.Value(null),
            downloadedAt: const drift.Value(null),
            lastError: const drift.Value(null),
          ),
          where: (table) =>
              table.comicId.equals(comicId) &
              table.pageNumber.equals(pageNumber),
        );
      }
    });
  }

  Future<void> _writeJobStatus({
    required String comicId,
    required DownloadJobStatus status,
    required String? lastError,
  }) async {
    final pages = await loadPages(comicId);
    final job = await loadJob(comicId);
    if (job == null) {
      return;
    }
    final completedPages = pages.where(
      (page) => page.status == DownloadPageStatus.completed,
    ).length;
    final nextPage = _nextIncompletePage(pages, job.totalPages);
    final statement = localDatabase.update(localDatabase.downloadJobs)
      ..where((table) => table.comicId.equals(comicId));
    await statement.write(
      DownloadJobsCompanion(
        status: drift.Value(status.storageValue),
        completedPages: drift.Value(completedPages),
        nextPageNumber: drift.Value(nextPage),
        updatedAt: drift.Value(DateTime.now().toIso8601String()),
        lastError: drift.Value(lastError),
        completedAt: drift.Value(
          status == DownloadJobStatus.completed
              ? DateTime.now().toIso8601String()
              : null,
        ),
      ),
    );
  }

  int _nextIncompletePage(List<DownloadPageSnapshot> pages, int totalPages) {
    if (pages.isEmpty) {
      return 1;
    }
    for (final page in pages) {
      if (page.status != DownloadPageStatus.completed) {
        return page.pageNumber;
      }
    }
    return totalPages + 1;
  }

  DownloadJobSnapshot _mapJobRow(DownloadJob row) {
    return DownloadJobSnapshot(
      comicId: row.comicId,
      mediaId: row.mediaId,
      title: row.title,
      thumbnailPath: row.thumbnailPath,
      status: DownloadJobStatus.fromStorage(row.status),
      totalPages: row.totalPages,
      completedPages: row.completedPages,
      nextPageNumber: row.nextPageNumber,
      requestedAt: DateTime.parse(row.requestedAt),
      updatedAt: DateTime.parse(row.updatedAt),
      startedAt: row.startedAt == null ? null : DateTime.parse(row.startedAt!),
      completedAt: row.completedAt == null
          ? null
          : DateTime.parse(row.completedAt!),
      lastError: row.lastError,
      retryCount: row.retryCount,
    );
  }

  DownloadPageSnapshot _mapPageRow(DownloadJobPage row) {
    return DownloadPageSnapshot(
      comicId: row.comicId,
      mediaId: row.mediaId,
      pageNumber: row.pageNumber,
      remotePath: row.remotePath,
      sourceServer: row.sourceServer,
      localPath: row.localPath,
      storedFormat: row.storedFormat,
      byteSize: row.byteSize,
      status: DownloadPageStatus.fromStorage(row.status),
      downloadedAt: row.downloadedAt == null
          ? null
          : DateTime.parse(row.downloadedAt!),
      lastError: row.lastError,
    );
  }
}
